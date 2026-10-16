# Bibliothekskontext

## Zweck

Die Notenbibliothek wird fuer digitale Noten in MobileSheets gepflegt. Neue
Stuecke werden auf dem Windows-Notebook als Master importiert und danach auf
andere MobileSheets-Geraete verteilt.

## Daten- und Systemrollen

| Bereich | Rolle |
|---|---|
| `scan-scores` | Skripte, CSV-Vorlagen, Metadatenregeln und technische Dokumentation |
| `mv-noten` in Seafile | Masterdaten: Scans, PDFs, `import.csv` und `.msb`-Backups |
| Windows-Notebook | Scanner-Arbeitsplatz und MobileSheets-Master |
| Silverbullet-/Obsidian-Vault | Private Notizen; nicht automatisch einlesen oder spiegeln |

Der lokale Pfad zur Seafile-Library wird ausschliesslich in `.env` als
`OUTPUT_PATH` gesetzt. Der konkrete Pfad ist installationsabhaengig und darf
nicht in Git festgeschrieben werden.

Der dokumentierte Zielpfad fuer die Seafile-CLI ist `~/Sync/mv-noten`. Auf dem
Notebook muss dieser Pfad vor dem ersten Scan mit `seaf-cli status` verifiziert
werden. Zugangsdaten und Tokens werden nur lokal bzw. interaktiv verwendet.

## Verzeichnisstruktur

Das Scan-Skript legt unter `OUTPUT_PATH` automatisch diese Bereiche an:

- `Waldenrath/`
- `Unterbruch/`

Jeder Titelordner enthaelt nach Moeglichkeit:

- `scans/` mit den JPG-Quelldateien
- `.scan-metadata` mit Titel, Artist, Genre und Composer
- `.scan-parts.tsv` mit Stimme, Seitenbereich und Instrumentengruppe
- `import.csv` fuer MobileSheets
- `<Titel>-Gesamt.pdf`
- `<Titel>-Schlagwerk.pdf`

Quelldateien und kleine Manifestdateien bleiben erhalten. Sie werden bei
spaeteren Scan-Laeufen benoetigt.

## MobileSheets-Konventionen

- Waldenrath verwendet die Collection `Musikverein`.
- Unterbruch verwendet die Collection `Unterbruch`.
- Ein Titel muss in MobileSheets pro Stimme eindeutig sein.
- Das aktuelle Importformat lautet:
  - Stimme: `<Titel> [<Stimme>]`
  - Gesamtdatei: `<Titel> [Gesamt]`
- Reine, wiederholte Stuecktitel fuer mehrere Dateien nicht wiederherstellen.
- Die CSV-Spalten sind:

```text
title;pages;setlists;collections;artist;albums;genres;composer;source types;custom groups
```

## Bekannter Migrationsstand

- Die Importtitel fuer Unterbruch wurden am 15.10.2026 qualifiziert.
- Vor dem Loeschen alter Eintraege muss ein `.msb`-Backup erstellt werden.
- Die alten CSV-Dateien liegen in der Seafile-Library unter
  `mv-noten/MobileSheets-Migration-2026-10-15/original/`.
- Die korrigierten CSV-Dateien liegen unter
  `mv-noten/MobileSheets-Migration-2026-10-15/corrected/`.
- Waldenrath ist noch nicht vollstaendig migriert.

Der ausfuehrliche Titelstatus steht in `docs/migration-status.md`. Die
Migrationsnotiz unterscheidet zwischen vorbereiteten CSVs und dem spaeteren
Import-/Annotationstest auf dem Mastergeraet.

## Prioritaeten bei Unklarheiten

1. Keine Daten verlieren.
2. Bestehende Annotationen und MobileSheets-Backups schuetzen.
3. Eindeutige Titel und stabile Dateipfade sicherstellen.
4. Erst danach Metadaten vereinheitlichen oder aufraeumen.
