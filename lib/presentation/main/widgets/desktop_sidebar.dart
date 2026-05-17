import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/session.dart';
import '../../auth/pages/login_page.dart';

class DesktopSidebar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 85 : 260,
      height: double.infinity,
      margin: const EdgeInsets.all(20),
      child: GlassBox(
        borderRadius: 24,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 16, 
            vertical: 20
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebarHeader(context),
              const SizedBox(height: 30),
              Expanded(child: _buildNavigationItems(context)),
              const Divider(color: Colors.white10),
              _buildBottomActions(context, ref, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 10),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Icon(Iconsax.shop, size: 20, color: Colors.white),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "DUKAN SATHI",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    final navItems = [
      _SidebarItem(Iconsax.home_2, "Home"),
      _SidebarItem(Iconsax.box, "Stock Inventory"),
      _SidebarItem(Iconsax.receipt_2, "Sales History"),
      _SidebarItem(Iconsax.people, "Customers"),
      _SidebarItem(Iconsax.message_programming, "AI Assistant"),
    ];

    return ListView.builder(
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final isSelected = currentIndex == index;
        return _buildItemWidget(context, index, navItems[index], isSelected);
      },
    );
  }

  Widget _buildItemWidget(BuildContext context, int index, _SidebarItem item, bool isSelected, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap ?? () => onDestinationSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.lightPrimarySoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? (isDark ? AppColors.primary : AppColors.lightPrimary)
                  : (isDark ? Colors.white60 : AppColors.lightOnSurface.withOpacity(0.5)),
              size: 22,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.lightOnSurface)
                        : (isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7)),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        _buildItemWidget(
          context, 
          -1, 
          _SidebarItem(isDark ? Iconsax.sun_1 : Iconsax.moon, isCollapsed ? "" : "Toggle Theme"), 
          false,
          onTap: () {
            ref.read(themeProvider.notifier).toggleTheme();
          }
        ),
        _buildItemWidget(
          context, 
          -1, 
          _SidebarItem(
            isCollapsed ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2, 
            isCollapsed ? "" : "Collapse Menu"
          ), 
          false,
          onTap: onToggleCollapse
        ),
        _buildItemWidget(
          context, 
          -1, 
          _SidebarItem(Iconsax.logout, isCollapsed ? "" : "Log Out"), 
          false,
          onTap: () async {
            await UserSession().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, a, _) => const LoginPage(),
                  transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 500),
                ),
                (route) => false,
              );
            }
          }
        ),
      ],
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem(this.icon, this.label);
}
