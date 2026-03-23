import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  // A key to validate our form
  final _formKey = GlobalKey<FormState>();

  // Controllers to grab the text the user types
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();

  // Dropdown state
  String? _selectedUnitType;
  final List<String> _unitTypes = ['Studio', '1-Bedroom', '2-Bedroom', 'Not Sure Yet'];

  // Loading state to disable the button while submitting
  bool _isSubmitting = false;

  // The function that pushes data to your Supabase database
  Future<void> _submitInquiry() async {
    // 1. Validate the form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 2. Insert the data into the 'inquiries' table
      await Supabase.instance.client.from('inquiries').insert({
        'name': _nameController.text.trim(),
        'contact_info': _contactController.text.trim(),
        'unit_type': _selectedUnitType ?? 'Not specified',
        'message': _messageController.text.trim(),
        // Note: 'status' defaults to 'pending' and 'created_at' is handled automatically by Supabase!
      });

      // 3. Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry submitted successfully! We will contact you soon.'),
            backgroundColor: Colors.green,
          ),
        );
        // 4. Send the user back to the Home Screen
        Navigator.pop(context);
      }
    } catch (error) {
      // Handle any errors (like no internet connection)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting inquiry: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Inquiry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Interested in renting?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill out the form below and our property manager will get back to you with availability and details.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Contact Info Field
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Email or Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_phone),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your contact info' : null,
              ),
              const SizedBox(height: 16),

              // Unit Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Preferred Unit Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                value: _selectedUnitType,
                items: _unitTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnitType = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a unit type' : null,
              ),
              const SizedBox(height: 16),

              // Message / Questions Field
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Questions or Preferences (e.g., Target move-in date)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitInquiry,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Inquiry', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}