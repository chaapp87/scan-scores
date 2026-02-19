#!/usr/bin/env python3
"""
Erstellt eine neue PDF basierend auf einer CSV-Datei.
Die CSV beschreibt, welche Seiten aus dem Original-PDF wie oft gedruckt werden sollen.
Erstellt Übersichtsseiten pro Instrumentengruppe.
"""

import csv
import sys
from pathlib import Path
from collections import defaultdict

try:
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.lib.units import cm
except ImportError:
    print("Fehler: Erforderliche Bibliotheken nicht installiert.")
    print("Installiere sie mit: pip install pypdf reportlab")
    sys.exit(1)


def parse_pages(pages_str: str) -> list[int]:
    """Parst einen Seitenstring wie '12' oder '2-10' in eine Liste von Seitenzahlen."""
    pages_str = pages_str.strip()
    
    if '-' in pages_str:
        start, end = pages_str.split('-', 1)
        start = int(start.strip())
        end = int(end.strip())
        return list(range(start, end + 1))
    else:
        return [int(pages_str)]


def create_group_overview_page(group_name: str, voices: list[tuple[str, str, int]]) -> Path:
    """Erstellt eine Übersichtsseite für eine Instrumentengruppe als temporäre PDF."""
    temp_path = Path(f"/tmp/overview_{group_name.replace(' ', '_').replace('/', '_')}.pdf")
    
    c = canvas.Canvas(str(temp_path), pagesize=A4)
    width, height = A4
    
    # Titel
    c.setFont("Helvetica-Bold", 24)
    c.drawString(2*cm, height - 3*cm, f"{group_name}")
    
    # Linie unter dem Titel
    c.setStrokeColorRGB(0, 0, 0)
    c.setLineWidth(2)
    c.line(2*cm, height - 3.5*cm, width - 2*cm, height - 3.5*cm)
    
    # Stimmen auflisten
    c.setFont("Helvetica-Bold", 14)
    c.drawString(2*cm, height - 5*cm, "Stimme")
    c.drawString(12*cm, height - 5*cm, "Anzahl")
    
    c.setLineWidth(0.5)
    c.line(2*cm, height - 5.2*cm, width - 2*cm, height - 5.2*cm)
    
    y = height - 5.8*cm
    c.setFont("Helvetica", 12)
    
    total_count = 0
    for voice, pages, count in voices:
        if count > 0:
            c.drawString(2*cm, y, voice)
            c.drawString(12*cm, y, str(count))
            total_count += count
            y -= 0.8*cm
    
    # Linie und Gesamtsumme
    c.line(2*cm, y + 0.3*cm, width - 2*cm, y + 0.3*cm)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(2*cm, y - 0.3*cm, "Gesamt:")
    c.drawString(12*cm, y - 0.3*cm, str(total_count))
    
    c.save()
    return temp_path


def create_master_overview_page(groups: dict[str, list[tuple[str, str, int]]]) -> Path:
    """Erstellt eine Gesamtübersichtsseite am Anfang des PDFs."""
    temp_path = Path("/tmp/overview_master.pdf")
    
    c = canvas.Canvas(str(temp_path), pagesize=A4)
    width, height = A4
    
    # Titel
    c.setFont("Helvetica-Bold", 28)
    c.drawString(2*cm, height - 3*cm, "Druckübersicht")
    
    # Linie unter dem Titel
    c.setStrokeColorRGB(0, 0, 0)
    c.setLineWidth(2)
    c.line(2*cm, height - 3.5*cm, width - 2*cm, height - 3.5*cm)
    
    # Spaltenüberschriften
    c.setFont("Helvetica-Bold", 14)
    c.drawString(2*cm, height - 5*cm, "Instrumentengruppe")
    c.drawString(9*cm, height - 5*cm, "Stimme")
    c.drawString(16*cm, height - 5*cm, "Anzahl")
    
    c.setLineWidth(0.5)
    c.line(2*cm, height - 5.2*cm, width - 2*cm, height - 5.2*cm)
    
    y = height - 5.8*cm
    c.setFont("Helvetica", 11)
    
    grand_total = 0
    
    for group_name in sorted(groups.keys()):
        voices = groups[group_name]
        printable_voices = [(v, p, c) for v, p, c in voices if c > 0]
        
        if not printable_voices:
            continue
        
        # Gruppenname nur bei der ersten Stimme anzeigen
        first = True
        group_total = sum(c for _, _, c in printable_voices)
        
        for voice, pages, count in printable_voices:
            if y < 3*cm:  # Neue Seite wenn nötig
                c.showPage()
                c.setFont("Helvetica", 11)
                y = height - 3*cm
            
            if first:
                c.setFont("Helvetica-Bold", 11)
                c.drawString(2*cm, y, group_name)
                c.setFont("Helvetica", 11)
                first = False
            
            c.drawString(9*cm, y, voice)
            c.drawString(16*cm, y, str(count))
            y -= 0.6*cm
        
        # Kleiner Abstand zwischen Gruppen
        y -= 0.2*cm
        grand_total += group_total
    
    # Gesamtsumme
    if y < 4*cm:
        c.showPage()
        y = height - 3*cm
    
    c.setLineWidth(1)
    c.line(2*cm, y + 0.4*cm, width - 2*cm, y + 0.4*cm)
    c.setFont("Helvetica-Bold", 14)
    c.drawString(2*cm, y - 0.4*cm, "Gesamtzahl aller Exemplare:")
    c.drawString(16*cm, y - 0.4*cm, str(grand_total))
    
    c.save()
    return temp_path


def create_print_pdf(csv_path: Path, pdf_path: Path, output_path: Path):
    """Erstellt die Druck-PDF basierend auf der CSV-Beschreibung."""
    
    # Original-PDF laden
    reader = PdfReader(str(pdf_path))
    writer = PdfWriter()
    
    # Daten einlesen und gruppieren
    groups = defaultdict(list)
    all_rows = []
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        csv_reader = csv.DictReader(f)
        for row in csv_reader:
            gruppe = row['Instrumentgruppe']
            stimme = row['Stimme']
            seiten = row['Seiten']
            anzahl = int(row['Anzahl'])
            
            all_rows.append((gruppe, stimme, seiten, anzahl))
            groups[gruppe].append((stimme, seiten, anzahl))
    
    # Gesamtübersicht am Anfang erstellen
    overview_files = []
    master_overview_path = create_master_overview_page(groups)
    overview_files.append(master_overview_path)
    
    master_reader = PdfReader(str(master_overview_path))
    for page in master_reader.pages:
        writer.add_page(page)
    
    print("\n" + "="*50)
    print("Gesamtübersicht erstellt")
    print("="*50)
    
    # Verarbeitung pro Gruppe
    for gruppe in groups.keys():
        voices = groups[gruppe]
        
        # Prüfen, ob es in dieser Gruppe überhaupt zu druckende Stimmen gibt
        has_printable = any(count > 0 for _, _, count in voices)
        
        if has_printable:
            # Übersichtsseite erstellen
            overview_path = create_group_overview_page(gruppe, voices)
            overview_files.append(overview_path)
            
            # Übersichtsseite hinzufügen
            overview_reader = PdfReader(str(overview_path))
            writer.add_page(overview_reader.pages[0])
            
            print(f"\n{'='*50}")
            print(f"Instrumentengruppe: {gruppe}")
            print(f"{'='*50}")
            
            # Stimmen dieser Gruppe verarbeiten
            for gruppe_name, stimme, seiten, anzahl in all_rows:
                if gruppe_name != gruppe:
                    continue
                    
                if anzahl <= 0:
                    continue
                
                # Seiten parsen
                pages = parse_pages(seiten)
                
                print(f"  {stimme}: Seite(n) {seiten} x {anzahl} Exemplare")
                
                # Seiten die angegebene Anzahl kopieren
                for _ in range(anzahl):
                    for page_num in pages:
                        page_index = page_num - 1
                        if 0 <= page_index < len(reader.pages):
                            writer.add_page(reader.pages[page_index])
                        else:
                            print(f"    Warnung: Seite {page_num} existiert nicht im PDF")
    
    # Neue PDF speichern
    with open(output_path, 'wb') as f:
        writer.write(f)
    
    # Temporäre Übersichtsseiten aufräumen
    for f in overview_files:
        if f.exists():
            f.unlink()
    
    print(f"\n{'='*50}")
    print(f"Ausgabe gespeichert unter: {output_path}")
    print(f"Gesamtseiten: {len(writer.pages)}")


def main():
    if len(sys.argv) < 3:
        print("Verwendung: python create_print_pdf.py <csv_datei> <pdf_datei> [ausgabe_pdf]")
        print("Beispiel: python create_print_pdf.py Peronne.csv Peronne.pdf Peronne_Druck.pdf")
        sys.exit(1)
    
    csv_path = Path(sys.argv[1])
    pdf_path = Path(sys.argv[2])
    
    if len(sys.argv) >= 4:
        output_path = Path(sys.argv[3])
    else:
        output_path = Path(str(pdf_path.parent / (pdf_path.stem + "_Druck.pdf")))
    
    if not csv_path.exists():
        print(f"Fehler: CSV-Datei nicht gefunden: {csv_path}")
        sys.exit(1)
    
    if not pdf_path.exists():
        print(f"Fehler: PDF-Datei nicht gefunden: {pdf_path}")
        sys.exit(1)
    
    create_print_pdf(csv_path, pdf_path, output_path)


if __name__ == "__main__":
    main()
