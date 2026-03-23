import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InquiryScreen extends StatefulWidget {
  final String? prefilledMessage; // <-- Add this to catch passed data

  const InquiryScreen({super.key, this.prefilledMessage});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  late final TextEditingController _messageController; // <-- Change to late

  String? _selectedUnitType;
  final List<String> _unitTypes = ['Studio', '1-Bedroom', '2-Bedroom', 'Not Sure Yet'];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the message box if a message was passed in!
    _messageController = TextEditingController(text: widget.prefilledMessage ?? '');
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('inquiries').insert({
        'name': _nameController.text.trim(),
        'contact_info': _contactController.text.trim(),
        'unit_type': _selectedUnitType ?? 'Not specified',
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry submitted successfully! We will contact you soon.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
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