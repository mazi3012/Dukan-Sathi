import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../widgets/desktop_sidebar.dart';
import '../../../core/session.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../inventory/pages/inventory_page.dart';
import '../../billing/pages/billing_page.dart';
import '../../customers/pages/customers_page.dart';
import '../../chat/pages/ai_chat_page.dart';
import '../../auth/pages/login_page.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Widget> _pages = [
    const DashboardPage(),
    const InventoryPage(),
    const BillingPage(),
    const CustomersPage(),
    const AiChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        key: mainScaffoldKey,
        extendBody: true,
        drawer: _buildDrawer(),
        body: _pages[_currentIndex],
        bottomNavigationBar: _buildBottomBar(),
      ),
      tablet: Scaffold(
        body: Row(
          children: [
            DesktopSidebar(
              currentIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              isCollapsed: true, // Always collapsed on tablet
              onToggleCollapse: () {}, // No-op on tablet
            ),
            Expanded(
              child: _pages[_currentIndex],
            ),
          ],
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            DesktopSidebar(
              currentIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
            ),
            Expanded(
              child: _pages[_currentIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                  (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildDrawerHeader(isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildDrawerItem(Iconsax.user, "Profile"),
                _buildDrawerItem(
                  isDark ? Iconsax.sun_1 : Iconsax.moon, 
                  isDark ? "Light Mode" : "Dark Mode",
                  onTap: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
                _buildDrawerItem(Iconsax.setting_2, "Settings"),
                _buildDrawerItem(Iconsax.info_circle, "Help & Support"),
                _buildDrawerItem(Iconsax.star, "Rate Us"),
              ],
            ),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildLogoutItem(isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary,
            child: Icon(Iconsax.user, size: 35, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            UserSession().userName ?? "Shop Owner",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            ),
          ),
          Text(
            UserSession().shopName ?? "Dukan Sathi Shop",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54, 
              fontSize: 14
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      onTap: onTap ?? () => Navigator.pop(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildLogoutItem(bool isDark) {
    return ListTile(
      leading: const Icon(Iconsax.logout, color: AppColors.error),
      title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () async {
        Navigator.pop(context);
        await UserSession().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, a, _) => const LoginPage(),
              transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        }
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Iconsax.home_2, "Home"),
              _buildNavItem(1, Iconsax.box, "Stock"),
              _buildNavItem(2, Iconsax.receipt_2, "Bills"),
              _buildNavItem(3, Iconsax.people, "Customers"),
              _buildNavItem(4, Iconsax.message_programming, "AI Chat"),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.lightPrimarySoft) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (isDark ? AppColors.primary : AppColors.lightPrimary) 
                  : (isDark ? Colors.white54 : AppColors.lightOnSurface.withOpacity(0.4)),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.primary : AppColors.lightPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ).animate().fadeIn().slideX(begin: -0.2),
            ],
          ],
        ),
      ),
    );
  }
}
