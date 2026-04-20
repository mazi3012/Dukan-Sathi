import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({Key? key}) : super(key: key);

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchRoles();
      context.read<DataProvider>().fetchPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Roles & Permissions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Roles'),
              Tab(text: 'Permissions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RolesTab(),
            PermissionsTab(),
          ],
        ),
      ),
    );
  }
}

class RolesTab extends StatelessWidget {
  const RolesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        if (dataProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dataProvider.roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No roles found'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: dataProvider.roles.map((role) {
              return SizedBox(
                width: isMobile ? double.infinity : 280,
                child: RoleCard(role: role),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class PermissionsTab extends StatelessWidget {
  const PermissionsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        if (dataProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dataProvider.permissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No permissions found'),
              ],
            ),
          );
        }

        // Group permissions by resource
        final groupedPerms = <String, List<Map<String, dynamic>>>{};
        for (final perm in dataProvider.permissions) {
          final resource = perm['resource'] ?? 'Other';
          groupedPerms.putIfAbsent(resource, () => []).add(perm);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedPerms.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((perm) {
                      return Chip(
                        label: Text(perm['permission_name'] ?? ''),
                        avatar: Icon(
                          perm['action'] == 'manage'
                              ? Icons.edit_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;

  const RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.security_outlined,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['role_name'] ?? '',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        role['description'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outlined),
                  label: const Text('Delete'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
