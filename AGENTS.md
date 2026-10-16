# Arbeitsanweisungen fuer lokale KI-Sessions

Dieses Repository verwaltet den technischen Workflow fuer die private
Notenbibliothek und MobileSheets. Lies vor jeder Aufgabe:

1. `docs/library-context.md`
2. `docs/session-context.md`
3. `docs/migration-status.md`
4. `docs/mobileSheets-master.md`
5. bei Scan-Aenderungen die relevanten Abschnitte in `README.md`

## Rollen der Systeme

- Dieses Repository enthaelt Skripte, Vorlagen und technische Regeln.
- Die gemountete Seafile-Library `mv-noten` enthaelt Scans, PDFs,
  `import.csv`-Dateien und MobileSheets-Backups.
- Das Windows-Notebook ist das MobileSheets-Mastergeraet und der bevorzugte
  Scan-Arbeitsplatz.
- Der Silverbullet-/Obsidian-Bestand ist kein Arbeitsverzeichnis fuer diese
  Session. Lies ihn nicht pauschal ein und kopiere keine privaten Notizen hierher.

## Sicherheits- und Aenderungsregeln

- Niemals Zugangsdaten, Tokens oder private URLs in Dateien dieses Repositories
  schreiben.
- `.env` enthaelt nur lokale Pfade und bleibt unversioniert.
- PDFs, Scans und MobileSheets-Backups niemals in Git committen.
- Vor Loeschungen, Migrationen oder dem Ersetzen einer Library immer ein
  `.msb`-Backup und eine getrennte Arbeitskopie anlegen.
- Bei Migrationen niemals die Quelle direkt ueberschreiben. Erst in einen
  separaten Zielordner schreiben, pruefen und erst danach uebernehmen.
- `import.csv`, `.scan-metadata` und `.scan-parts.tsv` erhalten. Sie sind fuer
  spaetere Ergaenzungen und Wiederherstellungen notwendig.
- Die KI darf Metadaten und Skripte vorbereiten. Destruktive MobileSheets-
  oder Dateisystemaktionen brauchen eine ausdrueckliche Bestaetigung.
- Wenn der Mount der Noten-Library nicht erreichbar ist, nicht raten. Pfad
  anzeigen und nach dem korrekten Mount fragen.
- Historische Aussagen immer gegen `docs/migration-status.md` pruefen. Einen
  als vorbereitet markierten CSV-Stand nicht als auf dem Master abgenommen
  darstellen.

## Standardarbeitsweise

1. Arbeits- und Zielpfad pruefen, ohne sensible Inhalte auszugeben.
2. Nur den betroffenen Verein, Titelordner oder CSV-Bestand untersuchen.
3. Aenderungen in einem separaten Zielordner erzeugen.
4. CSV-Struktur, Dateinamen, Seitenbereiche und Zielpfade pruefen.
5. Eine kurze Zusammenfassung und offene Entscheidungen ausgeben.

Die verbindlichen Details stehen in `docs/mobileSheets-master.md`.
