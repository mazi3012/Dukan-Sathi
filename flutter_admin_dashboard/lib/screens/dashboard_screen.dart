import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              showUserMenu(context);
            },
          ),
        ],
      ),
      drawer: isMobile ? buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) buildSidebar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),
                  const SizedBox(height: 32),
                  buildStatsRow(context),
                  const SizedBox(height: 32),
                  buildQuickAccessRow(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.grey[50],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dukan Sathi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                buildNavItem(
                  context,
                  icon: Icons.people_outlined,
                  label: 'Users',
                  route: '/users',
                ),
                buildNavItem(
                  context,
                  icon: Icons.security_outlined,
                  label: 'Roles & Permissions',
                  route: '/roles',
                ),
                buildNavItem(
                  context,
                  icon: Icons.history,
                  label: 'Audit Log',
                  route: '/audit-log',
                ),
                buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dukan Sathi Admin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                buildNavItem(
                  context,
                  icon: Icons.people_outlined,
                  label: 'Users',
                  route: '/users',
                ),
                buildNavItem(
                  context,
                  icon: Icons.security_outlined,
                  label: 'Roles & Permissions',
                  route: '/roles',
                ),
                buildNavItem(
                  context,
                  icon: Icons.history,
                  label: 'Audit Log',
                  route: '/audit-log',
                ),
                buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isActive = currentPath == route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.blue : null),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : null,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          context.go(route);
        },
      ),
    );
  }

  Widget buildStatsRow(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            StatsCard(
              title: 'Total Users',
              value: dataProvider.users.length.toString(),
              icon: Icons.people_outlined,
              color: Colors.blue,
            ),
            StatsCard(
              title: 'Total Roles',
              value: dataProvider.roles.length.toString(),
              icon: Icons.security_outlined,
              color: Colors.green,
            ),
            StatsCard(
              title: 'Total Permissions',
              value: dataProvider.permissions.length.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.purple,
            ),
            StatsCard(
              title: 'Audit Logs',
              value: dataProvider.auditLog.length.toString(),
              icon: Icons.history,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget buildQuickAccessRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            QuickAccessButton(
              icon: Icons.person_add_outlined,
              label: 'Add New User',
              onPressed: () {
                context.push('/users/create');
              },
            ),
            QuickAccessButton(
              icon: Icons.security_outlined,
              label: 'Manage Roles',
              onPressed: () {
                context.go('/roles');
              },
            ),
            QuickAccessButton(
              icon: Icons.history,
              label: 'View Audit Log',
              onPressed: () {
                context.go('/audit-log');
              },
            ),
            QuickAccessButton(
              icon: Icons.settings_outlined,
              label: 'System Settings',
              onPressed: () {
                context.go('/settings');
              },
            ),
          ],
        ),
      ],
    );
  }

  void showUserMenu(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 56, 0, 0),
      items: [
        PopupMenuItem(
          child: const Text('Profile'),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Text('Settings'),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Text('Logout'),
          onTap: () {
            authProvider.logout();
            context.go('/login');
          },
        ),
      ],
    );
  }
}

class QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const QuickAccessButton({super.key, 
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
