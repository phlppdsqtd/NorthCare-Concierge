import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text input
  final _tenantNameController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dropdown states and options
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

  // HELPER FUNCTION: Converts "philipp dee" to "Philipp Dee"
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
      // Format the data right before inserting
      final formattedUnitNumber = _unitNumberController.text.trim().toUpperCase();
      final formattedTenantName = _toTitleCase(_tenantNameController.text.trim());

      // Insert the data into the 'maintenance_requests' table
      await Supabase.instance.client.from('maintenance_requests').insert({
        'building_name': _selectedBuilding,
        'unit_number': formattedUnitNumber,
        'tenant_name': formattedTenantName,
        'issue_category': _selectedCategory,
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to Home Screen
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $error'),
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
    _tenantNameController.dispose();
    _unitNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
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
                'Maintenance Request',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kindly provide details about the issue so our caretaker can assist you promptly.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Added Verification Instruction Here
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please enter your exact unit code, first name, and last name to verify that the request is valid.',
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Building Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Building',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                ),
                value: _selectedBuilding,
                items: _buildings.map((building) {
                  return DropdownMenuItem(value: building, child: Text(building));
                }).toList(),
                onChanged: (value) => setState(() => _selectedBuilding = value),
                validator: (value) => value == null ? 'Please select your building' : null,
              ),
              const SizedBox(height: 16),

              // Unit Number and Tenant Name Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Unit #',
                        border: OutlineInputBorder(),
                      ),
                      // Bonus tip: textCapitalization gives the keyboard a hint to uppercase!
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _tenantNameController,
                      decoration: const InputDecoration(
                        labelText: 'First and Last Name',
                        border: OutlineInputBorder(),
                      ),
                      // Hinting the keyboard to capitalize words
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Issue Category Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Issue Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue in detail...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences, // Start sentences with a capital letter
                validator: (value) => value == null || value.isEmpty ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitMaintenanceRequest,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}