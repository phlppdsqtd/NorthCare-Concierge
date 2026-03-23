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

  // ================= INQUIRY DIALOG =================
  void _showInquiryDetails(Inquiry inquiry) {
    final isPending = inquiry.status == 'pending';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inquiry Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${inquiry.name ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Contact: ${inquiry.contactInfo ?? 'N/A'}'),
              Text('Unit Type: ${inquiry.unitType ?? 'N/A'}'),
              const SizedBox(height: 16),
              Text('Status: ${inquiry.status?.toUpperCase() ?? 'UNKNOWN'}'),
              const Divider(),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(inquiry.message ?? 'No message provided.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().deleteRecord('inquiries', inquiry.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().toggleStatus(
                'inquiries',
                inquiry.id,
                inquiry.status ?? 'pending',
              );
              Navigator.pop(context);
            },
            child: Text(isPending ? 'Mark Resolved' : 'Set Pending'),
          ),
        ],
      ),
    );
  }

  // ================= MAINTENANCE DIALOG =================
  void _showMaintenanceDetails(MaintenanceRequest request, AdminInboxViewModel viewModel) {
    final isPending = request.status == 'pending';
    
    bool isVerified = false;
    try {
      final matchingUnit = viewModel.units.firstWhere(
        (u) => u.unitCode == request.unitNumber,
      );
      
      if (request.tenantName != null) {
        String unitTenantFullName = "${matchingUnit.firstName ?? ''} ${matchingUnit.lastName ?? ''}".trim();
        if (unitTenantFullName.toLowerCase() == request.tenantName!.toLowerCase() && unitTenantFullName.isNotEmpty) {
          isVerified = true;
        }
      }
    } catch (e) {
      isVerified = false;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Maintenance Report')),
            // Icon(
            //   isVerified ? Icons.verified : Icons.warning_amber_rounded,
            //   color: isVerified ? Colors.green : Colors.orange,
            // ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isVerified ? '✓ Tenant Verified' : '⚠ Tenant Unverified',
                  style: TextStyle(
                    color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Reported By: ${request.tenantName ?? 'N/A'}'),
              Text('Location: ${request.buildingName ?? ''} - Unit ${request.unitNumber ?? ''}'),
              Text('Issue: ${request.issueCategory ?? 'N/A'}'),
              const SizedBox(height: 16),
              Text('Status: ${request.status?.toUpperCase() ?? 'UNKNOWN'}'),
              const Divider(),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(request.description ?? 'No description.'), 
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().deleteRecord('maintenance_requests', request.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminInboxViewModel>().toggleStatus(
                'maintenance_requests',
                request.id,
                request.status ?? 'pending',
              );
              Navigator.pop(context);
            },
            child: Text(isPending ? 'Mark Resolved' : 'Set Pending'),
          ),
        ],
      ),
    );
  }

  // ================= UNIT DIALOG =================
  void _showUnitDetails(Unit unit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Unit Details'),
            // Only show clear button if unit is NOT available
            if (unit.status?.toLowerCase() != 'available')
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('Clear Tenant?'),
                      content: const Text('This will remove the current tenant details and mark the unit as Available. Continue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () {
                            context.read<AdminInboxViewModel>().clearUnitTenant(unit.id);
                            Navigator.pop(confirmContext);
                            Navigator.pop(dialogContext); 
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    )
                  );
                },
                icon: const Icon(Icons.person_off, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final String fullName = "${unit.firstName ?? ''} ${unit.lastName ?? ''}".trim();
              final bool isVacant = fullName.isEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Building: ${unit.building ?? 'N/A'}'),
                  Text('Unit Code: ${unit.unitCode ?? 'N/A'}'),
                  Text('Status: ${unit.status ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Divider(),
                  
                  // Expanded Unit Info
                  const Text('Unit Specifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Type: ${unit.unitType ?? 'N/A'}'),
                  Text('Furnish: ${unit.furnish ?? 'N/A'}'),
                  Text('Restroom: ${unit.restroom ?? 'N/A'}'),
                  Text('Capacity: ${unit.capacity ?? 'N/A'} pax'),
                  Text('Curfew: ${unit.curfew ?? 'N/A'}'),
                  Text('Price: ₱${unit.priceLease ?? 'N/A'}'),
                  const Divider(),

                  const Text('Lease Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Term: ${unit.termLease ?? 'N/A'} Months'),
                  Text('Start Lease: ${unit.startLease ?? 'N/A'}'),
                  Text('End Lease: ${unit.endLease ?? 'N/A'}'),
                  const Divider(),
                  
                  const Text('Current Tenant Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  
                  if (isVacant)
                    const Text('Vacant', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else ...[
                    Text('Name: $fullName'),
                    Text('Contact: ${unit.contact != null && unit.contact!.trim().isNotEmpty ? unit.contact : 'N/A'}'),
                    Text('Occupancy: ${unit.occupancy ?? 'N/A'}'),
                  ],
                ],
              );
            }
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditUnitScreen(unit: unit)),
              );
            },
            child: const Text('Edit Full Details'),
          ),
        ],
      ),
    );
  }

  // ================= ANNOUNCEMENT DIALOG =================
  void _showAnnouncementDialog(Announcement? announcement) {
    final isNew = announcement == null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final messageController = TextEditingController(text: announcement?.message ?? '');
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
                  context.read<AdminInboxViewModel>().deleteRecord('announcements', announcement.id);
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
                    await context.read<AdminInboxViewModel>().createAnnouncement(
                          titleController.text,
                          messageController.text,
                        );
                  } else {
                    await context.read<AdminInboxViewModel>().updateAnnouncement(
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person_search), text: 'Inquiry'),
            Tab(icon: Icon(Icons.build), text: 'Maintain'),
            Tab(icon: Icon(Icons.apartment), text: 'Units'),
            Tab(icon: Icon(Icons.campaign), text: 'Announce'),
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
                _buildList(viewModel.maintenanceRequests, 'maintenance_requests', 'Maintenance'),
                _buildList(viewModel.units, 'units', 'Unit'),
                _buildList(viewModel.announcements, 'announcements', 'Announcement'),
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
        bool isResolved = false;

        if (item is Inquiry) {
          title = item.name ?? 'New Inquiry';
          subtitle = item.message ?? '';
          isResolved = item.status?.toLowerCase() == 'resolved';
        } else if (item is MaintenanceRequest) {
          title = "${item.buildingName ?? ''} - ${item.unitNumber ?? ''}";
          subtitle = item.issueCategory ?? '';
          isResolved = item.status?.toLowerCase() == 'resolved';
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
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            // Show Green Checkmark if resolved
            trailing: isResolved 
                ? const Icon(Icons.check_circle, color: Colors.green) 
                : null,
            onTap: () {
              if (item is Unit) {
                _showUnitDetails(item);
              } else if (item is Inquiry) {
                _showInquiryDetails(item);
              } else if (item is MaintenanceRequest) {
                _showMaintenanceDetails(item, context.read<AdminInboxViewModel>());
              } else if (item is Announcement) {
                _showAnnouncementDialog(item);
              }
            },
          ),
        );
      },
    );
  }
}