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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Inquiry Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${inquiry.name ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Contact: ${inquiry.contactInfo ?? 'N/A'}'),
              const SizedBox(height: 4),
              Text('Unit Type: ${inquiry.unitType ?? 'N/A'}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPending ? Colors.orange.shade200 : Colors.green.shade200),
                ),
                child: Text(
                  'Status: ${inquiry.status?.toUpperCase() ?? 'UNKNOWN'}',
                  style: TextStyle(
                    color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(inquiry.message ?? 'No message provided.', style: const TextStyle(fontSize: 16)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isPending ? Colors.teal : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Maintenance Report', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isVerified ? Colors.green.shade200 : Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isVerified ? Icons.verified : Icons.warning_amber_rounded, size: 18, color: isVerified ? Colors.green.shade700 : Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      isVerified ? 'Tenant Verified' : 'Tenant Unverified',
                      style: TextStyle(
                        color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Reported By: ${request.tenantName ?? 'N/A'}'),
              const SizedBox(height: 4),
              Text('Location: ${request.buildingName ?? ''} - Unit ${request.unitNumber ?? ''}'),
              const SizedBox(height: 4),
              Text('Issue: ${request.issueCategory ?? 'N/A'}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: ${request.status?.toUpperCase() ?? 'UNKNOWN'}',
                  style: TextStyle(
                    color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(request.description ?? 'No description.', style: const TextStyle(fontSize: 16)), 
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isPending ? Colors.teal : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Unit Details', style: TextStyle(fontWeight: FontWeight.bold)),
            if (unit.status?.toLowerCase() != 'available')
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Clear Tenant?'),
                      content: const Text('This will remove the current tenant details and mark the unit as Available. Continue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
                  Text('Building: ${unit.building ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Unit Code: ${unit.unitCode ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Status: ${unit.status ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                  ),
                  const Divider(height: 24),
                  
                  const Text('Unit Specifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Type: ${unit.unitType ?? 'N/A'}'),
                  Text('Furnish: ${unit.furnish ?? 'N/A'}'),
                  Text('Restroom: ${unit.restroom ?? 'N/A'}'),
                  Text('Capacity: ${unit.capacity ?? 'N/A'} pax'),
                  Text('Curfew: ${unit.curfew ?? 'N/A'}'),
                  Text('Price: ₱${unit.priceLease ?? 'N/A'}'),
                  const Divider(height: 24),

                  const Text('Lease Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Term: ${unit.termLease ?? 'N/A'} Months'),
                  Text('Start Lease: ${unit.startLease ?? 'N/A'}'),
                  Text('End Lease: ${unit.endLease ?? 'N/A'}'),
                  const Divider(height: 24),
                  
                  const Text('Current Tenant Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  if (isVacant)
                    const Text('Vacant', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else ...[
                    Text('Name: $fullName', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Contact: ${unit.contact != null && unit.contact!.trim().isNotEmpty ? unit.contact : 'N/A'}'),
                    const SizedBox(height: 4),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditUnitScreen(unit: unit)),
              );
            },
            child: const Text('Edit Details'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isNew ? 'New Announcement' : 'Announcement Details', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                enabled: isEditing,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setStateDialog(() => isEditing = true),
                child: const Text('Edit'),
              ),
            ],
            if (isEditing)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        // backgroundColor: Colors.teal.shade700,
        // foregroundColor: Colors.white,
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is also white
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
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.person_search), text: 'Inquiry'),
            Tab(icon: Icon(Icons.build), text: 'Maintain'),
            Tab(icon: Icon(Icons.apartment), text: 'Units'),
            Tab(icon: Icon(Icons.campaign), text: 'Announce'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton.extended(
              onPressed: () => _showAnnouncementDialog(null),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.add),
              label: const Text('New'),
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
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No $type records found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
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
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
            ),
            trailing: isResolved 
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.green, size: 20),
                  ) 
                : const Icon(Icons.chevron_right, color: Colors.grey),
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