from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.platypus import Table, TableStyle
from reportlab.lib import colors

# Dark teal (#0D7C66) -> RGB: 13, 124, 102
teal_color = colors.Color(13/255.0, 124/255.0, 102/255.0)
grey_color = colors.Color(248/255.0, 250/255.0, 251/255.0) # #F8FAFB
line_color = colors.Color(224/255.0, 230/255.0, 234/255.0) # #E0E6EA

def draw_pdf(filename):
    c = canvas.Canvas(filename, pagesize=A4)
    width, height = A4
    margin = 10 * mm
    current_y = height - margin
    
    # 1. HEADER BAR (full width, teal background, 14mm tall)
    c.setFillColor(teal_color)
    c.rect(margin, current_y - 14*mm, width - 2*margin, 14*mm, fill=1, stroke=0)
    
    c.setFillColor(colors.white)
    # Left
    c.setFont("Helvetica-Bold", 13)
    c.drawString(margin + 3*mm, current_y - 6*mm, "Dukan Sathi")
    c.setFont("Helvetica", 7)
    c.drawString(margin + 3*mm, current_y - 11*mm, "Retail business • State: AS")
    
    # Right
    c.setFont("Helvetica-Bold", 11)
    c.drawRightString(width - margin - 3*mm, current_y - 6*mm, "TAX INVOICE")
    c.setFont("Helvetica", 7)
    c.drawRightString(width - margin - 3*mm, current_y - 11*mm, "Invoice: INV-12345 | Date: 2026-04-26")
    
    current_y -= 14*mm
    
    # 2. INFO STRIP (2 columns, grey background, 8mm tall, 7pt font)
    c.setFillColor(colors.HexColor("#EEEEEE")) # Grey background for strip
    c.rect(margin, current_y - 8*mm, width - 2*margin, 8*mm, fill=1, stroke=0)
    
    c.setFillColor(colors.black)
    c.setFont("Helvetica", 7)
    c.drawString(margin + 3*mm, current_y - 5*mm, "Customer: mazi | Phone: - | State (POS): AS")
    
    # Pill for STATUS
    c.setFillColor(colors.orange)
    c.roundRect(width - margin - 22*mm, current_y - 6.5*mm, 19*mm, 5*mm, 2.5*mm, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 6)
    c.drawCentredString(width - margin - 12.5*mm, current_y - 5.2*mm, "PARTIAL")
    
    c.setFillColor(colors.black)
    c.setFont("Helvetica", 7)
    c.drawRightString(width - margin - 24*mm, current_y - 5*mm, "Approval ID: 33258c3a-2e87-4671-9a24-b3b3835dc1e2 | Status:")
    
    current_y -= 8*mm
    
    # 3. ITEMS TABLE
    # Widths requested: 8mm | 65mm | 18mm | 14mm | 10mm | 22mm | 22mm
    # We'll adjust slightly to fit 190mm: 8 | 75 | 18 | 14 | 14 | 30.5 | 30.5
    data = [
        ["#", "Item Name", "HSN", "GST%", "Qty", "Rate", "Amount"],
        ["1", "Parle-G Bkt (800g)", "1905", "5%", "1", "49.50", "49.50"],
        ["2", "N.bk A4 (200pg)", "4820", "12%", "1", "76.50", "76.50"],
        ["3", "Cke (750ml)", "2202", "28%", "1", "40.50", "40.50"],
        ["4", "Basmati Rice (5kg)", "1006", "18%", "1", "405.00", "405.00"],
        ["5", "Aml Buttr (500g)", "0405", "12%", "1", "247.50", "247.50"],
        ["6", "Det Soap (75g)-Ent1", "3401", "18%", "1", "43.20", "43.20"],
        ["7", "T-Slt (1kg)", "2501", "18%", "1", "21.60", "21.60"],
        ["8", "Gold Ring (2g)", "7113", "3%", "1", "8820.00", "8820.00"],
        ["9", "Det Soap (75g)-Ent2", "3401", "18%", "1", "43.20", "43.20"],
        ["10", "Surf Xcl Det (1kg)", "3402", "18%", "1", "107.10", "107.10"],
        ["11", "Marlboro Cig", "2402", "28%", "1", "297.00", "297.00"],
        ["12", "Real Apple Juice(1L)", "2202", "12%", "1", "126.00", "126.00"],
        ["13", "Dell Monitor", "8471", "18%", "1", "13950.00", "13950.00"]
    ]
    
    table = Table(data, colWidths=[8*mm, 75*mm, 18*mm, 14*mm, 14*mm, 30.5*mm, 30.5*mm])
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), teal_color),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 6),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 2),
        ('TOPPADDING', (0, 0), (-1, 0), 2),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('ALIGN', (3, 0), (-1, -1), 'RIGHT'),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 1),
        ('TOPPADDING', (0, 1), (-1, -1), 1),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, line_color),
        ('BOX', (0, 0), (-1, -1), 0, colors.white),
    ])
    
    for i in range(1, len(data)):
        if i % 2 == 1:
            style.add('BACKGROUND', (0, i), (-1, i), colors.white)
        else:
            style.add('BACKGROUND', (0, i), (-1, i), grey_color)
            
    table.setStyle(style)
    
    # Calculate height to draw
    w, h = table.wrap(width - 2*margin, current_y)
    current_y -= h
    table.drawOn(c, margin, current_y)
    
    current_y -= 5*mm
    
    # 4. BILLING SUMMARY (2 columns side by side, below items table)
    # LEFT — GST Rate-wise Summary
    gst_data = [
        ["GST%", "Taxable", "CGST", "SGST", "Total Tax"],
        ["3%", "8820.00", "132.30", "132.30", "264.60"],
        ["5%", "49.50", "1.24", "1.24", "2.48"],
        ["12%", "450.00", "27.00", "27.00", "54.00"],
        ["18%", "14570.10", "1311.31", "1311.31", "2622.62"],
        ["28%", "337.50", "47.25", "47.25", "94.50"]
    ]
    
    gst_table = Table(gst_data, colWidths=[15*mm, 25*mm, 20*mm, 20*mm, 20*mm])
    gst_style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), teal_color),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
        ('TOPPADDING', (0, 0), (-1, -1), 1),
        ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
        ('ALIGN', (0, 0), (0, -1), 'LEFT'),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, line_color),
        ('BOX', (0, 0), (-1, -1), 0.5, line_color),
    ])
    gst_table.setStyle(gst_style)
    gw, gh = gst_table.wrap(100*mm, current_y)
    
    # RIGHT — Invoice Totals (right-aligned)
    totals_data = [
        ["Subtotal:", "26919.00"],
        ["Discount:", "-2691.90"],
        ["Taxable Value:", "24227.10"],
        ["CGST:", "1519.10"],
        ["SGST:", "1519.10"],
        ["Grand Total:", "27265.30"],
        ["Paid:", "20000.00"],
        ["Due Amount:", "7265.30"]
    ]
    
    totals_table = Table(totals_data, colWidths=[35*mm, 30*mm])
    totals_style = TableStyle([
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 7),
        ('ALIGN', (0, 0), (0, -1), 'LEFT'),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
        ('TOPPADDING', (0, 0), (-1, -1), 1),
        ('LINEABOVE', (0, 5), (-1, 5), 1, line_color), # Above Grand total
        ('FONTNAME', (0, 5), (-1, 5), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 5), (-1, 5), 9),
        ('TEXTCOLOR', (0, 5), (-1, 5), teal_color),
        ('TEXTCOLOR', (1, 6), (1, 6), colors.green),
        ('TEXTCOLOR', (1, 7), (1, 7), colors.red),
        ('FONTNAME', (0, 7), (-1, 7), 'Helvetica-Bold'),
    ])
    totals_table.setStyle(totals_style)
    tw, th = totals_table.wrap(70*mm, current_y)
    
    # Draw them side by side
    max_h = max(gh, th)
    current_y -= max_h
    gst_table.drawOn(c, margin, current_y + max_h - gh)
    totals_table.drawOn(c, width - margin - tw, current_y + max_h - th)
    
    # 5. FOOTER (full width, teal background, 10mm tall)
    # Fixed at the bottom of the page
    footer_y = margin
    c.setFillColor(teal_color)
    c.rect(margin, footer_y, width - 2*margin, 10*mm, fill=1, stroke=0)
    
    c.setFillColor(colors.white)
    c.setFont("Helvetica", 7)
    c.drawString(margin + 3*mm, footer_y + 4*mm, "Reverse Charge: No | Intra-state: CGST+SGST applied")
    
    c.setFont("Helvetica-Oblique", 5)
    c.drawCentredString(width / 2.0, footer_y + 4*mm, "This is an auto-generated invoice")
    
    c.setFont("Helvetica", 7)
    c.drawRightString(width - margin - 3*mm, footer_y + 4*mm, "Authorized Signatory")
    c.setStrokeColor(colors.white)
    c.line(width - margin - 26*mm, footer_y + 8*mm, width - margin - 3*mm, footer_y + 8*mm)
    
    c.save()

draw_pdf("invoice_compact.pdf")
