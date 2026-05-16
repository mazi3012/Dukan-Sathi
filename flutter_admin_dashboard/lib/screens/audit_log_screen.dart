import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchAuditLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DataProvider>().fetchAuditLog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // Export audit logs
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, _) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataProvider.auditLog.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No audit logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Audit entries will appear here when actions are performed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (isMobile) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dataProvider.auditLog.length,
              itemBuilder: (context, index) {
                return buildAuditCard(context, dataProvider.auditLog[index]);
              },
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Timestamp')),
                  DataColumn(label: Text('Action')),
                  DataColumn(label: Text('Resource')),
                  DataColumn(label: Text('Resource ID')),
                  DataColumn(label: Text('Status')),
                ],
                rows: List.generate(
                  dataProvider.auditLog.length,
                  (index) {
                    final log = dataProvider.auditLog[index];
                    final timestamp = log['created_at'] != null
                        ? DateTime.parse(log['created_at']).toString().split('.')[0]
                        : 'N/A';
                    final status = log['status'] ?? 'unknown';
                    final isSuccess = status == 'success';

                    return DataRow(
                      cells: [
                        DataCell(Text(timestamp)),
                        DataCell(Text(log['action'] ?? '')),
                        DataCell(Text(log['resource'] ?? '')),
                        DataCell(Text(log['resource_id']?.toString() ?? 'N/A')),
                        DataCell(
                          Chip(
                            label: Text(status),
                            backgroundColor: isSuccess
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: isSuccess ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildAuditCard(BuildContext context, Map<String, dynamic> log) {
    final timestamp = log['created_at'] != null
        ? DateTime.parse(log['created_at']).toString().split('.')[0]
        : 'N/A';
    final status = log['status'] ?? 'unknown';
    final isSuccess = status == 'success';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        title: Text(log['action'] ?? 'Unknown action'),
        subtitle: Text(
          '${log['resource']} • $timestamp',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDetailRow('Action', log['action']),
                buildDetailRow('Resource', log['resource']),
                buildDetailRow('Resource ID', log['resource_id']?.toString() ?? 'N/A'),
                buildDetailRow('Status', status),
                if (log['ip_address'] != null)
                  buildDetailRow('IP Address', log['ip_address']),
                if (log['error_message'] != null)
                  buildDetailRow('Error', log['error_message']),
                if (log['changes'] != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['changes'].toString(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
