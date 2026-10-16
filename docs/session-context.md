# Sitzungs- und Projektkontext

Dieses Dokument bewahrt Entscheidungen und Erkenntnisse aus den bisherigen
Sessions. Es ist bewusst auf den Noten-/Scan-Workflow begrenzt und ersetzt
nicht private Silverbullet- oder Obsidian-Notizen.

## Zielbild

- Das Windows-Notebook ist das Mastergeraet fuer MobileSheets und der
  bevorzugte Scan-Arbeitsplatz.
- Neue Scans werden auf dem Notebook erstellt, dort in MobileSheets geprueft
  und erst danach auf andere Geraete verteilt.
- `scan-scores` ist die technische Quelle fuer Skripte, Metadatenregeln,
  Dokumentation und reproduzierbare Migrationen.
- Seafile `mv-noten` ist die Datenquelle fuer Scans, PDFs, Importdateien und
  MobileSheets-Backups.
- Eine lokale KI-Session arbeitet im Repository und bei Bedarf in genau dem
  betroffenen Unterordner von `~/Sync/mv-noten`.
- Der Silverbullet-/Obsidian-Vault wird nicht pauschal gespiegelt.

## Bereits umgesetzt

### Repository

- `scan-score.sh` erzeugt fuer neue Stimmen eindeutige MobileSheets-Titel:
  `<Titel> [<Stimme>]`.
- Die Gesamtdatei wird als `<Titel> [Gesamt]` eingetragen.
- `scripts/mobilesheets/qualify_import_titles.py` kann bestehende CSV-Bestaende
  in einen getrennten Zielordner migrieren.
- Der Kontext fuer lokale KI-Sessions liegt in `AGENTS.md` und `docs/`.
- Diese Aenderungen wurden in Commit `7bdfe1e` nach GitHub gepusht.

### Bestehende Migration

- Am 15.10.2026 wurden die bestehenden Import-CSV-Dateien fuer Unterbruch und
  Waldenrath mit eindeutigen Titeln vorbereitet.
- Original-CSV-Dateien liegen in der Seafile-Library unter
  `mv-noten/MobileSheets-Migration-2026-10-15/original/`.
- Korrigierte CSV-Dateien liegen unter
  `mv-noten/MobileSheets-Migration-2026-10-15/corrected/`.
- Das bedeutet nur: CSV-Korrektur ist vorbereitet. Ob die Daten bereits auf
  dem Notebook in MobileSheets importiert, getestet und synchronisiert wurden,
  muss auf dem Mastergeraet noch geprueft werden.

## Noch offene Einrichtung

- WSL 2 auf dem Notebook auf aktuellem Stand pruefen.
- Seafile CLI einrichten und `mv-noten` nach `~/Sync/mv-noten` synchronisieren.
- `.env` im Repository mit dem lokalen `OUTPUT_PATH` auf `~/Sync/mv-noten`
  konfigurieren.
- Scanner per USB/IP an WSL anschliessen und `scanimage -L` bestaetigen.
- MobileSheets fuer Windows auf dem Notebook als Master einrichten.
- Vor einer MobileSheets-Migration ein `.msb`-Backup erstellen.
- Mit `Adventure` aus Unterbruch einen Import-, Seiten- und
  Annotationserhalt-Test durchfuehren.
- Erst nach erfolgreichem Test die korrigierte Library an andere Geraete
  verteilen.

## Arbeitsentscheidungen

- Keine privaten Vault-Dateien in dieses Repository kopieren.
- Keine PDFs, Scans, `.msb`-Backups oder Seafile-Tokens in Git speichern.
- CSV-Migrationen immer in einen Staging-Ordner schreiben, nie direkt in der
  Quelle ersetzen.
- Vor dem Loeschen oder Neuimport in MobileSheets immer Backup und
  Rueckfallmoeglichkeit sicherstellen.
- Die KI darf technische Dateien und Metadaten vorbereiten. Destruktive
  Datei- oder MobileSheets-Aktionen brauchen eine explizite Bestaetigung.
- Bei unklaren Titeln, Stimmen, Seitenbereichen oder Duplikaten nachfragen.

## Begriffe

- **Master:** Notebook, auf dem gescannt und zuerst in MobileSheets importiert
  wird.
- **Datenquelle:** `~/Sync/mv-noten`, synchronisiert durch Seafile.
- **Staging:** Separater temporaerer Zielordner fuer qualifizierte CSVs oder
  andere vorbereitete Migrationsergebnisse.
- **Abnahme:** Titel, Collection, Seiten, PDF-Zuordnung und Annotation wurden
  auf dem Mastergeraet geprueft.
