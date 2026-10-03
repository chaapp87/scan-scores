#!/usr/bin/env bash
#### VARIABLE SECTION START ###
# Init Scanner. Use the scanner ID found with "scanimage --list-devices".
SCANNER="pixma:04A91913_597E72"
INSTRUMENTGROUP="Schlagwerk" # Used for the combined instrument-group PDF.
#### VARIABLE SECTION END ###

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Fehler: $ENV_FILE fehlt. Lege die Datei anhand von .env.example an." >&2
    exit 1
fi

# Read only the supported setting instead of executing the .env file.
while IFS= read -r env_line || [[ -n "$env_line" ]]; do
    env_line="${env_line#${env_line%%[![:space:]]*}}"
    [[ -z "$env_line" || "$env_line" == \#* ]] && continue
    [[ "$env_line" =~ ^OUTPUT_PATH[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
    OUTPUT_PATH=${BASH_REMATCH[1]}
    OUTPUT_PATH="${OUTPUT_PATH#${OUTPUT_PATH%%[![:space:]]*}}"
    OUTPUT_PATH="${OUTPUT_PATH%${OUTPUT_PATH##*[![:space:]]}}"
    OUTPUT_PATH=${OUTPUT_PATH#\"}
    OUTPUT_PATH=${OUTPUT_PATH%\"}
    OUTPUT_PATH=${OUTPUT_PATH#\'}
    OUTPUT_PATH=${OUTPUT_PATH%\'}
done < "$ENV_FILE"

if [[ -z "${OUTPUT_PATH:-}" ]]; then
    echo "Fehler: OUTPUT_PATH ist in $ENV_FILE nicht gesetzt." >&2
    exit 1
fi

echo "Song-Title: "
read -r TITLE
if [[ -z "$TITLE" ]]; then
    echo "Fehler: Der Titel darf nicht leer sein." >&2
    exit 1
fi

echo "Verein: (1=Waldenrath, 2=Unterbruch)"
read -r LOCATION_CHOICE
case "$LOCATION_CHOICE" in
    1)
        LOCATION="Waldenrath"
        COLLECTION="Musikverein"
        ;;
    2)
        LOCATION="Unterbruch"
        COLLECTION="Unterbruch"
        ;;
    *)
        echo "Fehler: Bitte 1 fuer Waldenrath oder 2 fuer Unterbruch eingeben." >&2
        exit 1
        ;;
esac

OUTPUTFOLDER="$OUTPUT_PATH/$LOCATION"
mkdir -p -- "$OUTPUTFOLDER"
if ! cd -- "$OUTPUTFOLDER"; then
    echo "Fehler: Ausgabeordner nicht erreichbar: $OUTPUTFOLDER" >&2
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

default_part_group() {
    case "$1" in
        Drums|Percussion|Mallets|Timpani|Glockenspiel|Pauken|Schlagzeug)
            printf '%s\n' "$INSTRUMENTGROUP"
            ;;
        *)
            printf '%s\n' "Andere"
            ;;
    esac
}

migrate_manifest_from_import() {
    local csv_title csv_pages ignored collection artist albums genre composer
    local source_type custom_group start_page end_page manifest_group
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
        manifest_group=$custom_group
        [[ -z "$manifest_group" || "$manifest_group" == "$INSTRUMENTGROUP" ]] && manifest_group=$(default_part_group "$source_type")
        printf '%s\t%s\t%s\t%s\n' "$source_type" "$start_page" "$end_page" "$manifest_group" >> "$MANIFEST_FILE"
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

get_part_images() {
    local image
    PART_IMAGE_FILES=()
    while IFS= read -r image; do
        [[ -f "$image" ]] && PART_IMAGE_FILES+=("$image")
    done < <(printf '%s\n' "$SCAN_FOLDER/$TITLETRIM"-*-"$STIMME".jpg | sort -V)
}

remove_part_images_range() {
    local part=$1
    local start_page=$2
    local end_page=$3
    local page

    if [[ ! "$start_page" =~ ^[0-9]+$ || ! "$end_page" =~ ^[0-9]+$ ]]; then
        return
    fi
    for ((page = start_page; page <= end_page; page++)); do
        rm -f -- "$SCAN_FOLDER/$TITLETRIM-$page-$part.jpg"
    done
}

# Older runs could already contain duplicate manifest rows. Keep the first
# occurrence and remove the source images belonging to later occurrences.
deduplicate_manifest() {
    local manifest_tmp part start_page end_page part_group seen duplicate
    local -a seen_parts=()

    manifest_tmp=$(mktemp --tmpdir=. ".scan-parts.XXXXXX")
    while IFS=$'\t' read -r part start_page end_page part_group; do
        [[ -z "$part" ]] && continue
        [[ -z "$part_group" ]] && part_group=$(default_part_group "$part")
        duplicate=0
        for seen in "${seen_parts[@]}"; do
            if [[ "$seen" == "$part" ]]; then
                duplicate=1
                break
            fi
        done
        if (( duplicate )); then
            remove_part_images_range "$part" "$start_page" "$end_page"
            continue
        fi
        seen_parts+=("$part")
        printf '%s\t%s\t%s\t%s\n' "$part" "$start_page" "$end_page" "$part_group" >> "$manifest_tmp"
    done < "$MANIFEST_FILE"
    mv -- "$manifest_tmp" "$MANIFEST_FILE"
}

find_existing_part() {
    local manifest_part manifest_start manifest_end manifest_group
    EXISTING_PART_RANGES=()
    while IFS=$'\t' read -r manifest_part manifest_start manifest_end manifest_group; do
        if [[ "$manifest_part" == "$STIMME" ]]; then
            EXISTING_PART_RANGES+=("$manifest_start:$manifest_end")
        fi
    done < "$MANIFEST_FILE"
}

replace_manifest_part() {
    local manifest_tmp manifest_part manifest_start manifest_end manifest_group replaced
    replaced=0
    manifest_tmp=$(mktemp --tmpdir=. ".scan-parts.XXXXXX")
    while IFS=$'\t' read -r manifest_part manifest_start manifest_end manifest_group; do
        [[ -z "$manifest_part" ]] && continue
        [[ -z "$manifest_group" ]] && manifest_group=$(default_part_group "$manifest_part")
        if [[ "$manifest_part" == "$STIMME" ]]; then
            if (( replaced == 0 )); then
                printf '%s\t%s\t%s\t%s\n' "$STIMME" "$STIMMEPAGESTART" "$STIMMEPAGEENDE" "$PART_GROUP" >> "$manifest_tmp"
                replaced=1
            fi
        else
            printf '%s\t%s\t%s\t%s\n' "$manifest_part" "$manifest_start" "$manifest_end" "$manifest_group" >> "$manifest_tmp"
        fi
    done < "$MANIFEST_FILE"
    if (( replaced == 0 )); then
        printf '%s\t%s\t%s\t%s\n' "$STIMME" "$STIMMEPAGESTART" "$STIMMEPAGEENDE" "$PART_GROUP" >> "$manifest_tmp"
    fi
    mv -- "$manifest_tmp" "$MANIFEST_FILE"
}

pdf_page_count() {
    local pdf_path=$1
    local key value

    if command -v pdfinfo >/dev/null 2>&1; then
        while IFS=: read -r key value; do
            key="${key#${key%%[![:space:]]*}}"
            key="${key%${key##*[![:space:]]}}"
            if [[ "$key" == "Pages" ]]; then
                value="${value#${value%%[![:space:]]*}}"
                [[ "$value" =~ ^[0-9]+$ ]] && printf '%s\n' "$value" && return 0
            fi
        done < <(pdfinfo "$pdf_path" 2>/dev/null)
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import sys; from pypdf import PdfReader; print(len(PdfReader(sys.argv[1]).pages))' \
            "$pdf_path" 2>/dev/null
    fi
}

# Rebuild global page numbers from JPGs and existing voice PDFs. Entries with
# no usable source are removed so the PDF and CSV always describe one another.
normalize_manifest_and_sources() {
    local manifest_part manifest_start manifest_end manifest_group start_page end_page
    local page image new_manifest temp_dir voice_pages original_stimme
    local missing_parts=""
    original_stimme=$STIMME

    temp_dir=$(mktemp -d --tmpdir="$SCAN_FOLDER" ".renumber.XXXXXX")
    new_manifest="$temp_dir/manifest.tsv"
    : > "$temp_dir/files.tsv"
    page=0

    while IFS=$'\t' read -r manifest_part manifest_start manifest_end manifest_group; do
        [[ -z "$manifest_part" ]] && continue
        STIMME=$manifest_part
        get_part_images
        [[ -z "$manifest_group" ]] && manifest_group=$(default_part_group "$manifest_part")

        if (( ${#PART_IMAGE_FILES[@]} > 0 )); then
            start_page=$((page + 1))
            for image in "${PART_IMAGE_FILES[@]}"; do
                page=$((page + 1))
                mv -- "$image" "$temp_dir/$page.jpg"
                printf '%s\t%s\n' "$page" "$manifest_part" >> "$temp_dir/files.tsv"
            done
            end_page=$page
        elif [[ -f "$TITLE-$manifest_part.pdf" ]] && voice_pages=$(pdf_page_count "$TITLE-$manifest_part.pdf") && [[ "$voice_pages" =~ ^[1-9][0-9]*$ ]]; then
            start_page=$((page + 1))
            page=$((page + voice_pages))
            end_page=$page
        else
            missing_parts+=" $manifest_part"
            continue
        fi
        printf '%s\t%s\t%s\t%s\n' "$manifest_part" "$start_page" "$end_page" "$manifest_group" >> "$new_manifest"
    done < "$MANIFEST_FILE"

    while IFS=$'\t' read -r new_page manifest_part; do
        mv -- "$temp_dir/$new_page.jpg" "$SCAN_FOLDER/$TITLETRIM-$new_page-$manifest_part.jpg"
    done < "$temp_dir/files.tsv"
    mv -- "$new_manifest" "$MANIFEST_FILE"
    rm -rf -- "$temp_dir"
    PAGE=$page
    STIMME=$original_stimme

    if [[ -n "$missing_parts" ]]; then
        echo "Warnung: Nicht rekonstruierbare Stimmen wurden aus Manifest, CSV und kombinierten PDFs entfernt:$missing_parts" >&2
    fi
}

deduplicate_manifest

# Continue after the last completed part. Incomplete scans are overwritten on
# the next run instead of creating gaps in the manifest.
PAGE=0
while IFS=$'\t' read -r existing_part existing_start existing_end existing_group; do
    if [[ "$existing_end" =~ ^[0-9]+$ ]] && (( existing_end > PAGE )); then
        PAGE=$existing_end
    fi
done < "$MANIFEST_FILE"

create_pdf() {
    local output_path=$1
    shift
    if (( $# == 0 )); then
        echo "Warnung: Keine Eingabedateien fuer $output_path gefunden." >&2
        return 1
    fi
    convert "$@" "$output_path"
}

write_import_csv() {
    local last_page=$1
    local manifest_part manifest_start manifest_end manifest_group

    printf '%s\n' "title;pages;setlists;collections;artist;albums;genres;composer;source types;custom groups" > "$IMPORT_FILE"
    while IFS=$'\t' read -r manifest_part manifest_start manifest_end manifest_group; do
        [[ -z "$manifest_part" ]] && continue
        [[ -z "$manifest_group" ]] && manifest_group=$(default_part_group "$manifest_part")
        printf '%s;%s-%s;;%s;%s;;%s;%s;%s;%s\n' \
            "$TITLE" "$manifest_start" "$manifest_end" "$COLLECTION" \
            "$ARTIST" "$GENRE" "$COMPOSER" "$manifest_part" "$manifest_group" >> "$IMPORT_FILE"
    done < "$MANIFEST_FILE"

    if (( last_page > 0 )); then
        printf '%s;1-%s;;%s;%s;;%s;%s;%s;%s\n' \
            "$TITLE" "$last_page" "$COLLECTION" "$ARTIST" "$GENRE" \
            "$COMPOSER" "$INSTRUMENTGROUP" "$INSTRUMENTGROUP" >> "$IMPORT_FILE"
    fi
}

get_combined_inputs() {
    local part_filter=$1
    local manifest_part manifest_start manifest_end manifest_group original_stimme=$STIMME
    COMBINED_INPUTS=()
    MISSING_COMBINED_PARTS=()

    while IFS=$'\t' read -r manifest_part manifest_start manifest_end manifest_group; do
        [[ -z "$manifest_part" ]] && continue
        [[ -z "$manifest_group" ]] && manifest_group=$(default_part_group "$manifest_part")
        if [[ "$part_filter" == "schlagwerk" && "$manifest_group" != "$INSTRUMENTGROUP" ]]; then
            continue
        fi
        STIMME=$manifest_part
        get_part_images
        if (( ${#PART_IMAGE_FILES[@]} > 0 )); then
            COMBINED_INPUTS+=("${PART_IMAGE_FILES[@]}")
        elif [[ -f "$TITLE-$manifest_part.pdf" ]]; then
            # Older score folders may no longer have the original JPGs.
            COMBINED_INPUTS+=("$TITLE-$manifest_part.pdf")
        else
            MISSING_COMBINED_PARTS+=("$manifest_part")
        fi
    done < "$MANIFEST_FILE"
    STIMME=$original_stimme
}

build_combined_pdf() {
    local output_path=$1
    local part_filter=$2
    local base_pdf temp_pdf
    get_combined_inputs "$part_filter"

    # If neither source JPGs nor per-voice PDFs are available, use an old
    # combined PDF as the base and append the currently available scans.
    if (( ${#MISSING_COMBINED_PARTS[@]} > 0 )); then
        base_pdf=""
        if [[ "$part_filter" == "schlagwerk" && -f "$GROUP_PDF" ]]; then
            base_pdf=$GROUP_PDF
        elif [[ -f "$TOTAL_PDF" ]]; then
            base_pdf=$TOTAL_PDF
        elif [[ -f "$GROUP_PDF" ]]; then
            base_pdf=$GROUP_PDF
        fi
        if [[ -n "$base_pdf" ]]; then
            COMBINED_INPUTS=("$base_pdf" "${COMBINED_INPUTS[@]}")
        else
            echo "Warnung: Folgende Stimmen konnten nicht aus JPG oder eigener PDF rekonstruiert werden: ${MISSING_COMBINED_PARTS[*]}" >&2
        fi
    fi
    if (( ${#COMBINED_INPUTS[@]} == 0 )); then
        echo "Warnung: Keine Eingabedateien fuer kombinierte PDFs gefunden." >&2
        return 1
    fi

    temp_pdf=$(mktemp --tmpdir=. ".scan-combined.XXXXXX.pdf")
    create_pdf "$temp_pdf" "${COMBINED_INPUTS[@]}" || {
        rm -f -- "$temp_pdf"
        return 1
    }

    echo "Aktualisiere $output_path"
    mv -- "$temp_pdf" "$output_path"
}

update_combined_pdfs() {
    build_combined_pdf "$TOTAL_PDF" "gesamt"
    build_combined_pdf "$GROUP_PDF" "schlagwerk"
}

SCANENDE=0
while (( SCANENDE < 1 )); do
    echo "Which Part are you scanning? (1=Drums, 2=Percussion, 3=Mallets, 4=Timpani, 5=put in text)"
    read -r STIMMECHOICE
    case "$STIMMECHOICE" in
        1)
            STIMME="Drums"
            PART_GROUP=$INSTRUMENTGROUP
            ;;
        2)
            STIMME="Percussion"
            PART_GROUP=$INSTRUMENTGROUP
            ;;
        3)
            STIMME="Mallets"
            PART_GROUP=$INSTRUMENTGROUP
            ;;
        4)
            STIMME="Timpani"
            PART_GROUP=$INSTRUMENTGROUP
            ;;
        5)
            echo "Custom part name: "
            read -r STIMME
            echo "Instrumentengruppe [Schlagwerk]: "
            read -r PART_GROUP
            [[ -z "$PART_GROUP" ]] && PART_GROUP=$INSTRUMENTGROUP
            ;;
        *)
            echo "Wrong input"
            continue
            ;;
    esac

    find_existing_part
    if (( ${#EXISTING_PART_RANGES[@]} > 0 )); then
        echo "Stimme '$STIMME' existiert bereits und wird nach dem Scan ersetzt."
    fi

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
        for existing_range in "${EXISTING_PART_RANGES[@]}"; do
            IFS=: read -r existing_start existing_end <<< "$existing_range"
            remove_part_images_range "$STIMME" "$existing_start" "$existing_end"
        done
        replace_manifest_part
        normalize_manifest_and_sources
        get_part_images
        if ! create_pdf "$TITLE-$STIMME.pdf" "${PART_IMAGE_FILES[@]}"; then
            exit 1
        fi
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
