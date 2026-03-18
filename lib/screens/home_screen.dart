import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'inquiry_screen.dart';
import 'maintenance_screen.dart';
import 'admin_inbox_screen.dart';
import 'available_units_screen.dart';
import 'announcements_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

                // ================= ANNOUNCEMENTS =================
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text(
                    'View Announcements',
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

                // ================= MAINTENANCE =================
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
                    );
                  },
                  icon: const Icon(Icons.build),
                  label: const Text('Report Maintenance Issue (Tenants)'),
                ),

                const SizedBox(height: 16),
                const Divider(height: 32),

                // ================= ADMIN =================
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        final TextEditingController passwordController = TextEditingController();

                        return AlertDialog(
                          title: const Text('Admin Authentication'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Please enter the manager password:'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Password',
                                ),
                              ),
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
                              onPressed: () {
                                if (passwordController.text == 'northcare2026') {
                                  Navigator.pop(dialogContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AdminInboxScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Incorrect password!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Login'),
                            ),
                          ],
                        );
                      },
                    );
                  },
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