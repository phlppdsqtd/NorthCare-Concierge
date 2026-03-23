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

  // Reusable password dialog for both Tenants and Admins
  Future<void> _showPasswordDialog(BuildContext context, String role, Widget destinationScreen) async {
    final passwordController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter ${role[0].toUpperCase()}${role.substring(1)} Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
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
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final input = passwordController.text.trim();
                    if (input.isEmpty) return;

                    try {
                      // Fetch the correct password from Supabase
                      final response = await Supabase.instance.client
                          .from('passcodes')
                          .select('code')
                          .eq('role', role)
                          .single();

                      if (response['code'] == input) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext); // Close dialog
                          // Navigate to destination
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
                  child: const Text('Login'),
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
      appBar: AppBar(
        title: const Text(
          'NorthCare Concierge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.apartment, size: 80, color: Colors.teal),
                const SizedBox(height: 24),

                const Text(
                  'Welcome to D’ NorthGate, D’ NorthWay & NorthPoint Atrium',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                // ================= AI BUTTON =================
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                  icon: const Icon(Icons.smart_toy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text(
                    'Ask our AI Concierge',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= AVAILABLE ROOMS =================
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AvailableUnitsScreen()),
                    );
                  },
                  icon: const Icon(Icons.meeting_room),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text(
                    'View Available Rooms',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // ================= INQUIRY =================
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InquiryScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_search),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text(
                    'Submit Unit Inquiry',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 28),

                // ================= ANNOUNCEMENTS =================
                TextButton.icon(
                  onPressed: () => _showPasswordDialog(context, 'tenant', const AnnouncementsScreen()),
                  icon: const Icon(Icons.campaign),
                  label: const Text('View Announcements (Tenants)'),
                ),

                const SizedBox(height: 16),

                // ================= MAINTENANCE =================
                TextButton.icon(
                  onPressed: () => _showPasswordDialog(context, 'tenant', const MaintenanceScreen()),
                  icon: const Icon(Icons.build),
                  label: const Text('Report Maintenance Issue (Tenants)'),
                ),

                const SizedBox(height: 16),
                const Divider(height: 32),

                // ================= ADMIN =================
                TextButton.icon(
                  onPressed: () => _showPasswordDialog(context, 'admin', const AdminInboxScreen()),
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
                  label: const Text(
                    'Property Manager Login',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}