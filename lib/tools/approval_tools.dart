import 'package:uuid/uuid.dart';
import '../core/database.dart';
import '../models/cart_item.dart';
import '../services/gst_calculator.dart';
import '../models/shop_config.dart';

/// Approve a pending draft invoice and create Sale + DraftInvoice records
Future<Map<String, dynamic>> approveDraftInvoice({
  required String approvalId,
  required String reviewedBy,
}) async {
  try {
    // Fetch the pending draft approval
    final approvalRows = await supabase
        .from('draft_approvals')
        .select()
        .eq('approval_id', approvalId)
        .eq('approval_status', 'PENDING')
        .single();

    final approvalData = Map<String, dynamic>.from(approvalRows as Map);

    final shopId = approvalData['shop_id'] as String;
    final customerId = approvalData['customer_id'] as String?;
    final proposedItems = approvalData['proposed_items'] as List;
    final proposedTotal = approvalData['proposed_total'] as num;
    final taxBreakdown = approvalData['proposed_tax_breakdown'] as Map<String, dynamic>;

    final items = (proposedItems as List).map((itemJson) {
      final json = Map<String, dynamic>.from(itemJson as Map);
      return CartItem(
        productId: json['productId'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );
    }).toList();

    // Create draft_invoices record
    final draftInvoiceResponse = await supabase
        .from('draft_invoices')
        .insert({
          'shop_id': shopId,
          'customer_id': customerId,
          'items': items.map((item) => item.toJson()).toList(),
          'total_amount': proposedTotal,
          'tax_breakdown': taxBreakdown,
          'status': 'approved',
          'draft_approval_id': approvalId,
        })
        .select('id')
        .single();

    final draftInvoiceId = draftInvoiceResponse['id'] as String;

    // Create Sale record with UUID id and human-readable invoice number
    final saleId = const Uuid().v4();
    final invoiceNumber = 'INV-${approvalId.substring(0, 13).replaceAll('-', '').toUpperCase()}';
    await supabase.from('sales').insert({
      'id': saleId,
      'invoice_number': invoiceNumber,
      'shop_id': shopId,
      'invoice_id': draftInvoiceId,
      'customer_id': customerId,
      'amount': proposedTotal,
      'timestamp': DateTime.now().toIso8601String(),
      'payment_method': 'pending',
      'status': 'approved',
    });

    // Update draft_approval status
    await supabase
        .from('draft_approvals')
        .update({
          'approval_status': 'APPROVED',
          'reviewed_by': reviewedBy,
          'reviewed_at': DateTime.now().toIso8601String(),
          'draft_invoice_id': draftInvoiceId,
          'sale_id': saleId,
        })
        .eq('approval_id', approvalId);

    return {
      'success': true,
      'approvalId': approvalId,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'draftInvoiceId': draftInvoiceId,
      'totalAmount': proposedTotal,
      'message': '✅ *Invoice Approved!*\n\n🧾 `$invoiceNumber`\n💰 Total: ₹${proposedTotal.toStringAsFixed(2)}\n\n_Saved to records._',
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Failed to approve draft: $e',
    };
  }
}

/// Reject a pending draft invoice (no Sale created)
Future<Map<String, dynamic>> rejectDraftInvoice({
  required String approvalId,
  required String reviewedBy,
  required String rejectionReason,
}) async {
  try {
    await supabase
        .from('draft_approvals')
        .update({
          'approval_status': 'REJECTED',
          'reviewed_by': reviewedBy,
          'reviewed_at': DateTime.now().toIso8601String(),
          'approval_notes': rejectionReason,
        })
        .eq('approval_id', approvalId);

    return {
      'success': true,
      'approvalId': approvalId,
      'message': '❌ *Invoice Rejected*\n\nReason: $rejectionReason\n\n_The draft has been discarded._',
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Failed to reject draft: $e',
    };
  }
}

/// Switch an existing PENDING draft between CGST/SGST and IGST
Future<Map<String, dynamic>> switchGstType({
  required String approvalId,
  required String newGstType, // 'IGST' or 'CGST_SGST'
}) async {
  try {
    final approvalRows = await supabase
        .from('draft_approvals')
        .select()
        .eq('approval_id', approvalId)
        .eq('approval_status', 'PENDING')
        .single();

    final approvalData = Map<String, dynamic>.from(approvalRows as Map);
    final shopId = approvalData['shop_id'] as String;
    final proposedItems = (approvalData['proposed_items'] as List).map((itemJson) {
      final json = Map<String, dynamic>.from(itemJson as Map);
      return CartItem(
        productId: json['productId'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );
    }).toList();

    // Fetch shop config
    final shopRows = await supabase
        .from('shops')
        .select('id, state, gst_registration_number, gst_mode, business_type, created_at')
        .eq('id', shopId)
        .single();
    final shopData = Map<String, dynamic>.from(shopRows as Map);
    final shopState = shopData['state'] as String;

    // Recalculate tax for IGST (inter-state) or CGST+SGST (intra-state)
    final isInterState = newGstType == 'IGST';
    // Build a fake "other state" to trigger inter-state calc
    final customerState = isInterState ? 'DL' : shopState;

    final shopConfig = ShopConfig(
      shopId: shopId,
      state: shopState,
      gstRegistrationNumber: shopData['gst_registration_number'] as String?,
      gstMode: GSTMode.registered,
      businessType: shopData['business_type'] as String? ?? 'Retail',
      createdAt: DateTime.parse(shopData['created_at'] as String),
    );

    final newTaxBreakdown = GSTCalculator.calculateTax(
      items: proposedItems,
      shopConfig: shopConfig,
      customerState: customerState,
    );

    await supabase.from('draft_approvals').update({
      'proposed_tax_breakdown': {
        'subtotal': newTaxBreakdown.subtotal,
        'cgst_amount': newTaxBreakdown.cgstAmount,
        'sgst_amount': newTaxBreakdown.sgstAmount,
        'igst_amount': newTaxBreakdown.igstAmount,
        'gst_mode': newTaxBreakdown.gstMode,
        'applicable_state': newTaxBreakdown.applicableState,
        'tax_slab': newTaxBreakdown.taxSlab,
        'total_amount': newTaxBreakdown.totalAmount,
        'breakdown': newTaxBreakdown.breakdown,
      },
      'proposed_total': newTaxBreakdown.totalAmount,
      'gst_type': newGstType,
    }).eq('approval_id', approvalId);

    return {
      'success': true,
      'newGstType': newGstType,
      'taxBreakdown': newTaxBreakdown,
    };
  } catch (e) {
    return {'success': false, 'error': 'Failed to switch GST type: $e'};
  }
}

/// Get approval details for display
Future<Map<String, dynamic>?> getApprovalDetails(String approvalId) async {
  try {
    final result = await supabase
        .from('draft_approvals')
        .select()
        .eq('approval_id', approvalId)
        .single();
    return Map<String, dynamic>.from(result as Map);
  } catch (e) {
    return null;
  }
}
