# scan-scores

Werkzeuge zum Scannen, Zusammenfuehren und Drucken von Noten fuer
Blasorchester und MobileSheets.

## Werkzeuge

- `scan-score.sh`: Scannt einzelne Stimmen und erzeugt PDFs sowie eine
  MobileSheets-Importdatei.
- `scripts/pdf/create_print_pdf.py`: Erstellt eine Druckzusammenstellung aus
  einer CSV-Datei und einer zusammengefuehrten PDF.
- `scripts/pdf/create_marschbuch_pdf.py`: Erstellt aus derselben Eingabe ein
  Marschbuch-PDF mit zwei Seiten pro Blatt.
- `templates/Noten-Druckvorlage.csv`: Vorlage fuer Instrumente und typische
  Stueckzahlen. Die Seitenzahlen werden je Musikstueck eingetragen.

## Installation

Voraussetzungen:

- Python 3.7 oder neuer
- `pypdf` und `reportlab`
- fuer `scan-score.sh`: Linux, `scanimage` und ein angeschlossener Scanner

```bash
python3 -m pip install -r requirements.txt
```

## Druck-PDF erstellen

Die Druckskripte erwarten eine einzige PDF, deren Seiten zu den Seitenangaben
der CSV passen. Einzelne Stimmen koennen vorher mit `pdfunite` zusammengefuehrt
werden.

```bash
pdfunite \
  Cover.pdf \
  Partitur.pdf \
  Stimmenliste.pdf \
  Stimme-1.pdf \
  Stimme-2.pdf \
  Gesamt.pdf
```

CSV und Gesamt-PDF verarbeiten:

```bash
python3 scripts/pdf/create_print_pdf.py \
  meine-stimmen.csv \
  Gesamt.pdf \
  Meine-Noten-Druck.pdf
```

Die Ausgabe enthaelt eine Gesamtuebersicht, Gruppenuebersichten und danach
die Stimmen in der jeweils angegebenen Anzahl. Stimmen mit `Anzahl=0` werden
uebersprungen.

## Marschbuch-PDF

```bash
python3 scripts/pdf/create_marschbuch_pdf.py \
  meine-stimmen.csv \
  Gesamt.pdf \
  Meine-Noten-Marschbuch.pdf
```

## CSV-Format

Die CSV-Datei verwendet vier Spalten:

```csv
Instrumentgruppe,Stimme,Seiten,Anzahl
Flöte,Piccoloflöte in C,12,2
Flöte,1. Flöte in C,13,5
Klarinette,1. Klarinette in B,14,3
```

- `Instrumentgruppe`: Gruppierung fuer die Uebersichtsseiten.
- `Stimme`: Bezeichnung der Stimme.
- `Seiten`: Seite oder Seitenbereich in der Gesamt-PDF, z. B. `12` oder `2-10`.
- `Anzahl`: Anzahl der zu druckenden Exemplare; `0` ueberspringt die Stimme.

Die Vorlage `templates/Noten-Druckvorlage.csv` kann fuer neue Stuecke kopiert
werden. Danach muessen mindestens die Seitenzahlen und gegebenenfalls die
Stueckzahlen angepasst werden.

## Scanner-Skript

Vor der ersten Nutzung die Variablen im Abschnitt `VARIABLE SECTION START`
von `scan-score.sh` anpassen, insbesondere Scanner-ID, Ausgabeordner,
Sammlung und Instrumentengruppe.

```bash
chmod 744 scan-score.sh
./scan-score.sh
```

### Nachtraeglich weitere Stimmen scannen

Das Skript kann fuer dasselbe Stueck mehrfach ausgefuehrt werden. Beim zweiten
Lauf den bereits vorhandenen Titelordner auswaehlen und die vorhandenen
Metadaten uebernehmen. Der letzte abgeschlossene Seitenstand wird aus
`.scan-parts.tsv` fortgesetzt; neue Stimmen werden an die Gesamt-PDF angehaengt.

Pro Titelordner werden folgende Dateien fortgeschrieben:

- `scans/`: JPG-Quelldateien fuer spaetere PDF-Aktualisierungen.
- `.scan-metadata`: Artist, Genre und Composer fuer spaetere Laeufe.
- `.scan-parts.tsv`: Zuordnung von Stimme und Seitenbereich.
- `import.csv`: MobileSheets-Import mit allen bisher gescannten Stimmen.
- `<Titel>-Gesamt.pdf`: alle bisher gescannten Seiten in Scan-Reihenfolge.
- `<Titel>-Schlagwerk.pdf`: die Schlagwerk-Gesamtdatei.

Die JPG-Quelldateien bleiben absichtlich im Unterordner `scans/`. Sie werden
fuer die Neuerstellung der kombinierten PDFs bei spaeteren Scans benoetigt.
