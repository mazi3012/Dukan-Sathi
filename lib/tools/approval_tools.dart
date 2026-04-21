import '../core/database.dart';
import '../models/cart_item.dart';
import '../models/draft_approval.dart';
import '../models/draft_invoice.dart';
import '../services/gst_calculator.dart';

/// Approve a pending draft invoice and create Sale record
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

    // Extract data
    final shopId = approvalData['shop_id'] as String;
    final customerId = approvalData['customer_id'] as String?;
    final proposedItems = approvalData['proposed_items'] as List;
    final proposedTotal = approvalData['proposed_total'] as num;
    final taxBreakdown =
        approvalData['proposed_tax_breakdown'] as Map<String, dynamic>;

    // Create CartItems from proposed items
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
        })
        .select('id')
        .single();

    final draftInvoiceId = draftInvoiceResponse['id'] as String;

    // Create Sale record with timestamp-based ID
    final saleId = DateTime.now().millisecondsSinceEpoch.toString();
    await supabase.from('sales').insert({
      'id': saleId,
      'shop_id': shopId,
      'invoice_id': draftInvoiceId,
      'customer_id': customerId,
      'amount': proposedTotal,
      'timestamp': DateTime.now().toIso8601String(),
      'payment_method': 'pending',
      'status': 'approved',
    }).select();

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
        .eq('approval_id', approvalId)
        .select();

    return {
      'success': true,
      'approvalId': approvalId,
      'saleId': saleId,
      'draftInvoiceId': draftInvoiceId,
      'message': '✅ Invoice finalized successfully',
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
        .eq('approval_id', approvalId)
        .select();

    return {
      'success': true,
      'approvalId': approvalId,
      'message': '❌ Draft invoice rejected',
      'reason': rejectionReason,
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Failed to reject draft: $e',
    };
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

/// List all pending approvals for a shop
Future<List<Map<String, dynamic>>> getPendingApprovalsForShop(
    String shopId) async {
  try {
    final result = await supabase
        .from('draft_approvals')
        .select()
        .eq('shop_id', shopId)
        .eq('approval_status', 'PENDING')
        .order('created_at', ascending: false);

    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  } catch (e) {
    return [];
  }
}

/// Count pending approvals for a shop
Future<int> countPendingApprovalsForShop(String shopId) async {
  try {
    final result = await supabase
        .from('draft_approvals')
        .select('id')
        .eq('shop_id', shopId)
        .eq('approval_status', 'PENDING')
        .count();

    return result.count ?? 0;
  } catch (e) {
    return 0;
  }
}
