import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import '../../../core/widgets/responsive_layout.dart';

class CustomerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final bool isEmbedded;
  final VoidCallback? onPaymentProcessed;

  const CustomerDetailsPage({
    super.key, 
    required this.customer, 
    this.isEmbedded = false,
    this.onPaymentProcessed,
  });

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _currentBalance = 0;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _currentBalance = (widget.customer['current_balance'] as num?)?.toDouble() ?? 0;
    _fetchTransactions();
  }

  @override
  void didUpdateWidget(covariant CustomerDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer['id'] != widget.customer['id']) {
      _currentBalance = (widget.customer['current_balance'] as num?)?.toDouble() ?? 0;
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase
          .from('sales')
          .select('id, amount, amount_paid, payment_status, timestamp, invoice_number')
          .eq('customer_id', widget.customer['id'])
          .order('timestamp', ascending: false); // Newest first

      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CustomerDetails] Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening WhatsApp for ${widget.customer['name']}...')),
    );
  }

  void _callCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${widget.customer['phone']}...')),
    );
  }

  void _showSettleDialog() {
    final TextEditingController amountController = TextEditingController(text: _currentBalance.toStringAsFixed(0));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
              left: BorderSide(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
              right: BorderSide(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
            ),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Receive Payment", 
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightOnSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Current Due: ₹${_currentBalance.toStringAsFixed(2)}", 
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),
              GlassBox(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightOnSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: "₹ ",
                    prefixStyle: TextStyle(
                      color: AppColors.primary, 
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      Navigator.pop(context);
                      await _processPayment(amount);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Confirm Payment", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(double amount) async {
    if (_isSettling) return;
    setState(() => _isSettling = true);
    
    try {
      final newBalance = _currentBalance - amount;
      
      // 1. Update customer balance
      await supabase.from('customers').update({
        'current_balance': newBalance < 0 ? 0 : newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.customer['id']);

      // 2. Create dummy sales record for timeline (Payment)
      final newSaleId = const Uuid().v4();
      await supabase.from('sales').insert({
        'id': newSaleId,
        'shop_id': UserSession().shopId,
        'invoice_id': newSaleId,
        'invoice_number': 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'customer_id': widget.customer['id'],
        'customer_name': widget.customer['name'],
        'amount': 0, // Payment, not a sale
        'amount_paid': amount,
        'due_amount': 0,
        'payment_status': 'PAID',
      });

      setState(() => _currentBalance = newBalance < 0 ? 0 : newBalance);
      _fetchTransactions(); // refresh timeline

      if (widget.onPaymentProcessed != null) {
        widget.onPaymentProcessed!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint('[CustomerDetails] Settlement error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customer['name'] ?? 'Unknown';
    final phone = widget.customer['phone'] ?? '';
    final balance = _currentBalance;
    final hasDues = balance > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: widget.isEmbedded 
          ? Colors.transparent 
          : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
      body: Stack(
        children: [
          const SizedBox.expand(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(name),
                _buildProfileHeader(name, phone, balance, hasDues),
                _buildQuickActions(),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withOpacity(0.5)
                          : AppColors.lightSurface.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : _transactions.isEmpty
                            ? _buildEmptyTransactions()
                            : _buildTransactionTimeline(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: hasDues ? _buildBottomSettleBar(balance) : null,
    );
  }

  Widget _buildAppBar(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          if (!widget.isEmbedded) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Iconsax.arrow_left_2, color: Theme.of(context).iconTheme.color),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            "Customer Profile",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String phone, double balance, bool hasDues) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Iconsax.user, size: 40, color: AppColors.primary),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 15),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightOnSurface,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 100.ms),
          Text(
            phone,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          GlassBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasDues ? Iconsax.wallet_minus : Iconsax.verify,
                    color: hasDues ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDues ? "Pending Dues" : "All Clear",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₹${balance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: hasDues ? AppColors.error : AppColors.success,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().slideY(begin: 0.5, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Iconsax.call, "Call", _callCustomer),
          _buildActionButton(Iconsax.message, "WhatsApp", _openWhatsApp, color: Colors.green),
          _buildActionButton(Iconsax.card, "Settle", _showSettleDialog, color: AppColors.primary),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final themeColor = color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.lightOnSurface);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        "No transaction history found.",
        style: TextStyle(
          color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTransactionTimeline() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (tx['amount_paid'] as num?)?.toDouble() ?? 0;
        final isPayment = amountPaid > 0 && amount == 0;
        final status = tx['payment_status'] ?? 'UNPAID';
        final dateStr = tx['timestamp'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        
        Color statusColor;
        IconData statusIcon;
        if (status == 'PAID') {
          statusColor = AppColors.success;
          statusIcon = Iconsax.tick_circle;
        } else if (status == 'PARTIAL') {
          statusColor = Colors.orange;
          statusIcon = Iconsax.clock;
        } else {
          statusColor = AppColors.error;
          statusIcon = Iconsax.close_circle;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, width: 3),
                  ),
                ),
                if (index != _transactions.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: GlassBox(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPayment ? "Payment Received" : "Bill: ${tx['invoice_number'] ?? 'N/A'}",
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightOnSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : "Unknown Date",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isPayment ? "+ ₹${amountPaid.toStringAsFixed(0)}" : "₹${amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: isPayment ? AppColors.success : (isDark ? Colors.white : AppColors.lightOnSurface), 
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildBottomSettleBar(double balance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, isDesktop ? 20 : 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "To Collect", 
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                "₹${balance.toStringAsFixed(0)}", 
                style: const TextStyle(
                  color: AppColors.error, 
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _showSettleDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Receive Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOut);
  }
}
