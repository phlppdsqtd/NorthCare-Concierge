import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'inquiry_screen.dart';
import 'maintenance_screen.dart';
import 'admin_inbox_screen.dart';
import 'available_units_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NorthCare Concierge', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apartment, size: 80, color: Colors.teal),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to D’ NorthGate, D’ NorthWay & NorthPoint Atrium',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                // AI Chatbot Button
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  label: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Ask our AI Concierge', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // View Available Units Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AvailableUnitsScreen()),
                    );
                  },
                  icon: const Icon(Icons.meeting_room),
                  label: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('View Available Rooms', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Inquiry Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InquiryScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_search),
                  label: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Submit Unit Inquiry', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Maintenance Button
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

                //const Spacer(), // Pushes the admin button to the bottom
                const Divider(),

                // Admin Access Button
                TextButton.icon(
                  onPressed: () {
                    // Show the password dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        final TextEditingController passwordController = TextEditingController();
                        // We use StatefulBuilder so we can update the error message inside the dialog
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('Admin Authentication'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Please enter the manager password:'),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true, // Hides the text like a password
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
                                    // HARDCODED PASSWORD FOR MVP: "northcare2026"
                                    if (passwordController.text == 'northcare2026') {
                                      Navigator.pop(dialogContext); // Close the dialog
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AdminInboxScreen()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Incorrect password!'),
                                          backgroundColor: Colors.red,
                                        )
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
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
                  label: const Text(
                    'Property Manager Login', 
                    style: TextStyle(color: Colors.grey)
                  ),
                ),
              
              ],
            ),
          ),
        )
      ),
    );
  }
}