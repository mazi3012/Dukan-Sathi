import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dukan_sathi_logo.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const LandingPage({super.key, required this.onGetStarted});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart AI Billing & POS',
      'subtitle': 'Revolutionize your sales checkout',
      'description': 'Speed up your billing by 3x with voice commands, automatic GST calculations, and instant digital invoice receipts.',
      'icon': Iconsax.microphone_2,
      'type': 'billing',
    },
    {
      'title': 'Smart Stock Alerts',
      'subtitle': 'Never lose a sale to low stock',
      'description': 'Our smart algorithms track your inventory levels in real-time, giving you predictive restock alerts for your bestsellers.',
      'icon': Iconsax.box,
      'type': 'inventory',
    },
    {
      'title': 'Real-Time Insights',
      'subtitle': 'A dashboard built for shop growth',
      'description': 'Keep a pulse on gross sales, net revenue, active customers, and profit trends. Elevate your retail decisions with AI suggestions.',
      'icon': Iconsax.chart_2,
      'type': 'analytics',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundBlobs(context),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                
                return Column(
                  children: [
                    _buildAppBar(context, isDark),
                    Expanded(
                      child: isDesktop 
                          ? _buildDesktopLayout(context, isDark)
                          : _buildMobileLayout(context, isDark),
                    ),
                    _buildBottomNavigation(context, isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const DukanSathiHeader(
            height: 32,
            showGlow: false,
            animate: true,
          ),
          TextButton(
            onPressed: widget.onGetStarted,
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.lightGlassBorder.withOpacity(0.3),
                ),
              ),
            ),
            child: const Text('Skip Tour', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildTextSlider(context, isDark),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 5,
            child: Center(
              child: _buildIllustrationContainer(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildIllustrationContainer(context, isDark),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildTextSlider(context, isDark),
        ),
      ],
    );
  }

  Widget _buildTextSlider(BuildContext context, bool isDark) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _slides.length,
      itemBuilder: (context, index) {
        final slide = _slides[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Text(
                  slide['subtitle'].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(),
              const SizedBox(height: 16),
              Text(
                slide['title'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.lightOnSurface,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              Text(
                slide['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.65),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIllustrationContainer(BuildContext context, bool isDark) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow for current slide
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getSlideColor(_currentPage).withOpacity(isDark ? 0.15 : 0.25),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          
          // Outer Glass Card
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightGlassBorder.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 320,
                      height: 250,
                      child: _buildIllustrationContent(context, _currentPage, isDark),
                    ),
                  ),
                ),
              ),
            ),
          ).animate(key: ValueKey(_currentPage)).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Color _getSlideColor(int index) {
    switch (index) {
      case 0:
        return AppColors.primary;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildIllustrationContent(BuildContext context, int pageIndex, bool isDark) {
    switch (pageIndex) {
      case 0:
        return _buildBillingIllustration(context, isDark);
      case 1:
        return _buildInventoryIllustration(context, isDark);
      case 2:
        return _buildAnalyticsIllustration(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // Slide 1 Content: AI Billing Mock
  Widget _buildBillingIllustration(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.receipt, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'AI INVOICE DRAFT',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightOnSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '#8439',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildBillingItemRow('Premium Basmati Rice 5kg', '1 unit', '₹499.00', isDark),
        const SizedBox(height: 8),
        _buildBillingItemRow('Organic Sunflower Oil 1L', '2 units', '₹360.00', isDark),
        const SizedBox(height: 8),
        _buildBillingItemRow('Desi Cow Ghee 500ml', '1 unit', '₹280.00', isDark),
        const Divider(height: 24, thickness: 1, color: Colors.white12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GST & Taxes Included', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
            Text(
              'Total: ₹1,139.00',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Voice microphone pulse mock
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.microphone_2, color: Colors.red, size: 16)
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(duration: 800.ms, curve: Curves.easeInOut, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15))
                    .then()
                    .scale(duration: 800.ms),
                const SizedBox(width: 8),
                Text(
                  'Listening: "Add 1 Surf Excel"...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.lightOnSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingItemRow(String name, String qty, String price, bool isDark) {
    return Row(
      children: [
        Icon(Iconsax.tick_circle5, color: AppColors.primary.withOpacity(0.8), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightOnSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          qty,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          price,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.lightOnSurface,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  // Slide 2 Content: Smart Inventory Stock Alert Mock
  Widget _buildInventoryIllustration(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INVENTORY REPLENISHMENT',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightOnSurface.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Icon(Iconsax.box, color: Colors.orange, size: 18),
          ],
        ),
        const SizedBox(height: 20),
        _buildStockAlertItem('Amul Butter 500g', 3, 25, 0.12, Colors.red, 'Critical Stock!', isDark),
        const SizedBox(height: 16),
        _buildStockAlertItem('Fortune Soyabean Oil 1L', 8, 40, 0.20, Colors.orange, 'Restock Recommended', isDark),
        const SizedBox(height: 16),
        _buildStockAlertItem('Tata Iodized Salt 1kg', 85, 100, 0.85, Colors.green, 'Stock Healthy', isDark),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Iconsax.flash_1, size: 16, color: Colors.white),
            label: const Text('Auto Restock (AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ).animate().shimmer(delay: 1.seconds, duration: 1.5.seconds),
        ),
      ],
    );
  }

  Widget _buildStockAlertItem(String name, int current, int max, double percentage, Color color, String badge, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$current/$max units',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Slide 3 Content: Analytics Line Chart Mock
  Widget _buildAnalyticsIllustration(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GROSS SALES TODAY',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.lightOnSurface.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹28,590.50',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightOnSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.arrow_up_3, color: Colors.blue, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '+14.8%',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.lightOnSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Mini Chart Mock
        SizedBox(
          height: 120,
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: LineChartPainter(isDark: isDark),
              ),
              // Floating pulsing highlight point on the line
              Positioned(
                right: 25,
                top: 30,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.blue, blurRadius: 10, spreadRadius: 4),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(duration: 1.seconds, begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3))
                    .then()
                    .scale(duration: 1.seconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniStatCard('Customers', '182', isDark),
            _buildMiniStatCard('AI Invoices', '74', isDark),
            _buildMiniStatCard('Avg Basket', '₹386', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppColors.primary 
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _slides.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  widget.onGetStarted();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Get Started' : 'Next Screen',
                  key: ValueKey(_currentPage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).scale(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onGetStarted,
            child: Text(
              'Already using Dukan Sathi? Sign In',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 380,
            height: 380,
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
          bottom: -150,
          right: -100,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getSlideColor(_currentPage).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final bool isDark;

  LineChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.9);
    path.cubicTo(
      size.width * 0.2, size.height * 0.95,
      size.width * 0.35, size.height * 0.6,
      size.width * 0.5, size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.65, size.height * 0.4,
      size.width * 0.8, size.height * 0.25,
      size.width * 0.95, size.height * 0.18,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width * 0.95, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw Grid Lines (dotted style mockup)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * 0.25 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
