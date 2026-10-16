# MobileSheets-Master-Workflow

## Zielbild

Das Windows-Notebook ist das einzige Mastergeraet fuer neue Scans und neue
MobileSheets-Eintraege. Die anderen Geraete erhalten die fertigen Daten erst
nach dem Test auf dem Mastergeraet.

Die KI arbeitet lokal und darf dieses Repository sowie den jeweils benoetigten
Unterordner der gemounteten `mv-noten`-Library untersuchen. Der private
Silverbullet-/Obsidian-Vault wird nicht benoetigt.

## Einmalige Vorbereitung des Notebooks

1. WSL 2 und Scanner-Zugriff einrichten.
2. Dieses Repository nach `~/git/scan-scores` auschecken.
3. Abhaengigkeiten gemaess `README.md` installieren.
4. `.env.example` nach `.env` kopieren.
5. `OUTPUT_PATH` in `.env` auf das lokale Mount der Seafile-Library `mv-noten`
   setzen. `.env` niemals committen.
6. Mit `scanimage --list-devices` die Scanner-ID pruefen und bei Bedarf den
   Wert `SCANNER` in `scan-score.sh` anpassen.
7. MobileSheets fuer Windows installieren oder aktualisieren.
8. Vor der ersten Migration aus MobileSheets ein `.msb`-Backup exportieren.

## Neuer Scan

Der normale Scanlauf ist:

```bash
cd ~/git/scan-scores
./scan-score.sh
```

Das Skript fragt Titel, Verein und Metadaten ab und erzeugt die Quelldateien,
PDFs, Manifeste und die MobileSheets-CSV im passenden Titelordner.

Nach dem Lauf pruefen:

- Titelordner und Verein stimmen.
- Alle erwarteten Stimmen sind in `.scan-parts.tsv` enthalten.
- Seitenbereiche in `import.csv` stimmen mit der Gesamt-PDF ueberein.
- Die Schlagwerk-Datei enthaelt nur die benoetigten Schlagwerkstimmen.
- Die MobileSheets-Titel sind eindeutig.

## Bestehende CSVs migrieren

Die Quelle niemals direkt ueberschreiben. Fuer einen Bestand wird ein getrennter
Zielordner verwendet:

```bash
python3 scripts/mobilesheets/qualify_import_titles.py \
  /pfad/zur/mv-noten/Unterbruch \
  /pfad/zum/staging/Unterbruch-qualified
```

Danach die erzeugten CSVs stichprobenartig pruefen. Erst nach dem Vergleich und
mit vorhandenem `.msb`-Backup die Ziel-CSV in die Seafile-Library uebernehmen.

## MobileSheets-Migration

1. MobileSheets auf dem Master beenden oder sicherstellen, dass kein Sync laeuft.
2. `.msb`-Backup erstellen.
3. Nur den betroffenen Verein bzw. Titelbereich bearbeiten.
4. Alte Eintraege des betroffenen Bereichs entfernen, falls die Migration das
   erfordert.
5. Korrigierte `import.csv` importieren.
6. Einen Titel oeffnen und Seiten, Stimme und Collection pruefen.
7. Eine Testannotation setzen und lokal speichern.
8. Einen kontrollierten Sync bzw. ein Update ausfuehren und pruefen, dass die
   Annotation erhalten bleibt.
9. Erst danach die fertige Library an die anderen Geraete verteilen.

## Testfall

Als erster Test eignet sich `Adventure` aus dem Bereich Unterbruch. Der Test
muss mindestens eine Gesamtdatei und eine Schlagwerkstimme abdecken. Der Test
ist erfolgreich, wenn:

- die qualifizierten Titel korrekt angezeigt werden,
- die Seitenbereiche auf die erwarteten PDF-Seiten zeigen,
- Collection und Metadaten stimmen,
- eine lokale Annotation nach dem kontrollierten Update erhalten bleibt.

## KI-Arbeitsregeln

- Die KI bevorzugt Skripte und reproduzierbare Verarbeitung gegen manuelle
  Einzelkorrekturen.
- Die KI arbeitet zuerst auf Kopien oder in einem Staging-Ordner.
- Die KI darf keine PDFs, Scans, CSVs oder MobileSheets-Eintraege loeschen,
  solange keine ausdrueckliche Bestaetigung vorliegt.
- Bei unklaren Titeln, Stimmen, Seitenbereichen oder Duplikaten fragt sie nach.
- Die KI gibt keine Zugangsdaten oder privaten Vault-Inhalte aus.
- Vor jeder Datenmigration nennt die KI Quelle, Ziel und erwartete Aenderung.
