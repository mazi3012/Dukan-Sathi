import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/database.dart';
import '../models/cart_item.dart';
import '../models/draft_approval.dart';
import '../models/tax_breakdown.dart';

enum InvoicePdfTemplate {
  igst,
  cgstSgst,
  nonGst,
  composite,
}

class GeneratedInvoicePdf {
  GeneratedInvoicePdf({
    required this.file,
    required this.caption,
    required this.template,
  });

  final File file;
  final String caption;
  final InvoicePdfTemplate template;
}

class InvoicePdfGenerator {
  static const List<String> _fontCandidates = [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    '/opt/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto/Roboto-Regular.ttf',
  ];

  static InvoicePdfTemplate resolveTemplate(TaxBreakdown taxBreakdown) {
    if (taxBreakdown.gstMode == 'COMPOSITE') {
      return InvoicePdfTemplate.composite;
    }
    if (taxBreakdown.gstMode == 'UNREGISTERED') {
      return InvoicePdfTemplate.nonGst;
    }
    if (taxBreakdown.igstAmount > 0) {
      return InvoicePdfTemplate.igst;
    }
    return InvoicePdfTemplate.cgstSgst;
  }

  static String templateLabel(InvoicePdfTemplate template) {
    switch (template) {
      case InvoicePdfTemplate.igst:
        return 'IGST Invoice';
      case InvoicePdfTemplate.cgstSgst:
        return 'CGST/SGST Invoice';
      case InvoicePdfTemplate.nonGst:
        return 'Non-GST Invoice';
      case InvoicePdfTemplate.composite:
        return 'Composite GST Invoice';
    }
  }

  static Future<GeneratedInvoicePdf> generateApprovedInvoicePdf({
    required String approvalId,
    required String invoiceNumber,
  }) async {
    final approval = await _fetchApproval(approvalId);
    final template = resolveTemplate(approval.proposedTaxBreakdown);
    final shop = await _fetchShop(approval.shopId);
    final customer = approval.customerId == null
        ? null
        : await _fetchCustomer(approval.customerId!);
    final itemNames = await _fetchProductNames(approval.proposedItems);
    final approvedAt = approval.reviewedAt ?? DateTime.now();
    final theme = await _loadTheme();

    final document = pw.Document(theme: theme);
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          _buildInvoicePage(
            approval: approval,
            shopName: shop['name'] as String? ?? 'Dukan Sathi',
            shopState: shop['state'] as String? ?? '-',
            gstNumber: shop['gst_registration_number'] as String?,
            businessType: shop['business_type'] as String? ?? 'Retail',
            customerName: customer?['name'] as String? ?? 'Walk-in Customer',
            customerPhone: customer?['phone'] as String?,
            invoiceNumber: invoiceNumber,
            approvedAt: approvedAt,
            itemNames: itemNames,
            template: template,
          ),
        ],
      ),
    );

    final bytes = await document.save();
    final safeInvoiceNumber = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final tempDir = await Directory.systemTemp.createTemp('dukansathi_invoice_');
    final file = File('${tempDir.path}/$safeInvoiceNumber.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return GeneratedInvoicePdf(
      file: file,
      caption: _buildCaption(
        invoiceNumber: invoiceNumber,
        approval: approval,
        template: template,
      ),
      template: template,
    );
  }

  static Future<DraftApproval> _fetchApproval(String approvalId) async {
    final approvalRows = await supabase
        .from('draft_approvals')
        .select()
        .eq('approval_id', approvalId)
        .single();
    return DraftApproval.fromJson(Map<String, dynamic>.from(approvalRows as Map));
  }

  static Future<Map<String, dynamic>> _fetchShop(String shopId) async {
    final shopRows = await supabase
        .from('shops')
        .select('id, name, state, gst_registration_number, gst_mode, business_type, created_at')
        .eq('id', shopId)
        .single();
    return Map<String, dynamic>.from(shopRows as Map);
  }

  static Future<Map<String, dynamic>?> _fetchCustomer(String customerId) async {
    try {
      final customerRows = await supabase
          .from('customers')
          .select('id, shop_id, name, phone, current_balance')
          .eq('id', customerId)
          .single();
      return Map<String, dynamic>.from(customerRows as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _fetchProductNames(List<CartItem> items) async {
    final names = <String, String>{};
    for (final item in items) {
      try {
        final productRows = await supabase
            .from('products')
            .select('name')
            .eq('id', item.productId)
            .single();
        names[item.productId] = (productRows as Map)['name'] as String? ?? item.productId;
      } catch (_) {
        names[item.productId] = item.productId;
      }
    }
    return names;
  }

  static pw.Widget _buildInvoicePage({
    required DraftApproval approval,
    required String shopName,
    required String shopState,
    required String? gstNumber,
    required String businessType,
    required String customerName,
    required String? customerPhone,
    required String invoiceNumber,
    required DateTime approvedAt,
    required Map<String, String> itemNames,
    required InvoicePdfTemplate template,
  }) {
    final tax = approval.proposedTaxBreakdown;
    final isIgst = template == InvoicePdfTemplate.igst;
    final isCgstSgst = template == InvoicePdfTemplate.cgstSgst;
    final isNonGst = template == InvoicePdfTemplate.nonGst;
    final title = templateLabel(template);
    final accent = switch (template) {
      InvoicePdfTemplate.igst => PdfColors.indigo800,
      InvoicePdfTemplate.cgstSgst => PdfColors.teal800,
      InvoicePdfTemplate.nonGst => PdfColors.brown800,
      InvoicePdfTemplate.composite => PdfColors.orange800,
    };

    final itemRows = approval.proposedItems.map((item) {
      final itemName = itemNames[item.productId] ?? item.productId;
      final amount = item.quantity * item.unitPrice;
      return [
        itemName,
        item.productId,
        item.quantity.toString(),
        _money(item.unitPrice),
        _money(amount),
      ];
    }).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$businessType business • State: $shopState',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                      ),
                      if (gstNumber != null && gstNumber.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GSTIN: $gstNumber',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Invoice: $invoiceNumber',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                    pw.Text(
                      'Approved: ${_formatDateTime(approvedAt)}',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _infoGrid(
            title: 'Customer Details',
            rows: [
              ['Customer', customerName],
              ['Phone', customerPhone ?? '-'],
              ['Approval ID', approval.approvalId],
              ['Sale ID', approval.saleId ?? '-'],
            ],
            accent: accent,
          ),
          pw.SizedBox(height: 12),
          _infoGrid(
            title: 'Invoice Summary',
            rows: [
              ['Subtotal', _money(tax.subtotal)],
              if (isIgst) ['IGST', _money(tax.igstAmount)],
              if (isCgstSgst) ['CGST', _money(tax.cgstAmount)],
              if (isCgstSgst) ['SGST', _money(tax.sgstAmount)],
              if (isNonGst) ['GST', 'Not applicable'],
              if (template == InvoicePdfTemplate.composite) ['Composite GST', _money(approval.proposedTotal - tax.subtotal)],
              ['Total', _money(tax.totalAmount)],
            ],
            accent: accent,
            highlightLastRow: true,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Itemized Details',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: accent),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(0.8),
              3: pw.FlexColumnWidth(1.0),
              4: pw.FlexColumnWidth(1.0),
            },
            headers: const ['Item', 'Product ID', 'Qty', 'Rate', 'Amount'],
            data: itemRows,
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tax Mode',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(_taxSummaryText(tax, template)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'This invoice was generated automatically after approval and matches the saved draft invoice record.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoGrid({
    required String title,
    required List<List<String>> rows,
    required PdfColor accent,
    bool highlightLastRow = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isLast = highlightLastRow && index == rows.length - 1;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      row.first,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isLast ? accent : PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row.last,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: isLast ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: isLast ? accent : PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _taxSummaryText(TaxBreakdown tax, InvoicePdfTemplate template) {
    switch (template) {
      case InvoicePdfTemplate.igst:
        return 'Inter-state sale: IGST is applied at the saved tax rate.\nSubtotal: ${_money(tax.subtotal)}\nIGST: ${_money(tax.igstAmount)}\nGrand Total: ${_money(tax.totalAmount)}';
      case InvoicePdfTemplate.cgstSgst:
        return 'Intra-state sale: CGST and SGST are applied separately.\nSubtotal: ${_money(tax.subtotal)}\nCGST: ${_money(tax.cgstAmount)}\nSGST: ${_money(tax.sgstAmount)}\nGrand Total: ${_money(tax.totalAmount)}';
      case InvoicePdfTemplate.nonGst:
        return 'GST is not applicable for this saved invoice.\nSubtotal: ${_money(tax.subtotal)}\nGrand Total: ${_money(tax.totalAmount)}';
      case InvoicePdfTemplate.composite:
        return 'Composite GST invoice.\nSubtotal: ${_money(tax.subtotal)}\nComposite GST: ${_money(tax.totalAmount - tax.subtotal)}\nGrand Total: ${_money(tax.totalAmount)}';
    }
  }

  static String _buildCaption({
    required String invoiceNumber,
    required DraftApproval approval,
    required InvoicePdfTemplate template,
  }) {
    return [
      'Invoice $invoiceNumber finalized',
      'Approval ID: ${approval.approvalId}',
      'Template: ${templateLabel(template)}',
      'Total: ${_money(approval.proposedTotal)}',
    ].join('\n');
  }

  static Future<pw.ThemeData> _loadTheme() async {
    for (final fontPath in _fontCandidates) {
      final file = File(fontPath);
      if (await file.exists()) {
        final regular = pw.Font.ttf(ByteData.sublistView(await file.readAsBytes()));
        return pw.ThemeData.withFont(
          base: regular,
          bold: regular,
          italic: regular,
          boldItalic: regular,
        );
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  static String _money(num value) => '₹${value.toDouble().toStringAsFixed(2)}';
}