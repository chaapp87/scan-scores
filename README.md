# scan-score.sh Bash script for music scores from sheet music for MobilSheets

Thi Bash-Script can be used to scan sheet music with a (USB-)scanner on linus.
It is especially made for the use with  the App [MobileSheets](https://www.zubersoft.com/mobilesheets/). 
You can scan various parts in one run of the script. I use it mostly for scanning percussion sheet music for a wind band, which typically includes multiple parts, like 'drums', 'percussion', 'mallets', 'timpani' and so.


## requirements
- Linux computer (bash)
- CLI tool `scanimage`
- a scanner connected to the computer

## input

**Following variables need to be specified hardcoded iside the script:**
- COLLECTION (Collection name for Mobile sheets, in my case the name of the band "Musikverein")
- INSTRUMENTGROUP (In My case this is "Schlagwerk", the german word for the group of percussion instruments)
- SCANNER (The ID of the hardware scannern found with `scanimage --list-devices`
- OUTPUTFOLDER (The target directory)

It also asks for some metadata:
- Title
- Genre
- Artist
- Composer

## output

In the script you can declare an output folder, whih will be the working directory.
The script will always create a new directory with the Song-Title as directory name.

As a result you will get following structure inside the OUTPUTFOLDER:

``` shell
OUTPUTFOLDER/TITLE-PART1.pdf 
OUTPUTFOLDER/TITLE-PART2.pdf
...
OUTPUTFOLDER/TITLE-INSTRUMENTGROUP.pdf
OUTPUTFOLDER/import.csv
```

So you habe dedicated PDF files for all parts and a summarized PDF file for the Instrumentgroup.
This summarized PDF, together with the CSV file is designed for the CSV-import function of the app [MobileSheets](https://www.zubersoft.com/mobilesheets/)

By using this function you will be able to import all the parts with the same title and appropriate metadata for all the parts.

Just use the CSV import function, select the CSV and the summarized pdf and MobileSheets will automatically discover the metadata and splits the PDF file internally like needed.

# installation

Download the sh script and make it executable:

`chmod 744 scan-score.sh`

Change the variables in the variable section `#### VARIABLE SECTION START ###` to fit your needs.
Find your scanner ID: `scanimage --list-devices`


# usage
In a bash shell:
`./scan-score.sh`

The cli includes a menu that guides you through the scan process.


---

# create_print_pdf.py - PDF Druckzusammenstellung

Dieses Python-Skript erstellt auf Basis einer CSV-Datei und einer PDF-Datei eine neue PDF-Datei, die alle zu druckenden Stimmen-Exemplare enthält. Es ist besonders nützlich für Blasorchester-Noten, bei denen verschiedene Instrumentenstimmen in unterschiedlichen Anzahlen gedruckt werden müssen.

## Funktionen

- **CSV-basierte Konfiguration**: Definiere welche Stimmen wie oft gedruckt werden sollen
- **Instrumentengruppen**: Gruppiere Stimmen (z.B. "Flöte", "Klarinette", "Trompete")
- **Gesamtübersicht**: Eine Übersichtsseite am Anfang mit allen zu druckenden Exemplaren
- **Gruppenübersichten**: Jede Instrumentengruppe erhält eine eigene Übersichtsseite
- **Flexible Seitenangaben**: Unterstützt einzelne Seiten ("12") und Bereiche ("2-10")

## CSV-Format

Die CSV-Datei muss folgende Spalten enthalten:

```csv
Instrumentgruppe,Stimme,Seiten,Anzahl
Flöte,Piccoloflöte in C,12,1
Flöte,Flöte in C,13,4
Klarinette,1. Klarinette in B,18,4
Klarinette,2. Klarinette in B,19,6
```

- **Instrumentgruppe**: Name der Gruppe (z.B. "Flöte", "Trompete")
- **Stimme**: Name der spezifischen Stimme
- **Seiten**: Seitenzahl(en) im Original-PDF (z.B. "12" oder "2-10")
- **Anzahl**: Wie viele Exemplare gedruckt werden sollen (0 = überspringen)

## Installation

### Voraussetzungen
- Python 3.7 oder höher
- pip (Python Package Installer)

### Abhängigkeiten installieren

**Option 1: Mit requirements.txt**
```bash
pip install -r requirements.txt
```

**Option 2: Manuelle Installation**
```bash
pip install pypdf reportlab
```

**Auf Systemen mit extern verwaltetem Python (z.B. Arch Linux):**
```bash
pip install -r requirements.txt --break-system-packages
```

## Verwendung

### Grundlegende Verwendung
```bash
python3 create_print_pdf.py <csv_datei> <pdf_datei>
```

### Mit benutzerdefiniertem Ausgabenamen
```bash
python3 create_print_pdf.py <csv_datei> <pdf_datei> <ausgabe_pdf>
```

### Beispiele
```bash
# Standardausgabe (Peronne_Druck.pdf)
python3 create_print_pdf.py Peronne.csv Peronne.pdf

# Eigener Dateiname
python3 create_print_pdf.py Peronne.csv Peronne.pdf MeinDruck.pdf
```

## Ausgabe

Das Skript erstellt eine PDF-Datei mit folgender Struktur:

1. **Gesamtübersicht** - Liste aller zu druckenden Exemplare mit Gesamtzahl
2. **Pro Instrumentengruppe**:
   - Übersichtsseite mit allen Stimmen der Gruppe
   - Alle Exemplare der Stimmen in der angegebenen Anzahl

## Beispiel-Ausgabe

```
==================================================
Gesamtübersicht erstellt
==================================================

==================================================
Instrumentengruppe: Flöte
==================================================
  Piccoloflöte in C: Seite(n) 12 x 1 Exemplare
  Flöte in C: Seite(n) 13 x 4 Exemplare

==================================================
Instrumentengruppe: Klarinette
==================================================
  1. Klarinette in B: Seite(n) 18 x 4 Exemplare
  2. Klarinette in B: Seite(n) 19 x 6 Exemplare
...
==================================================
Ausgabe gespeichert unter: Peronne_Druck.pdf
Gesamtseiten: 111
```

---

# create_marschbuch_pdf.py - Marschbuch-Format (2 Seiten pro Blatt)

Dieses Python-Skript erstellt ein kompaktes Marschbuch-PDF, bei dem 2 Seiten auf ein A4-Blatt gedruckt werden. Die Seiten werden dabei skaliert (maximal 19cm x 13cm), wobei das Seitenverhältnis beibehalten wird.

## Funktionen

- **2 Seiten pro Blatt**: Optimiert für kompaktes Marschbuch-Format
- **Automatische Skalierung**: Seiten werden proportional verkleinert (max 19x13cm)
- **Seitenverhältnis**: Bleibt erhalten, keine Verzerrung
- **Alle Features von create_print_pdf.py**: Übersichtsseiten, Gruppierung, etc.

## Anwendungsfall

Ideal für Musiker, die ihre Noten in einem kompakten Format mitführen möchten:
- 2 Notenseiten pro A4-Blatt
- Kleinere Seitengröße für einfacheres Blättern
- Weniger Papierverbrauch

## Installation

Siehe [Installation](#installation) in der Dokumentation für `create_print_pdf.py`.

## Verwendung

### Grundlegende Verwendung
```bash
python3 create_marschbuch_pdf.py <csv_datei> <pdf_datei>
```

### Mit benutzerdefiniertem Ausgabenamen
```bash
python3 create_marschbuch_pdf.py <csv_datei> <pdf_datei> <ausgabe_pdf>
```

### Beispiele
```bash
# Standardausgabe (Peronne_Marschbuch.pdf)
python3 create_marschbuch_pdf.py Peronne.csv Peronne.pdf

# Eigener Dateiname
python3 create_marschbuch_pdf.py Peronne.csv Peronne.pdf MeinMarschbuch.pdf
```

## Ausgabe

Das Skript erstellt eine A4-PDF-Datei mit:
- **2 Seiten pro Blatt** übereinander angeordnet
- **90° Drehung nach links**: Seiten werden gedreht, um die volle A4-Breite zu nutzen
- **Skalierte Inhalte**: Maximal 19cm Breite x 13cm Höhe pro Seite
- **Beibehaltenes Seitenverhältnis**: Keine Verzerrung der Noten
- **Schnittlinien**: Hilfslinien zum einfachen Auseinanderschneiden
  - 2 vertikale Linien (links und rechts)
  - 4 horizontale Linien (oben, Mitte, 13cm von unten, unten)
  - Mit maximal 5 Schnitten entstehen 2 einzelne Notenblätter mit je 19cm x 13cm

## Beispiel-Ausgabe

```
==================================================
Gesamtübersicht erstellt
==================================================

==================================================
Instrumentengruppe: Flöte
==================================================
  Piccoloflöte in C: Seite(n) 12 x 1 Exemplare
  Flöte in C: Seite(n) 13 x 4 Exemplare
...
Erstelle 2-up Layout aus 111 Seiten...

==================================================
Marschbuch-PDF gespeichert unter: Peronne_Marschbuch.pdf
Originale Seiten: 111
Seiten im Marschbuch: 56 (2 pro Blatt)
```

## Unterschiede zu create_print_pdf.py

| Feature | create_print_pdf.py | create_marschbuch_pdf.py |
|---------|---------------------|--------------------------|
| Seiten pro Blatt | 1 | 2 |
| Seitengröße | Original A4 | Skaliert (max 19x13cm) |
| Ausgabedatei | `[Name]_Druck.pdf` | `[Name]_Marschbuch.pdf` |
| Verwendung | Normaler Druck | Kompaktes Marschbuch |
