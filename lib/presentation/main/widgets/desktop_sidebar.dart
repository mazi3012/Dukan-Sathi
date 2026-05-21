import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/session.dart';
import '../../auth/pages/welcome_auth_flow.dart';
import '../../../data/sync/sync_manager.dart';

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
              _buildSyncStatusIndicator(context),
              const Divider(color: Colors.white10),
              _buildBottomActions(context, ref, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SyncManager.instance.pendingCountNotifier,
      builder: (context, pendingCount, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: SyncManager.instance.syncingNotifier,
          builder: (context, isSyncing, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (isCollapsed) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Tooltip(
                    message: isSyncing 
                        ? 'Syncing changes...' 
                        : (pendingCount > 0 ? '$pendingCount offline changes pending' : 'Fully synced with cloud'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSyncing 
                            ? AppColors.primary.withOpacity(0.1) 
                            : (pendingCount > 0 ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSyncing 
                              ? AppColors.primary.withOpacity(0.3) 
                              : (pendingCount > 0 ? Colors.amber.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                            : Icon(
                                pendingCount > 0 ? Iconsax.cloud_notif : Iconsax.cloud_change,
                                color: pendingCount > 0 ? Colors.amber : Colors.green,
                                size: 20,
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .scale(duration: 1000.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                      ),
                    ),
                  ),
                ),
              );
            }

            // Expanded Mode
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  if (isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    Icon(
                      pendingCount > 0 ? Iconsax.cloud_notif : Iconsax.cloud_change,
                      color: pendingCount > 0 ? Colors.amber : Colors.green,
                      size: 22,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSyncing 
                              ? 'Synchronizing...' 
                              : (pendingCount > 0 ? 'Local Queue' : 'Cloud Status'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSyncing 
                              ? 'Uploading to cloud' 
                              : (pendingCount > 0 ? '$pendingCount changes pending' : 'Fully synchronized'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pendingCount > 0 && !isSyncing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
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
                  pageBuilder: (_, a, _) => const WelcomeAuthFlow(),
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
