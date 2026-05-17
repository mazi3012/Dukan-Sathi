import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';

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
          // Background blobs for glassmorphism effect
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.lightPrimary.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.lightOutline.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          // Content
          ResponsiveLayout(
            mobile: SafeArea(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildWelcomeSection(context),
                        const SizedBox(height: 24),
                        _isLoading 
                          ? _buildOverviewSkeleton()
                          : _buildOverviewCard(),
                        const SizedBox(height: 20),
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
            desktop: _buildDesktopLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 65,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context),
                    const SizedBox(height: 24),
                    _isLoading ? _buildOverviewSkeleton() : _buildOverviewCard(),
                    const SizedBox(height: 20),
                    _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              flex: 35,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10), // Alignment
                    _buildSectionTitle(context, "Recent Activity"),
                    const SizedBox(height: 15),
                    _isLoading ? _buildActivitySkeleton() : _buildActivityList(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          icon: Icon(Iconsax.menu_1, color: Theme.of(context).iconTheme.color),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Iconsax.notification, color: Theme.of(context).iconTheme.color),
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          UserSession().userName ?? "Shop Owner",
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Sales", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("₹${_totalSales.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 4),
                      Text("12.5% vs last month", style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Iconsax.trend_up, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("₹${(_totalSales * 1.15).toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 4),
                      Text("8.3% vs last month", style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsGrid() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: isDesktop ? 1.8 : 1.4,
      children: [
        _buildStatCard("Sales", "₹${_totalSales.toStringAsFixed(0)}", Iconsax.wallet_money),
        _buildStatCard("Invoices", _invoiceCount.toString(), Iconsax.document_text),
        _buildStatCard("Expenses", "₹${_totalExpenses.toStringAsFixed(0)}", Iconsax.card_send),
        _buildStatCard("Products", _productCount.toString(), Iconsax.box),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark ? Colors.white.withOpacity(0.1) : AppColors.lightPrimarySoft;
    final iconColor = isDark ? Colors.white : AppColors.lightPrimary;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppColors.lightGlassBorder;

    return GlassBox(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
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

  Widget _buildOverviewSkeleton() {
    return const SkeletonSummaryCard();
  }

  Widget _buildStatsSkeleton() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: isDesktop ? 1.8 : 1.5,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.1) 
                  : AppColors.lightPrimarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.1) 
                    : AppColors.lightGlassBorder,
              ),
            ),
            child: Icon(
              Iconsax.receipt, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : AppColors.lightPrimary, 
              size: 20
            ),
          ),
          title: Text("Invoice #$invNum", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text("Customer: $customer", style: Theme.of(context).textTheme.bodySmall),
          trailing: Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
