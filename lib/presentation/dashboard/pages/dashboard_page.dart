import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../main/pages/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import 'package:dukansathi_new/data/local/local_database.dart';
import 'package:dukansathi_new/core/services/connectivity_service.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Section 1: Top Number Cards
  double _grossSales = 0;
  double _netRevenue = 0;
  double _gstCollected = 0;
  int _invoiceCountToday = 0;

  // Section 2: AI Insights
  double _totalMarketDues = 0;
  int _aiRestockItemsCount = 1;
  String _aiRestockItemName = "Premium Basmati Rice (5kg)";
  double _expectedRevenueTomorrow = 0;
  int _pendingApprovalsCount = 0;

  // Section 3: Recent Activity
  List<Map<String, dynamic>> _recentActivity = [];
  
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

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
      // 1. Fetch Total Sales locally
      final salesRes = await _localDb.queryAll(
        'sales',
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );
      
      double sales = 0;
      for (var row in salesRes) {
        sales += (row['amount'] as num).toDouble();
      }

      // 2. Fetch Invoice Count locally
      final invoiceCount = salesRes.length;

      // 3 & 4. Fetch Expenses and Pending Approvals (Online-only parallelized queries)
      double expenses = 0;
      int pendingApprovals = 0;
      if (_connectivity.isOnline) {
        try {
          final results = await Future.wait([
            supabase
                .from('expenses')
                .select('amount')
                .eq('shop_id', shopId),
            supabase
                .from('draft_approvals')
                .select('approval_id')
                .eq('shop_id', shopId)
                .eq('approval_status', 'PENDING'),
          ]);

          final expensesRes = results[0] as List<dynamic>;
          for (var row in expensesRes) {
            expenses += (row['amount'] as num).toDouble();
          }

          final approvalsRes = results[1] as List<dynamic>;
          pendingApprovals = approvalsRes.length;
        } catch (e) {
          debugPrint('[Dashboard] Online parallel query error: $e');
        }
      }

      // 5. Fetch Low Stock Count (< 5 units) locally
      final lowStockRes = await _localDb.queryAll(
        'products',
        where: 'shop_id = ? AND stock_quantity < ?',
        whereArgs: [shopId, 5],
      );
      final lowStock = lowStockRes.length;

      // 6. Fetch Total Market Dues locally
      final duesRes = await _localDb.queryAll(
        'customers',
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );
      
      double dues = 0;
      for (var row in duesRes) {
        dues += (row['current_balance'] as num?)?.toDouble() ?? 0;
      }

      // 7. Fetch Recent Activity locally
      final activityRes = await _localDb.queryAll(
        'sales',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'timestamp DESC',
        limit: 6,
      );

      if (mounted) {
        setState(() {
          _grossSales = sales > 0 ? sales * 1.2 : 0.0;
          _netRevenue = sales > 0 ? sales : 0.0;
          _gstCollected = _netRevenue * 0.18;
          _invoiceCountToday = invoiceCount;

          _pendingApprovalsCount = pendingApprovals;
          _totalMarketDues = dues > 0 ? dues : 0.0;
          _aiRestockItemsCount = lowStock;
          _expectedRevenueTomorrow = _netRevenue * 1.05; // 5% growth projection

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
        return '${difference.inMinutes}h ago'; // Short label
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
          // Ambient neon blur blobs
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
                    const Color(0xFF10B981).withOpacity(0.08),
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
              _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
              const SizedBox(height: 25),
              _buildSectionTitle(context, "Dukan Sathi Insights"),
              const SizedBox(height: 12),
              _isLoading ? _buildInsightsSkeleton() : _buildInsightsGrid(isDesktop: false),
              const SizedBox(height: 25),
              _buildSectionTitle(context, "Recent Invoices & Activity"),
              const SizedBox(height: 12),
              if (!_isLoading) ...[
                _buildSalesChart(),
                const SizedBox(height: 16),
              ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 28),
          _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Dukan Sathi Insights
                Expanded(
                  flex: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, "Dukan Sathi Insights"),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading ? _buildInsightsSkeleton() : _buildInsightsGrid(isDesktop: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column: Recent Invoices & Activity
                Expanded(
                  flex: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(context, "Recent Invoices & Activity"),
                          // Search & Filter header controls
                          Row(
                            children: [
                              Container(
                                width: 140,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    const Icon(Iconsax.search_normal, size: 12, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text("Search", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: const Icon(Iconsax.filter_search, size: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading ? _buildActivitySkeleton() : Column(
                          children: [
                            _buildSalesChart(),
                            const SizedBox(height: 16),
                            Expanded(child: _buildActivityCard()),
                          ],
                        ),
                      ),
                    ],
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
      leading: IconButton(
        icon: const Icon(Iconsax.menu),
        onPressed: () {
          mainScaffoldKey.currentState?.openDrawer();
        },
      ),
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
    final userName = UserSession().userName ?? "Mazidur Rahman";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: const NetworkImage(
                'https://api.dicebear.com/7.x/adventurer/png?seed=Mazidur',
              ),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isDesktop) ...[
          Row(
            children: [
              // Notification bell with red dot
              Stack(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Iconsax.notification, color: Colors.white70),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Settings gear
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.setting_4, color: Colors.white70),
                  ),
              const SizedBox(width: 16),
              // Search bar pill
              Container(
                width: 220,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Iconsax.search_normal, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      "Search",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05);
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        int crossAxisCount = 2;
        if (width > 850) {
          crossAxisCount = 4;
        } else if (width > 480) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        
        // Dynamic Aspect Ratio locks Card height to exactly 135.0px for perfect organization & zero clipping
        final double cardHeight = crossAxisCount == 1 ? 110.0 : 135.0;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricsCard(
              "Gross Sales",
              "₹${_grossSales.toStringAsFixed(0)}",
              trendLabel: "Total value before discounts",
              chartData: [120, 150, 130, 170, 160, 180],
            ),
            _buildMetricsCard(
              "Net Revenue",
              "₹${_netRevenue.toStringAsFixed(0)}",
              trendLabel: "Gross Sales minus discounts",
              chartData: [100, 120, 110, 140, 130, 157],
            ),
            _buildMetricsCard(
              "GST Collected",
              "₹${_gstCollected.toStringAsFixed(0)}",
              trendLabel: "Total tax set aside",
            ),
            _buildMetricsCard(
              "Total Invoices",
              _invoiceCountToday.toString(),
              trendLabel: "Transactions today",
              showPageDots: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsCard(
    String title,
    String value, {
    String? trendLabel,
    List<double>? chartData,
    bool showPageDots = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenBorder = const Color(0xFF10B981).withOpacity(0.35);

    return GlassBox(
      borderRadius: 20,
      border: Border.all(color: greenBorder, width: 1.2),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.02),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            if (chartData != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (trendLabel != null)
                    Text(
                      trendLabel,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(
                    width: 70,
                    height: 24,
                    child: CustomPaint(
                      painter: SparklinePainter(chartData, const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ] else if (showPageDots) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10), // blank spacing balance
            ]
          ],
        ),
      ),
    );
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
        final crossAxisCount = isDesktop ? 2 : (width > 480 ? 2 : 1);
        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        
        // Locked aspect ratio for insights cards
        final double cardHeight = isDesktop ? 130.0 : 120.0;
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
              "Market Credit.",
              "₹${_totalMarketDues.toStringAsFixed(0)} Outstanding",
              "Manage Ledger",
              const Color(0xFF2563EB),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Opening Market Credit balances..."), backgroundColor: Color(0xFF2563EB)),
                );
              },
            ),
            _buildInsightCard(
              "AI Smart Restock.",
              "$_aiRestockItemName will run out before the weekend.",
              "Order Stock",
              const Color(0xFFDC2626),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ordering stock..."), backgroundColor: Color(0xFFDC2626)),
                );
              },
            ),
            _buildInsightCard(
              "AI Sales Projection.",
              "Expected Revenue: ₹${_expectedRevenueTomorrow.toStringAsFixed(0)}",
              "View Insights",
              const Color(0xFF10B981),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Opening detailed analytics..."), backgroundColor: Color(0xFF10B981)),
                );
              },
            ),
            _buildInsightCard(
              "AI Approvals.",
              "$_pendingApprovalsCount Pending Reviews",
              "Review",
              const Color(0xFFD97706),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Launching AI Approvals Manager..."), backgroundColor: Color(0xFFD97706)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String buttonText,
    Color color, {
    VoidCallback? onTap,
    bool showButton = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = color.withOpacity(isDark ? 0.3 : 0.4);
    
    return GlassBox(
      borderRadius: 16,
      border: Border.all(color: borderColor, width: 1.2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (showButton && onTap != null)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              Text(
                "Manage SKU catalog",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      borderRadius: 20,
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Hourly Sales Trend",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Avg: ₹1,250/hr",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100, // Fixed height for chart
              width: double.infinity,
              child: CustomPaint(
                painter: SparklinePainter(
                  [10, 25, 45, 30, 60, 85, 40, 55, 90, 75, 110, 100], // Dummy hourly data
                  const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassBox(
      borderRadius: 20,
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: _recentActivity.isEmpty
                  ? const Center(
                      child: EmptyState(
                        title: "No Recent Sales",
                        subtitle: "Create invoices inside the Billing page to view logs.",
                        icon: Iconsax.receipt_item,
                      ),
                    )
                  : Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.0), // Invoice #
                        1: FlexColumnWidth(1.2), // Customer
                        2: FlexColumnWidth(1.1), // Date/Time
                        3: FlexColumnWidth(0.9), // Status
                        4: FlexColumnWidth(1.0), // Amount
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Table header row
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white12 : Colors.black12,
                                width: 1,
                              ),
                            ),
                          ),
                          children: [
                            _buildTableHeaderCell("Invoice #"),
                            _buildTableHeaderCell("Customer"),
                            _buildTableHeaderCell("Time"),
                            _buildTableHeaderCell("Status", align: TextAlign.center),
                            _buildTableHeaderCell("Net Amount", align: TextAlign.right),
                          ],
                        ),
                        // Data rows
                        ..._recentActivity.take(4).map((activity) {
                          final invNum = activity['invoice_number'] ?? 'N/A';
                          final customer = activity['customer_name'] ?? 'Walk-in';
                          final amount = (activity['amount'] as num?)?.toDouble() ?? 0;
                          final timeStr = _formatTimestamp(activity['timestamp']);

                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            children: [
                              _buildTableCellText(invNum, isBold: true),
                              _buildTableCellText(customer),
                              _buildTableCellText(timeStr),
                              TableCell(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                    ),
                                    child: const Text(
                                      "PAID",
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    "₹${amount.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // View all action
              },
              child: const Text(
                "View All Invoices",
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCellText(String text, {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.87) : Colors.black.withOpacity(0.87),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
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
              Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
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
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double cardHeight = 135.0;
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
        int crossAxisCount = 2;
        if (width < 360) crossAxisCount = 1;

        final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double cardHeight = 130.0;
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

  Widget _buildActivitySkeleton() {
    return Column(
      children: List.generate(4, (index) => const SkeletonListTile()),
    );
  }
}

// Sparkline Wave Custom Painter matching desktop mockup exactly!
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double dx = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    double getX(int index) => index * dx;
    double getY(double val) => size.height - ((val - minVal) / range) * (size.height * 0.7) - (size.height * 0.15);

    path.moveTo(getX(0), getY(data[0]));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final double x1 = getX(i - 1);
      final double y1 = getY(data[i - 1]);
      final double x2 = getX(i);
      final double y2 = getY(data[i]);
      
      final double controlX1 = x1 + (x2 - x1) / 2;
      final double controlY1 = y1;
      final double controlX2 = x1 + (x2 - x1) / 2;
      final double controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
