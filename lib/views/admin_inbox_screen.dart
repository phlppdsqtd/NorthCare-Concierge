import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_inbox_viewmodel.dart';
import '../models/unit_model.dart';
import '../models/inquiry_model.dart';
import '../models/maintenance_model.dart';
import '../models/announcement_model.dart';
import 'edit_unit_screen.dart';
import 'admin_settings_screen.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.microtask(() => context.read<AdminInboxViewModel>().fetchData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showActionDialog(dynamic item, String table, String type) {
    // Get status safely regardless of object type
    String currentStatus = "";
    String id = "";
    if (item is Inquiry) {
      currentStatus = item.status ?? 'pending';
      id = item.id;
    }
    if (item is MaintenanceRequest) {
      currentStatus = item.status ?? 'pending';
      id = item.id;
    }

    final isPending = currentStatus == 'pending';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Manage $type'),
        content: Text('Current Status: $currentStatus'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().deleteRecord(table, id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().toggleStatus(
                table,
                id,
                currentStatus,
              );
              Navigator.pop(context);
            },
            child: Text(isPending ? 'Mark Resolved' : 'Set Pending'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(Announcement? announcement) {
    final isNew = announcement == null;
    final titleController = TextEditingController(
      text: announcement?.title ?? '',
    );
    final messageController = TextEditingController(
      text: announcement?.message ?? '',
    );
    bool isEditing = isNew;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isNew ? 'New Announcement' : 'Announcement Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                enabled: isEditing,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
                enabled: isEditing,
              ),
            ],
          ),
          actions: [
            if (!isNew && !isEditing) ...[
              TextButton(
                onPressed: () {
                  context.read<AdminInboxViewModel>().deleteRecord(
                    'announcements',
                    announcement.id,
                  );
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => setStateDialog(() => isEditing = true),
                child: const Text('Edit'),
              ),
            ],
            if (isEditing)
              ElevatedButton(
                onPressed: () async {
                  if (isNew) {
                    await context
                        .read<AdminInboxViewModel>()
                        .createAnnouncement(
                          titleController.text,
                          messageController.text,
                        );
                  } else {
                    await context
                        .read<AdminInboxViewModel>()
                        .updateAnnouncement(
                          announcement.id,
                          titleController.text,
                          messageController.text,
                        );
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminInboxViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Color of the active tab
          unselectedLabelColor: Colors.white70, // Color of the inactive tabs
          indicatorColor:
              Colors.white, // Color of the line under the active tab
          tabs: const [
            Tab(icon: Icon(Icons.person_search), text: 'Inquiries'),
            Tab(icon: Icon(Icons.build), text: 'Maintenance'),
            Tab(icon: Icon(Icons.apartment), text: 'Units'),
            Tab(icon: Icon(Icons.campaign), text: 'News'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton(
              onPressed: () => _showAnnouncementDialog(null),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(viewModel.inquiries, 'inquiries', 'Inquiry'),
                _buildList(
                  viewModel.maintenanceRequests,
                  'maintenance_requests',
                  'Maintenance',
                ),
                _buildList(viewModel.units, 'units', 'Unit'),
                _buildList(
                  viewModel.announcements,
                  'announcements',
                  'Announcement',
                ),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, String table, String type) {
    if (items.isEmpty) return const Center(child: Text('No data found.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String title = "";
        String subtitle = "";

        if (item is Inquiry) {
          title = item.name ?? 'New Inquiry';
          subtitle = item.message ?? '';
        } else if (item is MaintenanceRequest) {
          title = "${item.buildingName ?? ''} - ${item.unitNumber ?? ''}";
          subtitle = item.issueCategory ?? '';
        } else if (item is Unit) {
          title = "${item.building ?? ''} Unit ${item.unitCode ?? ''}";
          subtitle = "Status: ${item.status ?? 'Unknown'}";
        } else if (item is Announcement) {
          title = item.title ?? '';
          subtitle = item.message ?? '';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              if (item is Unit) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditUnitScreen(unit: item)),
                );
              } else if (item is Announcement) {
                _showAnnouncementDialog(item);
              } else {
                _showActionDialog(item, table, type);
              }
            },
          ),
        );
      },
    );
  }
}
