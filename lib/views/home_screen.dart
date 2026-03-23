import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'inquiry_screen.dart';
import 'maintenance_screen.dart';
import 'admin_inbox_screen.dart';
import 'available_units_screen.dart';
import 'announcements_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Reusable password dialog (Modernized slightly with rounded corners)
  Future<void> _showPasswordDialog(BuildContext context, String role, Widget destinationScreen) async {
    final passwordController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                '${role[0].toUpperCase()}${role.substring(1)} Verification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please enter the access code to continue.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Access Code',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final input = passwordController.text.trim();
                    if (input.isEmpty) return;

                    try {
                      final response = await Supabase.instance.client
                          .from('passcodes')
                          .select('code')
                          .eq('role', role)
                          .single();

                      if (response['code'] == input) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => destinationScreen),
                          );
                        }
                      } else {
                        setState(() => errorMessage = 'Incorrect password. Please try again.');
                      }
                    } catch (e) {
                      setState(() => errorMessage = 'Error verifying password.');
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apartment, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'NorthCare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'Welcome home.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'How can we help you today?',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prominent AI Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                        border: Border.all(color: Colors.teal.shade100, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.smart_toy, color: Colors.teal.shade700, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ask AI Concierge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Instant answers 24/7', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.teal.shade300, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 2x2 Grid for Actions
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.meeting_room_outlined,
                        title: 'Available\nUnits',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailableUnitsScreen())),
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.person_search_outlined,
                        title: 'Submit\nInquiry',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InquiryScreen())),
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.campaign_outlined,
                        title: 'Community\nUpdates',
                        color: Colors.purple,
                        onTap: () => _showPasswordDialog(context, 'tenant', const AnnouncementsScreen()),
                        isSecured: true,
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.build_circle_outlined,
                        title: 'Report\nIssue',
                        color: Colors.red,
                        onTap: () => _showPasswordDialog(context, 'tenant', const MaintenanceScreen()),
                        isSecured: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Admin Login at the very bottom
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showPasswordDialog(context, 'admin', const AdminInboxScreen()),
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.grey, size: 18),
                      label: const Text(
                        'Property Manager Login',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to generate clean, uniform cards
  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isSecured = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (isSecured)
                  Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}