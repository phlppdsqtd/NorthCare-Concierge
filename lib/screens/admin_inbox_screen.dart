import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_unit_screen.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  late Future<List<Map<String, dynamic>>> _inquiriesFuture;
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;
  late Future<List<Map<String, dynamic>>> _unitsFuture;
  late Future<List<Map<String, dynamic>>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

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

      _unitsFuture = Supabase.instance.client
          .from('units')
          .select()
          .order('building', ascending: true)
          .order('unit_code', ascending: true);

      _announcementsFuture = Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
    });
  }

  Future<void> _toggleStatus(String table, String id, String currentStatus) async {
    final newStatus = currentStatus == 'pending' ? 'resolved' : 'pending';
    await Supabase.instance.client.from(table).update({'status': newStatus}).eq('id', id);
    _refreshData();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteRecord(String table, String id) async {
    await Supabase.instance.client.from(table).delete().eq('id', id);
    _refreshData();
    if (mounted) Navigator.pop(context);
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();

              if (title.isEmpty || message.isEmpty) return;

              await Supabase.instance.client.from('announcements').insert({
                'title': title,
                'message': message,
              });

              _refreshData();

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final messageController = TextEditingController(text: data['message'] ?? '');

    bool isEditing = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: isEditing
                ? TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  )
                : Text((data['title'] ?? '').toString()),
            content: isEditing
                ? TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message'),
                  )
                : Text((data['message'] ?? '').toString()),
            actions: [
              if (!isEditing)
                TextButton(
                  onPressed: () => _deleteRecord('announcements', data['id']),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              if (!isEditing)
                TextButton(
                  onPressed: () => setState(() => isEditing = true),
                  child: const Text('Edit'),
                ),
              if (isEditing)
                ElevatedButton(
                  onPressed: () async {
                    final newTitle = titleController.text.trim();
                    final newMessage = messageController.text.trim();
                    if (newTitle.isEmpty || newMessage.isEmpty) return;

                    await Supabase.instance.client
                        .from('announcements')
                        .update({
                          'title': newTitle,
                          'message': newMessage,
                        })
                        .eq('id', data['id']);

                    _refreshData();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
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
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(child: Text('No records found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,

          // ✅ FIXED TAB COLORS HERE
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.person_search), text: 'Inquiries'),
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
              Tab(icon: Icon(Icons.apartment), text: 'Units'),
              Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal,
          onPressed: _showCreateAnnouncementDialog,
          child: const Icon(Icons.add),
        ),

        body: TabBarView(
          children: [
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
                      child: Icon(
                        isPending ? Icons.pending : Icons.check,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                    ),
                    title: Text((data['name'] ?? '').toString()),
                    subtitle: Text((data['message'] ?? '').toString()),
                  ),
                );
              },
            ),

            _buildDataList(
              future: _maintenanceFuture,
              itemBuilder: (context, data) {
                final isPending = data['status'] == 'pending';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _showActionDialog(data, 'maintenance_requests', 'Maintenance'),
                    leading: Icon(Icons.build, color: isPending ? Colors.orange : Colors.green),
                    title: Text('${data['building_name']} - ${data['unit_number']}'),
                    subtitle: Text((data['issue_category'] ?? '').toString()),
                  ),
                );
              },
            ),

            _buildDataList(
              future: _unitsFuture,
              itemBuilder: (context, data) {
                final isAvailable = data['status'] == 'Available';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUnitScreen(unit: data),
                        ),
                      );
                      if (shouldRefresh == true) _refreshData();
                    },
                    leading: Icon(
                      isAvailable ? Icons.check_circle : Icons.person,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    title: Text('${data['building']} - Unit ${data['unit_code']}'),
                    subtitle: Text(
                      isAvailable
                          ? 'Available'
                          : 'Tenant: ${data['first_name']} ${data['last_name']}',
                    ),
                    trailing: const Icon(Icons.edit),
                  ),
                );
              },
            ),

            _buildDataList(
              future: _announcementsFuture,
              itemBuilder: (context, data) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _showAnnouncementDialog(data),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.campaign, color: Colors.teal),
                    ),
                    title: Text(
                      (data['title'] ?? 'No Title').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      (data['message'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

  void _showActionDialog(Map<String, dynamic> data, String table, String title) {
    final isPending = data['status'] == 'pending';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Manage $title'),
        content: Text((data['message'] ?? data['description'] ?? '').toString()),
        actions: [
          TextButton(
            onPressed: () => _deleteRecord(table, data['id']),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () => _toggleStatus(table, data['id'], data['status']),
            child: Text(isPending ? 'Resolve' : 'Set Pending'),
          ),
        ],
      ),
    );
  }
}