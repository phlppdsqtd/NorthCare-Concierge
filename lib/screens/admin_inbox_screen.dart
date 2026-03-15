import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  // We use late Futures so we can re-trigger them to refresh the screen
  late Future<List<Map<String, dynamic>>> _inquiriesFuture;
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Call this whenever we update or delete a record to reload the UI
  void _refreshData() {
    setState(() {
      _inquiriesFuture = Supabase.instance.client
          .from('inquiries')
          .select()
          .order('created_at', ascending: false);

      _maintenanceFuture = Supabase.instance.client
          .from('maintenance_requests')
          .select()
          .order('created_at', ascending: false);
    });
  }

  // Function to Update Status
  Future<void> _toggleStatus(String table, String id, String currentStatus) async {
    final newStatus = currentStatus == 'pending' ? 'resolved' : 'pending';
    try {
      await Supabase.instance.client.from(table).update({'status': newStatus}).eq('id', id);
      _refreshData();
      if (mounted) Navigator.pop(context); // Close the dialog
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Function to Delete Record
  Future<void> _deleteRecord(String table, String id) async {
    try {
      await Supabase.instance.client.from(table).delete().eq('id', id);
      _refreshData();
      if (mounted) Navigator.pop(context); // Close the dialog
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // The Popup Dialog when an admin taps a record
  void _showActionDialog(Map<String, dynamic> data, String table, String title) {
    final isPending = data['status'] == 'pending';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${data['status']?.toUpperCase()}', 
                style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.orange : Colors.green)),
              const Divider(),
              const Text('Full Message/Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(data['message'] ?? data['description'] ?? 'No details provided.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _deleteRecord(table, data['id']),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () => _toggleStatus(table, data['id'], data['status']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(isPending ? 'Mark as Resolved' : 'Mark as Pending'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.person_search), text: 'Inquiries'),
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Inquiries List
            _buildDataList(
              future: _inquiriesFuture,
              itemBuilder: (context, data) {
                final isPending = data['status'] == 'pending';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _showActionDialog(data, 'inquiries', 'Inquiry'),
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                      child: Icon(isPending ? Icons.pending_actions : Icons.check_circle, 
                        color: isPending ? Colors.orange : Colors.green),
                    ),
                    title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Unit: ${data['unit_type']}\nContact: ${data['contact_info']}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),

            // TAB 2: Maintenance List
            _buildDataList(
              future: _maintenanceFuture,
              itemBuilder: (context, data) {
                final isPending = data['status'] == 'pending';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _showActionDialog(data, 'maintenance_requests', 'Maintenance Request'),
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                      child: Icon(isPending ? Icons.build_circle : Icons.check_circle, 
                        color: isPending ? Colors.orange : Colors.green),
                    ),
                    title: Text('${data['building_name']} - Unit ${data['unit_number']}', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tenant: ${data['tenant_name']}\nIssue: ${data['issue_category']}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataList({
    required Future<List<Map<String, dynamic>>> future,
    required Widget Function(BuildContext, Map<String, dynamic>) itemBuilder,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No records found.'));
        }

        final items = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return itemBuilder(context, items[index]);
          },
        );
      },
    );
  }
}