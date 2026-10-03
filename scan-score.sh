#!/usr/bin/env bash
#### VARIABLE SECTION START ###
# Some values
COLLECTION="Musikverein"
INSTRUMENTGROUP="Schlagwerk" # Used for the combined instrument-group PDF.

# Init Scanner. Use the scanner ID found with "scanimage --list-devices".
SCANNER="pixma:04A91913_597E72"
# Output Folder
OUTPUTFOLDER="/home/chaapp/onedrive/Notenordner/Musikverein"

#### VARIABLE SECTION END ###

if ! cd -- "$OUTPUTFOLDER"; then
    echo "Fehler: Ausgabeordner nicht gefunden: $OUTPUTFOLDER" >&2
    exit 1
fi

echo "Song-Title: "
read -r TITLE
if [[ -z "$TITLE" ]]; then
    echo "Fehler: Der Titel darf nicht leer sein." >&2
    exit 1
fi

# Each score folder keeps its source scans and a small manifest so later runs
# can continue the page numbering and rebuild all derived files.
mkdir -p -- "$TITLE"
cd -- "$TITLE" || exit 1
TITLETRIM=$(printf '%s' "$TITLE" | tr -d '[:blank:]')
if [[ -z "$TITLETRIM" ]]; then
    echo "Fehler: Der Titel enthaelt keinen gueltigen Dateinamen." >&2
    exit 1
fi

METADATA_FILE=".scan-metadata"
MANIFEST_FILE=".scan-parts.tsv"
IMPORT_FILE="import.csv"
SCAN_FOLDER="scans"
TOTAL_PDF="$TITLE-Gesamt.pdf"
GROUP_PDF="$TITLE-$INSTRUMENTGROUP.pdf"

mkdir -p -- "$SCAN_FOLDER"

# Move source images from versions before the scans/ folder was introduced.
for image in "$TITLETRIM"-*.jpg; do
    [[ -f "$image" ]] && mv -- "$image" "$SCAN_FOLDER/"
done

prompt_metadata() {
    echo "Artist: "
    read -r ARTIST
    echo "Genre: "
    read -r GENRE
    echo "Composer: "
    read -r COMPOSER
}

save_metadata() {
    printf 'title=%s\nartist=%s\ngenre=%s\ncomposer=%s\n' \
        "$TITLE" "$ARTIST" "$GENRE" "$COMPOSER" > "$METADATA_FILE"
}

load_metadata() {
    local key value
    while IFS='=' read -r key value; do
        case "$key" in
            title) TITLE=${value:-$TITLE} ;;
            artist) ARTIST=$value ;;
            genre) GENRE=$value ;;
            composer) COMPOSER=$value ;;
        esac
    done < "$METADATA_FILE"
}

# This fallback makes folders created by older versions keep their metadata.
load_metadata_from_import() {
    local csv_title csv_pages ignored collection artist albums genre composer
    local source_type custom_group
    while IFS=';' read -r csv_title csv_pages ignored collection artist albums genre composer source_type custom_group; do
        [[ "$csv_title" == "title" || -z "$csv_title" ]] && continue
        ARTIST=$artist
        GENRE=$genre
        COMPOSER=$composer
        return 0
    done < "$IMPORT_FILE"
    return 1
}

migrate_manifest_from_import() {
    local csv_title csv_pages ignored collection artist albums genre composer
    local source_type custom_group start_page end_page
    while IFS=';' read -r csv_title csv_pages ignored collection artist albums genre composer source_type custom_group; do
        [[ "$csv_title" == "title" || -z "$csv_title" ]] && continue
        [[ "$source_type" == "$INSTRUMENTGROUP" && "$custom_group" == "$INSTRUMENTGROUP" ]] && continue

        if [[ "$csv_pages" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start_page=${BASH_REMATCH[1]}
            end_page=${BASH_REMATCH[2]}
        elif [[ "$csv_pages" =~ ^[0-9]+$ ]]; then
            start_page=$csv_pages
            end_page=$csv_pages
        else
            continue
        fi
        printf '%s\t%s\t%s\n' "$source_type" "$start_page" "$end_page" >> "$MANIFEST_FILE"
    done < "$IMPORT_FILE"
}

if [[ -f "$METADATA_FILE" ]]; then
    echo "Vorhandene Metadaten verwenden? [J/n]"
    read -r USE_EXISTING_METADATA
    if [[ "$USE_EXISTING_METADATA" =~ ^[Nn]$ ]]; then
        prompt_metadata
        save_metadata
    else
        load_metadata
        echo "Vorhandene Metadaten wurden uebernommen."
    fi
elif [[ -f "$IMPORT_FILE" ]] && load_metadata_from_import; then
    save_metadata
    echo "Metadaten aus import.csv uebernommen."
else
    prompt_metadata
    save_metadata
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
    : > "$MANIFEST_FILE"
fi
if [[ ! -s "$MANIFEST_FILE" && -f "$IMPORT_FILE" ]]; then
    migrate_manifest_from_import
fi

# Continue after the last completed part. Incomplete scans are overwritten on
# the next run instead of creating gaps in the manifest.
PAGE=0
while IFS=$'\t' read -r existing_part existing_start existing_end; do
    if [[ "$existing_end" =~ ^[0-9]+$ ]] && (( existing_end > PAGE )); then
        PAGE=$existing_end
    fi
done < "$MANIFEST_FILE"

get_all_images() {
    local image
    IMAGE_FILES=()
    while IFS= read -r image; do
        [[ -f "$image" ]] && IMAGE_FILES+=("$image")
    done < <(printf '%s\n' "$SCAN_FOLDER/$TITLETRIM"-*.jpg | sort -V)
}

get_part_images() {
    local image
    PART_IMAGE_FILES=()
    while IFS= read -r image; do
        [[ -f "$image" ]] && PART_IMAGE_FILES+=("$image")
    done < <(printf '%s\n' "$SCAN_FOLDER/$TITLETRIM"-*-"$STIMME".jpg | sort -V)
}

create_pdf() {
    local output_path=$1
    shift
    if (( $# == 0 )); then
        echo "Warnung: Keine JPG-Dateien fuer $output_path gefunden." >&2
        return 1
    fi
    convert "$@" "$output_path"
}

write_import_csv() {
    local last_page=$1
    local manifest_part manifest_start manifest_end

    printf '%s\n' "title;pages;setlists;collections;artist;albums;genres;composer;source types;custom groups" > "$IMPORT_FILE"
    while IFS=$'\t' read -r manifest_part manifest_start manifest_end; do
        [[ -z "$manifest_part" ]] && continue
        printf '%s;%s-%s;;%s;%s;;%s;%s;%s;%s\n' \
            "$TITLE" "$manifest_start" "$manifest_end" "$COLLECTION" \
            "$ARTIST" "$GENRE" "$COMPOSER" "$manifest_part" "$INSTRUMENTGROUP" >> "$IMPORT_FILE"
    done < "$MANIFEST_FILE"

    if (( last_page > 0 )); then
        printf '%s;1-%s;;%s;%s;;%s;%s;%s;%s\n' \
            "$TITLE" "$last_page" "$COLLECTION" "$ARTIST" "$GENRE" \
            "$COMPOSER" "$INSTRUMENTGROUP" "$INSTRUMENTGROUP" >> "$IMPORT_FILE"
    fi
}

update_combined_pdfs() {
    local combined_pdf base_pdf temp_pdf
    get_all_images
    if (( ${#IMAGE_FILES[@]} == 0 )); then
        echo "Warnung: Keine Scans fuer kombinierte PDFs gefunden." >&2
        return 1
    fi

    temp_pdf=$(mktemp --tmpdir=. ".scan-combined.XXXXXX.pdf")

    # With the current workflow all source JPGs are available. For an older
    # folder, only the newly scanned JPGs exist, so append them to the old PDF
    # instead of silently dropping the already scanned pages.
    if (( PAGE == ${#IMAGE_FILES[@]} )); then
        create_pdf "$temp_pdf" "${IMAGE_FILES[@]}" || {
            rm -f -- "$temp_pdf"
            return 1
        }
    else
        base_pdf=""
        if [[ -f "$TOTAL_PDF" ]]; then
            base_pdf=$TOTAL_PDF
        elif [[ -f "$GROUP_PDF" ]]; then
            base_pdf=$GROUP_PDF
        fi
        if [[ -z "$base_pdf" ]]; then
            echo "Fehler: Vorhandene Seiten sind nicht als JPG oder PDF vorhanden." >&2
            rm -f -- "$temp_pdf"
            return 1
        fi
        create_pdf "$temp_pdf" "$base_pdf" "${IMAGE_FILES[@]}" || {
            rm -f -- "$temp_pdf"
            return 1
        }
    fi

    echo "Aktualisiere $TOTAL_PDF und $GROUP_PDF"
    mv -- "$temp_pdf" "$TOTAL_PDF"

    if [[ "$GROUP_PDF" != "$TOTAL_PDF" ]]; then
        cp -- "$TOTAL_PDF" "$GROUP_PDF"
    fi
}

SCANENDE=0
while (( SCANENDE < 1 )); do
    echo "Which Part are you scanning? (1=Drums, 2=Percussion, 3=Mallets, 4=Timpani, 5=put in text)"
    read -r STIMMECHOICE
    case "$STIMMECHOICE" in
        1) STIMME="Drums" ;;
        2) STIMME="Percussion" ;;
        3) STIMME="Mallets" ;;
        4) STIMME="Timpani" ;;
        5)
            echo "Custom part name: "
            read -r STIMME
            ;;
        *)
            echo "Wrong input"
            continue
            ;;
    esac

    STIMMEPAGE=0
    STIMMEPAGESTART=$((PAGE + 1))
    while :; do
        PAGE=$((PAGE + 1))
        STIMMEPAGE=$((STIMMEPAGE + 1))
        IMAGE_FILE="$SCAN_FOLDER/$TITLETRIM-$PAGE-$STIMME.jpg"

        echo "Scanning $TITLE - $STIMME - $STIMMEPAGE"
        echo "Overallpage: $PAGE"
        read -r -p "Press enter to continue scanning" _
        if ! scanimage -d "$SCANNER" --mode Lineart --resolution 300 --format=jpeg > "$IMAGE_FILE"; then
            echo "Fehler: Scan fehlgeschlagen: $IMAGE_FILE" >&2
            rm -f -- "$IMAGE_FILE"
            PAGE=$((PAGE - 1))
            exit 1
        fi

        echo "Did you scan all pages of the part? (y/n): "
        read -r STIMMENENDEINPUT
        if [[ "$STIMMENENDEINPUT" =~ ^[Nn]$ ]]; then
            continue
        fi

        echo "Part is ready, going on"
        STIMMEPAGEENDE=$PAGE
        get_part_images
        if ! create_pdf "$TITLE-$STIMME.pdf" "${PART_IMAGE_FILES[@]}"; then
            exit 1
        fi
        printf '%s\t%s\t%s\n' "$STIMME" "$STIMMEPAGESTART" "$STIMMEPAGEENDE" >> "$MANIFEST_FILE"
        write_import_csv "$PAGE"
        break
    done

    echo "Is the whole scan done? (y/n)"
    read -r SCANENDEINPUT
    if [[ "$SCANENDEINPUT" =~ ^[Nn]$ ]]; then
        echo "Scanning next part..."
    else
        SCANENDE=1
    fi
done

write_import_csv "$PAGE"
update_combined_pdfs

echo "Scans und Metadaten liegen in: $(pwd)"
echo "Die JPG-Quelldateien bleiben in $SCAN_FOLDER/, damit spaetere Scans die PDFs aktualisieren koennen."
