import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/session.dart';

class InvoiceDraftCard extends StatefulWidget {
  final Map<String, dynamic>? payload;
  const InvoiceDraftCard({super.key, this.payload});

  @override
  State<InvoiceDraftCard> createState() => _InvoiceDraftCardState();
}

class _InvoiceDraftCardState extends State<InvoiceDraftCard> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;
  bool _isApproving = false;
  bool _showAdvanced = false;

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final FocusNode _paidAmountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _data = widget.payload ?? {};
    _discountController.text = (_data['discount_value'] ?? _data['discountValue'] ?? _data['discount']?['discountValue'] ?? 0).toString();
    _paidAmountController.text = (_data['amount_paid'] ?? _data['amountPaid'] ?? _data['payment']?['amountPaid'] ?? 0).toString();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidAmountController.dispose();
    _paidAmountFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InvoiceDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload && widget.payload != null) {
      setState(() {
        _data = widget.payload!;
        _discountController.text = (_data['discount_value'] ?? _data['discountValue'] ?? _data['discount']?['discountValue'] ?? 0).toString();
        _paidAmountController.text = (_data['amount_paid'] ?? _data['amountPaid'] ?? _data['payment']?['amountPaid'] ?? 0).toString();
      });
    }
  }

  String get _approvalId => (_data['approval_id'] ?? _data['approvalId'] ?? '').toString();

  Future<void> _updateDraft(String type, Map<String, dynamic> extra) async {
    final aid = _approvalId;
    if (aid.isEmpty) {
      debugPrint("Warning: approvalId is empty in _data: $_data");
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/update-draft'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'approvalId': aid,
          'type': type,
          ...extra,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh draft data
        final refreshResp = await http.get(
          Uri.parse('http://localhost:3100/api/get-draft?approvalId=$aid'),
        );
        if (refreshResp.statusCode == 200) {
          setState(() {
            _data = jsonDecode(refreshResp.body);
            _discountController.text = (_data['discount_value'] ?? 0).toString();
            _paidAmountController.text = (_data['amount_paid'] ?? 0).toString();
            if (type == 'payment' && (_data['payment_status'] ?? _data['paymentStatus']) == 'PARTIAL') {
              _paidAmountFocusNode.requestFocus();
            }
          });
        }
      } else {
        final errorMsg = response.body;
        throw Exception("Server Error ($type): $errorMsg");
      }
    } catch (e) {
      debugPrint("Error in _updateDraft: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${e.toString()}"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDraft() async {
    setState(() => _isApproving = true);
    try {
      final userId = UserSession().userId;
      final aid = _approvalId;
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/approve-draft'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'approvalId': aid,
          'userId': userId,
        }),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Invoice Approved!"),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _data['approval_status'] = 'APPROVED';
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? "Approval failed"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Approve error: $e");
    } finally {
      setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      return const _StaticPlaceholder();
    }

    final isApproved = _data['approval_status'] == 'APPROVED';
    final items = (_data['proposed_items'] ?? _data['items']) as List<dynamic>? ?? [];
    final tax = _data['proposed_tax_breakdown'] ?? _data['taxBreakdown'] ?? {};
    final customerName = (_data['customer_name'] ?? _data['customerName'])?.toString() ?? "Walk-in Customer";
    final totalAmount = (tax['total_amount'] ?? tax['totalAmount'] ?? 0.0).toDouble();
    final gstType = _data['gst_type'] ?? _data['gstType'] ?? 'CGST_SGST';
    final paymentStatus = _data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID';
    final discAmt = (_data['discount_amount'] ?? _data['discountAmount'] ?? _data['discount']?['discountAmount'] ?? 0.0).toDouble();

    return GlassBox(
      blur: 25,
      opacity: 0.15,
      border: Border.all(
        color: isApproved ? AppColors.success.withOpacity(0.4) : AppColors.primary.withOpacity(0.3),
        width: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isApproved ? Iconsax.tick_circle : Iconsax.edit,
                      color: isApproved ? AppColors.success : AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isApproved ? "Approved Invoice" : "Draft Invoice",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isApproved ? AppColors.success : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkGlass,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    customerName,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.darkGlassBorder, height: 24),
            
            // Item List
            ...items.map((item) {
              final name = item['name']?.toString() ?? "Item";
              final qty = item['quantity']?.toString() ?? "1";
              final price = item['unitPrice']?.toString() ?? "0";
              final total = (item['quantity'] * item['unitPrice']).toStringAsFixed(2);
              return _buildLineItem(name, "$qty x ₹$price", "₹$total");
            }),
            
            const SizedBox(height: 16),
            
            // Tax Breakdown Tray
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTaxLine("Subtotal", "₹${(tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                      if ((tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0) > 0)
                        _buildTaxLine("CGST", "₹${(tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                      if ((tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0) > 0)
                        _buildTaxLine("SGST", "₹${(tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                      if ((tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0) > 0)
                        _buildTaxLine("IGST", "₹${(tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                      if (discAmt > 0)
                        _buildTaxLine("Discount", "-₹${discAmt.toStringAsFixed(2)}", color: AppColors.error),
                    ],
                  ),
                  if (_isLoading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
            
            if (!isApproved) ...[
              const SizedBox(height: 12),
              // Advanced Toggle
              GestureDetector(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Row(
                  children: [
                    Text(
                      _showAdvanced ? "Hide Controls" : "Edit Draft (GST, Discount, Payment)",
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Icon(_showAdvanced ? Iconsax.arrow_up_1 : Iconsax.arrow_down_1, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
              if (_showAdvanced)
                _buildAdvancedControls(gstType, paymentStatus).animate().fadeIn().slideY(begin: -0.1),
            ],

            const SizedBox(height: 16),
            
            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  "₹${totalAmount.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: isApproved ? AppColors.success : AppColors.success,
                    shadows: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            if (!isApproved)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isApproving ? null : _approveDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isApproving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.tick_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Approve & Print", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.darkGlassBorder),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.trash, color: AppColors.error),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () {
                  final aid = _approvalId;
                  html.window.open('http://localhost:3100/api/download-invoice?approvalId=$aid', '_blank');
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.document_download, color: AppColors.success, size: 20),
                        SizedBox(width: 10),
                        Text("Download Invoice PDF", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ).animate().shimmer(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAdvancedControls(String currentGst, String paymentStatus) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          // GST Switcher
          Row(
            children: [
              const Text("GST Type:", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              _buildSmallToggle(
                "Intra-state (CGST+SGST)",
                currentGst == 'CGST_SGST',
                () => _updateDraft('gst', {'gstType': 'CGST_SGST'}),
              ),
              const SizedBox(width: 8),
              _buildSmallToggle(
                "Inter-state (IGST)",
                currentGst == 'IGST',
                () => _updateDraft('gst', {'gstType': 'IGST'}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment Status
          Row(
            children: [
              const Text("Payment:", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              _buildSmallToggle("Unpaid", paymentStatus == 'UNPAID', () => _updateDraft('payment', {'paymentStatus': 'UNPAID'})),
              const SizedBox(width: 4),
              _buildSmallToggle("Partial", paymentStatus == 'PARTIAL', () => _updateDraft('payment', {'paymentStatus': 'PARTIAL'})),
              const SizedBox(width: 4),
              _buildSmallToggle("Paid", paymentStatus == 'PAID', () => _updateDraft('payment', {'paymentStatus': 'PAID'})),
            ],
          ),
          if (paymentStatus == 'PARTIAL') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Amount Paid:", style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    focusNode: _paidAmountFocusNode,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDecoration("₹ 0.00"),
                    onSubmitted: (val) => _updateDraft('payment', {
                      'paymentStatus': 'PARTIAL',
                      'amountPaid': double.tryParse(val) ?? 0,
                    }),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Discount
          Row(
            children: [
              const Text("Discount:", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration("e.g. 10% or 50"),
                  onSubmitted: (val) {
                    final isPercent = val.contains('%');
                    final value = double.tryParse(val.replaceAll('%', '')) ?? 0;
                    _updateDraft('discount', {
                      'discountType': isPercent ? 'PERCENT' : 'AMOUNT',
                      'discountValue': value,
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  Widget _buildSmallToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: active ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.primary : Colors.white10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : Colors.white54,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(String name, String qtyPrice, String total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(qtyPrice, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(total, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaxLine(String label, String amount, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(amount, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StaticPlaceholder extends StatelessWidget {
  const _StaticPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Preparing Draft...", style: TextStyle(color: Colors.white54)));
  }
}
