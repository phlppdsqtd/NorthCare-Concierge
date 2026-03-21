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

    // 1. Basic Validation
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
      // 2. Verify the old password from Supabase
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

      // 3. Update to the new password
      await Supabase.instance.client
          .from('passcodes')
          .update({'code': newPassword})
          .eq('role', _selectedRole);

      _showMessage('Successfully updated $_selectedRole password!', Colors.green);
      
      // Clear the text fields after success
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
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text(
              'Update App Passwords',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Role Selector
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Which password do you want to change?',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'tenant', child: Text('Tenant Access Password')),
                DropdownMenuItem(value: 'admin', child: Text('Property Manager (Admin) Password')),
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
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_clock),
              ),
            ),
            const SizedBox(height: 20),

            // New Password
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm New Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}