import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'tenant'; // Defaults to changing the tenant password
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields', Colors.red);
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('New passwords do not match!', Colors.red);
      return;
    }
    if (newPassword.length < 6) {
      _showMessage('New password must be at least 6 characters long.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('passcodes')
          .select('code')
          .eq('role', _selectedRole)
          .single();

      if (response['code'] != oldPassword) {
        _showMessage('Incorrect old password.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      await Supabase.instance.client
          .from('passcodes')
          .update({'code': newPassword})
          .eq('role', _selectedRole);

      _showMessage('Successfully updated $_selectedRole password!', Colors.green);
      
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
    } catch (e) {
      _showMessage('Error updating password. Please try again.', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Modern input decoration helper
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal.shade700),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.teal, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Security Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        // backgroundColor: Colors.teal.shade700,
        // foregroundColor: Colors.white,
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is also white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, size: 64, color: Colors.teal),
            ),
            const SizedBox(height: 24),
            const Text(
              'Update App Passwords',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Securely update access codes for your users.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Role Selector
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: _buildInputDecoration('Which password to change?', Icons.badge),
              icon: const Icon(Icons.expand_more, color: Colors.teal),
              items: const [
                DropdownMenuItem(value: 'tenant', child: Text('Tenant Access Password')),
                DropdownMenuItem(value: 'admin', child: Text('Property Manager (Admin)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Old Password
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: _buildInputDecoration('Current Password', Icons.lock_clock),
            ),
            const SizedBox(height: 20),

            // New Password
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: _buildInputDecoration('New Password', Icons.lock_reset),
            ),
            const SizedBox(height: 20),

            // Confirm New Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _buildInputDecoration('Confirm New Password', Icons.check_circle_outline),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}