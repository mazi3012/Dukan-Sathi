import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../models/customer.dart';
import '../providers/customers_provider.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/local/local_database.dart';
import '../../../core/services/connectivity_service.dart';

class CustomerDetailsPage extends ConsumerStatefulWidget {
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
  ConsumerState<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends ConsumerState<CustomerDetailsPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _currentBalance = 0;
  bool _isSettling = false;
  String _customerName = '';
  String _customerPhone = '';

  @override
  void initState() {
    super.initState();
    _customerName = widget.customer['name'] ?? 'Unknown';
    _customerPhone = widget.customer['phone'] ?? '';
    _currentBalance = (widget.customer['current_balance'] as num?)?.toDouble() ?? 0;
    _fetchTransactions();
  }

  @override
  void didUpdateWidget(covariant CustomerDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer['id'] != widget.customer['id']) {
      _customerName = widget.customer['name'] ?? 'Unknown';
      _customerPhone = widget.customer['phone'] ?? '';
      _currentBalance = (widget.customer['current_balance'] as num?)?.toDouble() ?? 0;
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch from local database first (instant offline access)
      final localSales = await LocalDatabase.instance.queryAll(
        'sales',
        where: 'customer_id = ?',
        whereArgs: [widget.customer['id']],
        orderBy: 'timestamp DESC',
      );
      
      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(localSales);
        });
      }

      // 2. If online, fetch fresh data from cloud and update local cache
      if (ConnectivityService.instance.isOnline) {
        final cloudSales = await supabase
            .from('sales')
            .select('id, amount, amount_paid, payment_status, timestamp, invoice_number')
            .eq('customer_id', widget.customer['id'])
            .order('timestamp', ascending: false);

        // Keep local cache updated for these specific records to ensure accuracy
        for (var row in cloudSales) {
          final saleMap = Map<String, dynamic>.from(row as Map);
          await LocalDatabase.instance.insert(
            'sales',
            saleMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        if (mounted) {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(cloudSales);
          });
        }
      }
    } catch (e) {
      debugPrint('[CustomerDetails] Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      final finalBalance = newBalance < 0 ? 0.0 : newBalance;
      
      // 1. Update customer balance using CustomerRepository (handles local cache + sync manager + web fast path)
      final customerData = Customer(
        id: widget.customer['id'],
        shopId: widget.customer['shop_id'] ?? UserSession().shopId ?? '',
        name: _customerName,
        phone: _customerPhone,
        currentBalance: finalBalance,
      );
      await CustomerRepository().updateCustomer(customerData);

      // 2. Create payment transaction record using SaleRepository (handles local cache + sync manager + web fast path)
      final newSaleId = const Uuid().v4();
      final saleRecord = {
        'id': newSaleId,
        'shop_id': widget.customer['shop_id'] ?? UserSession().shopId ?? '',
        'invoice_id': newSaleId,
        'invoice_number': 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'customer_id': widget.customer['id'],
        'customer_name': widget.customer['name'],
        'amount': 0.0, // Payment, not a sale
        'amount_paid': amount,
        'due_amount': 0.0, // Handled atomically by finalBalance update
        'payment_status': 'PAID',
        'discount_amount': 0.0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'payment_method': 'cash',
        'status': 'approved',
      };
      
      await SaleRepository().saveSale(saleRecord);

      setState(() => _currentBalance = finalBalance);
      _fetchTransactions(); // refresh timeline

      // Update customers provider to ensure parent pages reflect the updated balances immediately
      ref.read(customersProvider.notifier).fetchCustomers();

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
    final name = _customerName;
    final phone = _customerPhone;
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
          const Spacer(),
          IconButton(
            icon: const Icon(Iconsax.edit, color: AppColors.primary),
            onPressed: _showEditForm,
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, color: AppColors.error),
            onPressed: _confirmDelete,
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

  void _showEditForm() {
    final nameController = TextEditingController(text: _customerName);
    final phoneController = TextEditingController(text: _customerPhone);
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
            border: Border.all(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Customer Details",
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightOnSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Customer Name *", style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GlassBox(
                child: TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
                  decoration: InputDecoration(
                    hintText: "Enter full name",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Phone Number *", style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GlassBox(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
                  decoration: InputDecoration(
                    hintText: "Enter 10-digit number",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
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
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all required fields"), backgroundColor: AppColors.warning),
                      );
                      return;
                    }
                    Navigator.pop(context);

                    final shopId = UserSession().shopId ?? '';
                    final newCustomer = Customer(
                      id: widget.customer['id'],
                      shopId: shopId,
                      name: name,
                      phone: phone,
                      currentBalance: _currentBalance,
                    );

                    await ref.read(customersProvider.notifier).updateCustomer(newCustomer);
                    setState(() {
                      _customerName = name;
                      _customerPhone = phone;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Customer details updated successfully!"), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final hasDues = _currentBalance > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        bool isConfirmed = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Permanently Delete?",
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDues
                        ? "Warning: This customer has outstanding dues of ₹${_currentBalance.toStringAsFixed(2)}. Deleting this customer will remove their profile and all active dues from your ledger forever."
                        : "Are you sure you want to delete ${_customerName}? This action cannot be undone and all data will be permanently removed.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isConfirmed = !isConfirmed;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isConfirmed,
                            activeColor: AppColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setDialogState(() {
                                isConfirmed = val ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "I confirm I want to permanently delete this customer.",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () async {
                          Navigator.pop(context); // close dialog
                          final id = widget.customer['id'];
                          
                          // Clear selection in provider first (important for desktop layout)
                          ref.read(customersProvider.notifier).selectCustomer(null);
                          
                          await ref.read(customersProvider.notifier).deleteCustomer(id);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Customer deleted successfully"),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            if (!widget.isEmbedded) {
                              Navigator.pop(context); // close profile page
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: isDark 
                        ? Colors.white.withOpacity(0.06) 
                        : Colors.black.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    "Permanently Delete",
                    style: TextStyle(
                      color: isConfirmed 
                          ? Colors.white 
                          : (isDark ? Colors.white30 : Colors.black30),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
