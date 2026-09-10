#!/usr/bin/env python3
"""
Erstellt ein Marschbuch-PDF basierend auf einer CSV-Datei.
2 Seiten pro Blatt übereinander (90° gedreht), skaliert auf max 19cm x 13cm, Seitenverhältnis beibehalten.
"""

import csv
import sys
from pathlib import Path
from collections import defaultdict

try:
    from pypdf import PdfReader, PdfWriter, Transformation, PageObject
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.lib.units import cm
    from reportlab.lib.colors import black
except ImportError:
    print("Fehler: Erforderliche Bibliotheken nicht installiert.")
    print("Installiere sie mit: pip install pypdf reportlab")
    sys.exit(1)


# Konfiguration für Marschbuch-Format
MAX_WIDTH_CM = 19  # Maximale Breite in cm
MAX_HEIGHT_CM = 13  # Maximale Höhe in cm
MAX_WIDTH_PT = MAX_WIDTH_CM * 28.35  # Umrechnung in Points (1 cm ≈ 28.35 pt)
MAX_HEIGHT_PT = MAX_HEIGHT_CM * 28.35


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


def create_2up_page_with_guides(page1: PageObject, page2: PageObject = None) -> PageObject:
    """Erstellt eine A4-Seite mit 2 Seiten übereinander (90° gedreht) und Schnittlinien."""
    from reportlab.pdfgen import canvas as canvas_module
    from reportlab.lib.colors import black
    
    # Neue A4-Seite erstellen (Hochformat)
    new_page = PageObject.create_blank_page(width=A4[0], height=A4[1])
    
    # Positionen und Größen speichern für Schnittlinien
    upper_info = None
    lower_info = None
    
    # Obere Seite (erste Seite) - um 90° nach links gedreht
    if page1:
        page1_width = float(page1.mediabox.width)
        page1_height = float(page1.mediabox.height)
        
        # Nach 90° Drehung nach links:
        # - Original-Breite wird zur Höhe auf dem A4
        # - Original-Höhe wird zur Breite auf dem A4
        # Skalierung für max 19cm Breite und 13cm Höhe:
        scale_w = MAX_WIDTH_PT / page1_height  # 19cm / Original-Höhe
        scale_h = MAX_HEIGHT_PT / page1_width  # 13cm / Original-Breite
        scale1 = min(scale_w, scale_h)
        
        # Skalierte Größe nach Drehung berechnen
        new_width1 = page1_height * scale1  # wird zur Breite auf A4
        new_height1 = page1_width * scale1  # wird zur Höhe auf A4
        
        # Position: horizontal zentriert, oben mit 1cm Abstand
        upper_x = (A4[0] - new_width1) / 2
        upper_y = A4[1] - new_height1 - 1*cm  # 1cm Abstand vom oberen Rand
        
        upper_info = (upper_x, upper_y, new_width1, new_height1)
        
        # Transformation: skalieren, 90° nach links drehen, positionieren
        # Bei 90° links-Drehung: Ursprung verschiebt sich, daher +new_width1 bei x
        transformation1 = (Transformation()
                          .scale(scale1, scale1)
                          .rotate(90)  # 90° nach links (gegen Uhrzeigersinn)
                          .translate(upper_x + new_width1, upper_y))
        new_page.merge_transformed_page(page1, transformation1)
    
    # Untere Seite (zweite Seite) - um 90° nach links gedreht
    if page2:
        page2_width = float(page2.mediabox.width)
        page2_height = float(page2.mediabox.height)
        
        # Skalierung berechnen
        scale_w = MAX_WIDTH_PT / page2_height
        scale_h = MAX_HEIGHT_PT / page2_width
        scale2 = min(scale_w, scale_h)
        
        # Skalierte Größe nach Drehung berechnen
        new_width2 = page2_height * scale2
        new_height2 = page2_width * scale2
        
        # Position: horizontal zentriert, unten mit 1cm Abstand
        lower_x = (A4[0] - new_width2) / 2
        lower_y = 1*cm  # 1cm Abstand vom unteren Rand
        
        lower_info = (lower_x, lower_y, new_width2, new_height2)
        
        # Transformation: skalieren, 90° nach links drehen, positionieren
        transformation2 = (Transformation()
                          .scale(scale2, scale2)
                          .rotate(90)
                          .translate(lower_x + new_width2, lower_y))
        new_page.merge_transformed_page(page2, transformation2)
    
    # Schnittlinien erstellen
    temp_guides_path = Path("/tmp/cutting_guides_temp.pdf")
    c = canvas_module.Canvas(str(temp_guides_path), pagesize=A4)
    
    c.setDash(3, 3)  # 3pt Strich, 3pt Lücke
    c.setStrokeColor(black)
    c.setLineWidth(0.5)
    
    # Schnittlinien basierend auf der oberen Seite
    if upper_info:
        x, y, w, h = upper_info
        
        # Linke vertikale Schnittlinie
        c.line(x, 0, x, A4[1])
        # Rechte vertikale Schnittlinie
        c.line(x + w, 0, x + w, A4[1])
        
        # Obere horizontale Schnittlinie
        c.line(0, y + h, A4[0], y + h)
        
        # Untere horizontale Schnittlinie (untere Kante der oberen Seite)
        c.line(0, y, A4[0], y)
    
    # Zusätzliche Schnittlinie für untere Seite (13cm oberhalb der untersten Linie)
    if lower_info:
        lx, ly, lw, lh = lower_info
        # Linie bei 13cm Höhe von unten gemessen
        cut_y = ly + lh
        c.line(0, cut_y, A4[0], cut_y)
    
    # Untere horizontale Schnittlinie (untere Kante der unteren Seite)
    if lower_info:
        lx, ly, lw, lh = lower_info
        c.line(0, ly, A4[0], ly)
    
    c.save()
    
    # Schnittlinien überlagern
    guides_reader = PdfReader(str(temp_guides_path))
    new_page.merge_page(guides_reader.pages[0])
    
    # Aufräumen
    temp_guides_path.unlink()
    
    return new_page


def create_marschbuch_pdf(csv_path: Path, pdf_path: Path, output_path: Path):
    """Erstellt das Marschbuch-PDF (2 Seiten pro Blatt, skaliert)."""
    
    # Original-PDF laden
    reader = PdfReader(str(pdf_path))
    
    # Zwischen-PDF erstellen (mit allen Seiten in Originalgröße)
    temp_writer = PdfWriter()
    
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
        temp_writer.add_page(page)
    
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
            temp_writer.add_page(overview_reader.pages[0])
            
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
                            temp_writer.add_page(reader.pages[page_index])
                        else:
                            print(f"    Warnung: Seite {page_num} existiert nicht im PDF")
    
    # Temporäre Datei speichern
    temp_pdf_path = Path("/tmp/temp_marschbuch.pdf")
    with open(temp_pdf_path, 'wb') as f:
        temp_writer.write(f)
    
    # Jetzt 2-up Layout mit Schnittlinien erstellen
    final_writer = PdfWriter()
    temp_reader = PdfReader(str(temp_pdf_path))
    
    total_pages = len(temp_reader.pages)
    print(f"\nErstelle 2-up Layout mit Schnittlinien aus {total_pages} Seiten...")
    
    # Seiten paarweise verarbeiten
    for i in range(0, total_pages, 2):
        page1 = temp_reader.pages[i]
        page2 = temp_reader.pages[i + 1] if i + 1 < total_pages else None
        
        new_page = create_2up_page_with_guides(page1, page2)
        final_writer.add_page(new_page)
    
    # Finale PDF speichern
    with open(output_path, 'wb') as f:
        final_writer.write(f)
    
    # Aufräumen
    temp_pdf_path.unlink()
    for f in overview_files:
        if f.exists():
            f.unlink()
    
    print(f"\n{'='*50}")
    print(f"Marschbuch-PDF gespeichert unter: {output_path}")
    print(f"Originale Seiten: {total_pages}")
    print(f"Seiten im Marschbuch: {len(final_writer.pages)} (2 pro Blatt)")


def main():
    if len(sys.argv) < 3:
        print("Verwendung: python create_marschbuch_pdf.py <csv_datei> <pdf_datei> [ausgabe_pdf]")
        print("Beispiel: python create_marschbuch_pdf.py Peronne.csv Peronne.pdf Peronne_Marschbuch.pdf")
        sys.exit(1)
    
    csv_path = Path(sys.argv[1])
    pdf_path = Path(sys.argv[2])
    
    if len(sys.argv) >= 4:
        output_path = Path(sys.argv[3])
    else:
        output_path = Path(str(pdf_path.parent / (pdf_path.stem + "_Marschbuch.pdf")))
    
    if not csv_path.exists():
        print(f"Fehler: CSV-Datei nicht gefunden: {csv_path}")
        sys.exit(1)
    
    if not pdf_path.exists():
        print(f"Fehler: PDF-Datei nicht gefunden: {pdf_path}")
        sys.exit(1)
    
    create_marschbuch_pdf(csv_path, pdf_path, output_path)


if __name__ == "__main__":
    main()
