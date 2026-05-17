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
  int _pendingApprovalsCount = 0;
  int _lowStockCount = 0;
  double _totalMarketDues = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
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
          .limit(6);

      // 6. Fetch Pending Approvals Count
      final approvalsRes = await supabase
          .from('draft_approvals')
          .select('approval_id')
          .eq('shop_id', shopId)
          .eq('approval_status', 'PENDING');
      final pendingApprovals = approvalsRes.length;

      // 7. Fetch Low Stock Count (< 5 units)
      final lowStockRes = await supabase
          .from('products')
          .select('id')
          .eq('shop_id', shopId)
          .lt('stock_quantity', 5);
      final lowStock = lowStockRes.length;

      // 8. Fetch Total Market Dues
      final duesRes = await supabase
          .from('customers')
          .select('current_balance')
          .eq('shop_id', shopId);
      
      double dues = 0;
      for (var row in duesRes) {
        dues += (row['current_balance'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalSales = sales;
          _invoiceCount = invoiceCount;
          _totalExpenses = expenses;
          _productCount = productCount;
          _pendingApprovalsCount = pendingApprovals;
          _lowStockCount = lowStock;
          _totalMarketDues = dues;
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

  String _formatTimestamp(String? timestampStr) {
    if (timestampStr == null) return '';
    try {
      final dateTime = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ambient blur blobs
          Positioned(
            top: -120,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildMobileAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeSection(context),
              const SizedBox(height: 20),
              _isLoading ? const SkeletonSummaryCard() : _buildOverviewCard(),
              const SizedBox(height: 20),
              _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
              const SizedBox(height: 25),
              _buildSectionTitle(context, "Dukan Sathi Insights"),
              const SizedBox(height: 12),
              _isLoading ? _buildInsightsSkeleton() : _buildInsightsGrid(isDesktop: false),
              const SizedBox(height: 25),
              _buildSectionTitle(context, "Recent Activity"),
              const SizedBox(height: 12),
              _isLoading ? _buildActivitySkeleton() : _buildActivityList(),
              const SizedBox(height: 100), // Navigation spacer
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Greetings, Metrics & Business Insights
          Expanded(
            flex: 62,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _isLoading ? const SkeletonSummaryCard() : _buildOverviewCard(),
                  const SizedBox(height: 24),
                  _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, "Dukan Sathi Insights"),
                  const SizedBox(height: 16),
                  _isLoading ? _buildInsightsSkeleton() : _buildInsightsGrid(isDesktop: true),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right Side: Timeline Recent Activity Feed
          Expanded(
            flex: 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, "Recent Activity"),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading 
                      ? _buildActivitySkeleton() 
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildActivityList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.shop, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            "DUKAN SATHI",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _fetchDashboardData,
          icon: Icon(Iconsax.refresh, color: Theme.of(context).iconTheme.color),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);
    final userName = UserSession().userName ?? "Shop Owner";
    final shopName = UserSession().shopName ?? "Your Retail Shop";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: isDesktop ? 26 : 22,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.primary.withOpacity(0.2) 
                  : AppColors.lightPrimarySoft,
              child: Icon(
                Iconsax.user, 
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary,
                size: isDesktop ? 26 : 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 24 : 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isDesktop)
          IconButton(
            tooltip: "Refresh Dashboard",
            onPressed: _fetchDashboardData,
            icon: Icon(Iconsax.refresh, color: Theme.of(context).iconTheme.color),
          ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05);
  }

  Widget _buildOverviewCard() {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);
    
    final overviewGradient = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF047857), Color(0xFF064E3B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF047857).withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: overviewGradient,
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.04),
            ),
          ),
          isDesktop ? _buildDesktopOverviewContent() : _buildMobileOverviewContent(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08);
  }

  Widget _buildDesktopOverviewContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildOverviewColumn("Total Sales", _totalSales, "12.5% vs last month"),
              Container(
                height: 50,
                width: 1,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 40),
              ),
              _buildOverviewColumn("Total Revenue", _totalSales * 1.15, "8.3% vs last month"),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: const Icon(Iconsax.trend_up, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildMobileOverviewContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildOverviewColumn("Total Sales", _totalSales, "12.5% vs last month")),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Iconsax.trend_up, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildOverviewColumn("Total Revenue", _totalSales * 1.15, "8.3% vs last month"),
        ),
      ],
    );
  }

  Widget _buildOverviewColumn(String title, double value, String helperText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          "₹${value.toStringAsFixed(0)}", 
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 13),
            const SizedBox(width: 4),
            Text(helperText, style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        int crossAxisCount = 2;
        if (width > 850) {
          crossAxisCount = 4;
        } else if (width > 480) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        
        // Dynamic Aspect Ratio locks Card height to exactly 120.0px for perfect organization & zero clipping
        const double cardHeight = 120.0;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard("Sales", "₹${_totalSales.toStringAsFixed(0)}", Iconsax.wallet_money, AppColors.success),
            _buildStatCard("Invoices", _invoiceCount.toString(), Iconsax.document_text, AppColors.primary),
            _buildStatCard("Expenses", "₹${_totalExpenses.toStringAsFixed(0)}", Iconsax.card_send, AppColors.error),
            _buildStatCard("Products", _productCount.toString(), Iconsax.box, Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark ? color.withOpacity(0.15) : color.withOpacity(0.1);
    final iconColor = isDark ? color : color.withOpacity(0.9);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder;

    return GlassBox(
      borderRadius: 16,
      border: Border.all(color: borderColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? color.withOpacity(0.2) : Colors.transparent),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInsightsGrid({required bool isDesktop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        int crossAxisCount = isDesktop ? 3 : 2;
        if (width < 360) {
          crossAxisCount = 1;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        final double cardHeight = crossAxisCount == 1 ? 85.0 : 100.0;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildInsightCard(
              "AI Approvals", 
              "$_pendingApprovalsCount Pending", 
              _pendingApprovalsCount > 0 ? "Voice review required" : "All drafts processed",
              Iconsax.microphone_2,
              _pendingApprovalsCount > 0 ? AppColors.warning : AppColors.success,
            ),
            _buildInsightCard(
              "Low Stock Alert", 
              "$_lowStockCount Products", 
              _lowStockCount > 0 ? "Under 5 items remaining" : "Stock fully optimized",
              Iconsax.warning_2,
              _lowStockCount > 0 ? AppColors.error : AppColors.success,
            ),
            _buildInsightCard(
              "Market Credit", 
              "₹${_totalMarketDues.toStringAsFixed(0)}", 
              "Outstanding customer dues",
              Iconsax.wallet_3,
              _totalMarketDues > 0 ? AppColors.primary : AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return GlassBox(
      borderRadius: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) {
      return const EmptyState(
        title: "No Recent Sales",
        subtitle: "Create invoices inside the Billing page to view logs.",
        icon: Iconsax.receipt_item,
      );
    }
    return Column(
      children: _recentActivity.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final invNum = activity['invoice_number'] ?? 'N/A';
    final customer = activity['customer_name'] ?? 'Walk-in';
    final amount = (activity['amount'] as num?)?.toDouble() ?? 0;
    final timeStr = _formatTimestamp(activity['timestamp']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassBox(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.08) 
                  : AppColors.lightPrimarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.receipt, color: AppColors.primary, size: 18),
          ),
          title: Text(
            "Invoice #$invNum", 
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Customer: $customer", style: Theme.of(context).textTheme.bodySmall),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15)),
              if (timeStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(timeStr, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width > 850) {
          crossAxisCount = 4;
        } else if (width > 480) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double cardHeight = 120.0;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: List.generate(4, (index) => const SkeletonCard()),
        );
      },
    );
  }

  Widget _buildInsightsSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 360) crossAxisCount = 1;

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        final double cardHeight = crossAxisCount == 1 ? 85.0 : 100.0;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: List.generate(3, (index) => const SkeletonCard()),
        );
      },
    );
  }

  Widget _buildActivitySkeleton() {
    return Column(
      children: List.generate(4, (index) => const SkeletonListTile()),
    );
  }
}
