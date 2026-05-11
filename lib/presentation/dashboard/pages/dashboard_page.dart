import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../chat/pages/ai_chat_page.dart';

import '../../../core/database.dart';
import '../../../core/session.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _totalSales = 0;
  int _invoiceCount = 0;
  double _totalExpenses = 0;
  int _productCount = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final shopId = UserSession().shopId;
    if (shopId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch Total Sales
      final salesRes = await supabase
          .from('sales')
          .select('amount')
          .eq('shop_id', shopId);
      
      double sales = 0;
      for (var row in salesRes) {
        sales += (row['amount'] as num).toDouble();
      }

      // 2. Fetch Invoice Count
      final invoicesRes = await supabase
          .from('sales')
          .select('id')
          .eq('shop_id', shopId);
      final invoiceCount = invoicesRes.length;

      // 3. Fetch Expenses
      final expensesRes = await supabase
          .from('expenses')
          .select('amount')
          .eq('shop_id', shopId);
      
      double expenses = 0;
      for (var row in expensesRes) {
        expenses += (row['amount'] as num).toDouble();
      }

      // 4. Fetch Product Count
      final productsRes = await supabase
          .from('products')
          .select('id')
          .eq('shop_id', shopId);
      final productCount = productsRes.length;

      // 5. Fetch Recent Activity
      final activityRes = await supabase
          .from('sales')
          .select('invoice_number, customer_name, amount, timestamp')
          .eq('shop_id', shopId)
          .order('timestamp', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _totalSales = sales;
          _invoiceCount = invoiceCount;
          _totalExpenses = expenses;
          _productCount = productCount;
          _recentActivity = List<Map<String, dynamic>>.from(activityRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkBackground, Color(0xFF1A1D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWelcomeSection(context),
                      const SizedBox(height: 30),
                      _isLoading 
                        ? _buildStatsSkeleton()
                        : _buildStatsGrid(),
                      const SizedBox(height: 30),
                      _buildSectionTitle(context, "Recent Activity"),
                      const SizedBox(height: 15),
                      _isLoading 
                        ? _buildActivitySkeleton()
                        : _buildActivityList(),
                      const SizedBox(height: 100), // Spacer for bottom bar
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // Don't show back button
      title: Row(
        children: [
          const Icon(Iconsax.shop, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            "DUKAN SATHI",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Open drawer from parent Scaffold
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Iconsax.menu_1, color: Colors.white70),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Iconsax.notification, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back,",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
        ),
        Text(
          UserSession().userName ?? "Shop Owner",
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Sales", "₹${_totalSales.toStringAsFixed(0)}", Iconsax.money_send, AppColors.primary),
        _buildStatCard("Invoices", _invoiceCount.toString(), Iconsax.document_text, AppColors.accent),
        _buildStatCard("Expenses", "₹${_totalExpenses.toStringAsFixed(0)}", Iconsax.money_remove, AppColors.error),
        _buildStatCard("Products", _productCount.toString(), Iconsax.box, AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) {
      return const EmptyState(
        title: "No Recent Sales",
        subtitle: "Once you create invoices, they will appear here.",
        icon: Iconsax.receipt_item,
      );
    }
    return Column(
      children: _recentActivity.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  Widget _buildStatsSkeleton() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: List.generate(4, (index) => const SkeletonCard()),
    );
  }

  Widget _buildActivitySkeleton() {
    return Column(
      children: List.generate(3, (index) => const SkeletonListTile()),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final invNum = activity['invoice_number'] ?? 'N/A';
    final customer = activity['customer_name'] ?? 'Walk-in';
    final amount = (activity['amount'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GlassBox(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.darkGlass,
            child: Icon(Iconsax.receipt, color: AppColors.primary, size: 18),
          ),
          title: Text("Invoice #$invNum", style: const TextStyle(color: Colors.white)),
          subtitle: Text("Customer: $customer", style: const TextStyle(color: Colors.white54)),
          trailing: Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
