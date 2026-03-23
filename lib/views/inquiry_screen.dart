import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InquiryScreen extends StatefulWidget {
  final String? prefilledMessage; 

  const InquiryScreen({super.key, this.prefilledMessage});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  late final TextEditingController _messageController; 

  String? _selectedUnitType;
  final List<String> _unitTypes = ['Studio', '1-Bedroom', '2-Bedroom', 'Not Sure Yet'];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
          SnackBar(
            content: const Text('Inquiry submitted successfully! We will contact you soon.', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting inquiry: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Helper method for consistent input styling
  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal.shade600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Unit Inquiry', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Interested in renting?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill out the form below and our property manager will get back to you with availability and details.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words, // Added auto-capitalization for words
                decoration: _inputDecor('Full Name', Icons.person_outline),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                // Intentionally left out textCapitalization here for emails
                decoration: _inputDecor('Email or Phone Number', Icons.contact_phone_outlined),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your contact info' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: _inputDecor('Preferred Unit Type', Icons.meeting_room_outlined),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
                textCapitalization: TextCapitalization.sentences, // Added auto-capitalization for sentences
                maxLines: 4,
                decoration: _inputDecor('Questions or Preferences', Icons.chat_bubble_outline).copyWith(
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSubmitting ? null : _submitInquiry,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Inquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}