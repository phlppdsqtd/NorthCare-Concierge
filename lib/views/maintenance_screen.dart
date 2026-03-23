import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tenantNameController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedBuilding;
  final List<String> _buildings = [
    'D’ NorthGate',
    'D’ NorthWay',
    'NorthPoint Atrium'
  ];

  String? _selectedCategory;
  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Appliance / AC',
    'Pest Control',
    'Other'
  ];

  bool _isSubmitting = false;

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _submitMaintenanceRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formattedUnitNumber = _unitNumberController.text.trim().toUpperCase();
      final formattedTenantName = _toTitleCase(_tenantNameController.text.trim());

      await Supabase.instance.client.from('maintenance_requests').insert({
        'building_name': _selectedBuilding,
        'unit_number': formattedUnitNumber,
        'tenant_name': formattedTenantName,
        'issue_category': _selectedCategory,
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maintenance request submitted successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
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
            content: Text('Error submitting request: $error'),
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
    _tenantNameController.dispose();
    _unitNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Helper method for consistent input styling
  InputDecoration _inputDecor(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal.shade600) : null,
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
        title: const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.w600)),
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
                'Maintenance Request',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Kindly provide details about the issue so our caretaker can assist you promptly.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              
              // Modernized Verification Instruction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please enter your exact unit code, first name, and last name to verify that the request is valid.',
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              DropdownButtonFormField<String>(
                decoration: _inputDecor('Building', icon: Icons.apartment_outlined),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                value: _selectedBuilding,
                items: _buildings.map((building) {
                  return DropdownMenuItem(value: building, child: Text(building));
                }).toList(),
                onChanged: (value) => setState(() => _selectedBuilding = value),
                validator: (value) => value == null ? 'Please select your building' : null,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitNumberController,
                      decoration: _inputDecor('Unit #'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _tenantNameController,
                      decoration: _inputDecor('First & Last Name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: _inputDecor('Issue Category', icon: Icons.build_circle_outlined),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecor('Describe the issue in detail...', icon: Icons.description_outlined).copyWith(
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences, 
                validator: (value) => value == null || value.isEmpty ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSubmitting ? null : _submitMaintenanceRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}