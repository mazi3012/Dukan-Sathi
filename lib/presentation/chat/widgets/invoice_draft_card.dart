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
        headers: {
          'Content-Type': 'application/json',
        },
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
  void _showEditItemDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController(text: item['quantity']?.toString());
    final priceCtrl = TextEditingController(text: item['unitPrice']?.toString());
    final name = item['productName']?.toString() ?? item['name']?.toString() ?? "Item";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBackground,
          title: Text("Edit $name", style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.darkGlassBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.darkGlassBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = int.tryParse(qtyCtrl.text.trim());
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (newQty != null && newQty > 0) {
                  Navigator.pop(context);
                  _updateDraft('edit_item', {
                    'productId': item['productId'],
                    'quantity': newQty,
                    'unitPrice': newPrice,
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
  Future<void> _approveDraft() async {
    // Block approval if PARTIAL with no amount paid entered
    final currentPaymentStatus = (_data['payment_status'] ?? _data['paymentStatus'] ?? 'UNPAID').toString();
    final currentAmountPaid = (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0);
    final amountPaidVal = (currentAmountPaid is num) ? currentAmountPaid.toDouble() : 0.0;
    if (currentPaymentStatus == 'PARTIAL' && amountPaidVal <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter the paid amount before approving a partial payment invoice."),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _isApproving = true);
    try {
      final userId = UserSession().userId;
      final aid = _approvalId;
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/approve-draft'),
        headers: {
          'Content-Type': 'application/json',
        },
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
            
            // Item List — Indian GST style with per-item tax detail
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final name = item['productName']?.toString() ?? item['name']?.toString() ?? "Item";
              final qty = (item['quantity'] as num).toInt();
              final unitPrice = (item['unitPrice'] as num).toDouble();
              final gstRate = (item['gstRate'] as num?)?.toDouble() ?? 18.0;
              final taxableValue = qty * unitPrice;
              final taxAmount = taxableValue * (gstRate / 100);
              final totalWithTax = taxableValue + taxAmount;
              final gstRateStr = gstRate == gstRate.roundToDouble() ? '${gstRate.toInt()}%' : '${gstRate.toStringAsFixed(1)}%';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name + Edit + Total
                    Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$idx', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        if (!isApproved)
                          GestureDetector(
                            onTap: () => _showEditItemDialog(Map<String, dynamic>.from(item)),
                            child: const Icon(Iconsax.edit, size: 14, color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Row 2: Qty × Rate = Taxable | GST% | Tax Amt
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$qty × ₹${unitPrice.toStringAsFixed(2)} = ₹${taxableValue.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('GST $gstRateStr', style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+₹${taxAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.amber.shade300, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    // Row 3: Total including tax
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Total: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text(
                          '₹${totalWithTax.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              );
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
                      // Show Items Total → Discount → Taxable Value when discount is applied
                      if (discAmt > 0) ...[
                        _buildTaxLine("Items Total", "₹${(_data['subtotal_before_discount'] ?? _data['subtotalBeforeDiscount'] ?? tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                        () {
                          final discType = (_data['discount_type'] ?? _data['discountType'])?.toString();
                          final discVal = (_data['discount_value'] ?? _data['discountValue'] ?? 0.0);
                          final discValNum = (discVal is num) ? discVal.toDouble() : 0.0;
                          final label = discType == 'PERCENT' ? "Discount (${discValNum.toStringAsFixed(1)}%)" : "Discount";
                          return _buildTaxLine(label, "-₹${discAmt.toStringAsFixed(2)}", color: AppColors.success);
                        }(),
                        _buildTaxLine("Taxable Value", "₹${(_data['subtotal_after_discount'] ?? _data['subtotalAfterDiscount'] ?? tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                      ] else
                        _buildTaxLine("Subtotal", "₹${(tax['subtotal'] ?? 0.0).toStringAsFixed(2)}"),
                      if (tax['rate_wise_summary'] != null && (tax['rate_wise_summary'] as List).isNotEmpty)
                        ...(tax['rate_wise_summary'] as List).map((entry) {
                          final rate = (entry['rate'] as num).toDouble();
                          if (rate <= 0) return const SizedBox.shrink();
                          final isIGST = gstType == 'IGST';
                          if (isIGST) {
                            final igst = (entry['igst'] as num).toDouble();
                            return _buildTaxLine("IGST (${rate == rate.roundToDouble() ? rate.toInt() : rate.toStringAsFixed(1)}%)", "₹${igst.toStringAsFixed(2)}");
                          } else {
                            final cgst = (entry['cgst'] as num).toDouble();
                            final sgst = (entry['sgst'] as num).toDouble();
                            final halfRate = rate / 2;
                            final halfRateStr = halfRate == halfRate.roundToDouble() ? halfRate.toInt() : halfRate.toStringAsFixed(1);
                            return Column(
                              children: [
                                _buildTaxLine("CGST ($halfRateStr%)", "₹${cgst.toStringAsFixed(2)}"),
                                _buildTaxLine("SGST ($halfRateStr%)", "₹${sgst.toStringAsFixed(2)}"),
                              ],
                            );
                          }
                        })
                      else ...[
                        if ((tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0) > 0)
                          _buildTaxLine("CGST", "₹${(tax['cgst_amount'] ?? tax['cgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                        if ((tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0) > 0)
                          _buildTaxLine("SGST", "₹${(tax['sgst_amount'] ?? tax['sgstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                        if ((tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0) > 0)
                          _buildTaxLine("IGST", "₹${(tax['igst_amount'] ?? tax['igstAmount'] ?? 0.0).toStringAsFixed(2)}"),
                      ],
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

            // Payment Summary (Paid / Due)
            if (paymentStatus == 'PARTIAL' || paymentStatus == 'UNPAID') ...[
              const SizedBox(height: 8),
              () {
                final amtPaid = (_data['amount_paid'] ?? _data['amountPaid'] ?? 0.0);
                final paidVal = (amtPaid is num) ? amtPaid.toDouble() : 0.0;
                final dueVal = totalAmount - paidVal;
                return Column(
                  children: [
                    if (paymentStatus == 'PARTIAL' && paidVal > 0)
                      _buildTaxLine("Amount Paid", "₹${paidVal.toStringAsFixed(2)}", color: AppColors.success),
                    _buildTaxLine(
                      "Balance Due",
                      "₹${dueVal.toStringAsFixed(2)}",
                      color: AppColors.error,
                    ),
                  ],
                );
              }(),
            ] else if (paymentStatus == 'PAID') ...[
              const SizedBox(height: 8),
              _buildTaxLine("Fully Paid", "₹${totalAmount.toStringAsFixed(2)}", color: AppColors.success),
            ],
            
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final val = _paidAmountController.text.trim();
                    final amount = double.tryParse(val) ?? 0;
                    if (amount > 0) {
                      _updateDraft('payment', {
                        'paymentStatus': 'PARTIAL',
                        'amountPaid': amount,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Enter a valid amount greater than 0"),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Text("Save", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    final value = double.tryParse(val.replaceAll('%', '').trim()) ?? 0;
                    _updateDraft('discount', {
                      'discountType': isPercent ? 'PERCENT' : 'AMOUNT',
                      'discountValue': value,
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final val = _discountController.text.trim();
                  if (val.isEmpty) return;
                  final isPercent = val.contains('%');
                  final value = double.tryParse(val.replaceAll('%', '').trim()) ?? 0;
                  if (value > 0) {
                    _updateDraft('discount', {
                      'discountType': isPercent ? 'PERCENT' : 'AMOUNT',
                      'discountValue': value,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter a valid discount value (e.g. 10% or 50)"),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Text("Apply", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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
  Widget _buildLineItem(String name, String qtyPrice, String total, {VoidCallback? onEdit}) {
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
          if (onEdit != null) ...[
            Text(total, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Iconsax.edit, size: 16, color: AppColors.primary),
            ),
          ] else
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
