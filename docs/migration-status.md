# Migrationsstatus MobileSheets

## Statuswerte

- `[x] vorbereitet`: CSV oder technische Verarbeitung ist vorhanden.
- `[ ] offen`: auf dem Mastergeraet noch zu bearbeiten oder abzunehmen.
- `[?] pruefen`: historischer Stand ist nicht sicher und muss auf dem
  Notebook bzw. in Seafile verifiziert werden.

Eine vorbereitete CSV gilt niemals automatisch als erfolgreich importiert.

## Unterbruch

Die folgenden Titel waren in der Migrationsnotiz als bearbeitet markiert. Vor
der Verteilung an andere Geraete trotzdem auf dem Mastergeraet stichprobenartig
pruefen:

- A Swinkling Christmas
- Adventure
- Bis bald auf Wiedersehen
- Don't Stop Believin'
- Jubelklaenge
- Libertango
- Pirates of the Caribbean
- Rockin' Elise
- Shirim
- The Phantom of the Opera
- The Phantom of the Opera Medley
- The Sound of Silence
- Trumpet Voluntary
- Von Guten Maechten
- Weihnachten in den Bergen
- Winter Wonderland
- Wir sagen euch an den lieben Advent - Macht Hoch die Tuer

**Naechster Test:** `Adventure`. Mindestens eine Gesamtdatei und eine
Schlagwerkstimme importieren, Seiten pruefen, eine Annotation setzen und den
Annotationserhalt nach einem kontrollierten Update pruefen.

## Waldenrath

### In der Migrationsnotiz als bereits bearbeitet markiert

- `Klarinette/Blaues Marschbuch Klarinette1`
- `Klarinette/Einzelstuecke`
- `Klarinette/Kirchennoten Klarinette1`
- `Klarinette/Schwarzes Marschbuch Klarinette1`
- `Klarinette/St. Martin Klarinette1`
- `Klarinette/Weihnachten Klarinette1`

Diese sechs Eintraege sind als historischer Status zu verstehen und muessen
bei der ersten Notebook-Session verifiziert werden.

### Noch offen laut Migrationsnotiz

- All In
- Celtic Crest
- CheckTest
- Forever Young
- Konzert_2026/Eine letzte Runde
- Konzert_2026/Kaiserin Sissi
- Konzert_2026/Klarinette/Eine letzte Runde
- Konzert_2026/Klarinette/Kaiserin Sissi
- Konzert_2026/Klarinette/La Primitiva
- Konzert_2026/Klarinette/Peronne
- Konzert_2026/Klarinette/Selections from Mary Poppins
- Konzert_2026/Klarinette/The March from 1942
- Konzert_2026/Klarinette/The Ultimate Bee Gees
- Konzert_2026/Klarinette/Vive la France
- Konzert_2026/Klarinette/Voice of the Vikings
- Konzert_2026/La Primitiva
- Konzert_2026/Mussinan Marsch
- Konzert_2026/Peronne
- Konzert_2026/Salina con Carina
- Konzert_2026/Selections from Mary Poppins
- Konzert_2026/The March from 1942
- Konzert_2026/The Ultimate Bee Gees
- Konzert_2026/Vive La France
- Konzert_2026/Voice of the Vikings
- Stets treu
- The Story

## Quellenlage und bekannte Abweichungen

- Die aktuelle Masterquelle ist die Seafile-Library `mv-noten`, nicht der
  temporaere `tmp/`-Ordner im Privat-Vault.
- Die im Privat-Vault vorhandenen Beispiel-CSV-Dateien koennen noch alte,
  nicht qualifizierte Titel enthalten. Nicht ungeprueft als Masterdaten
  verwenden.
- Die korrigierten CSVs muessen auf dem Notebook gegen den aktuellen
  Seafile-Bestand geprueft werden, bevor alte MobileSheets-Eintraege geloescht
  werden.
- `PT-004` bezeichnet die Reorganisation und Vervollstaendigung der digitalen
  Notensammlung.
- `PT-154` bezeichnet die separate Uebertragung der Noten der Musikgemeinschaft
  auf das Tablet und bleibt ein eigener offener Vorgang.

## Abnahme-Checkliste pro Verein oder Titelbereich

- [ ] `.msb`-Backup erstellt
- [ ] Quelle und Staging-Ziel eindeutig dokumentiert
- [ ] Anzahl und Namen der CSV-Dateien geprueft
- [ ] Eindeutige Titel mit Stimme bzw. `[Gesamt]` vorhanden
- [ ] Seitenbereiche gegen PDFs geprueft
- [ ] Collection und Metadaten geprueft
- [ ] Import auf dem Notebook abgeschlossen
- [ ] Eine Annotation lokal gespeichert
- [ ] Annotation nach kontrolliertem Update erhalten
- [ ] Erst danach Verteilung an weitere Geraete
