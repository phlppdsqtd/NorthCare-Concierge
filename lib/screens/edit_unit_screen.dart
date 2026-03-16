import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUnitScreen extends StatefulWidget {
  final Map<String, dynamic> unit;

  const EditUnitScreen({super.key, required this.unit});

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for Tenant Info
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactController;
  late TextEditingController _startLeaseController;
  late TextEditingController _endLeaseController;

  // Controllers for Unit Details
  late TextEditingController _priceController;
  late TextEditingController _occupancyController;
  
  String? _status;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing data
    _firstNameController = TextEditingController(text: widget.unit['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.unit['last_name'] ?? '');
    _contactController = TextEditingController(text: widget.unit['contact'] ?? '');
    _startLeaseController = TextEditingController(text: widget.unit['start_lease'] ?? '');
    _endLeaseController = TextEditingController(text: widget.unit['end_lease'] ?? '');
    
    _priceController = TextEditingController(text: widget.unit['price_lease']?.toString() ?? '');
    _occupancyController = TextEditingController(text: widget.unit['occupancy']?.toString() ?? '0');
    
    _status = widget.unit['status'];
  }

  // A helper function to wipe tenant data instantly
  void _clearTenantInfo() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _contactController.clear();
      _startLeaseController.clear();
      _endLeaseController.clear();
      _occupancyController.text = '0';
      _status = 'Available';
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('units').update({
        'first_name': _firstNameController.text.isEmpty ? null : _firstNameController.text,
        'last_name': _lastNameController.text.isEmpty ? null : _lastNameController.text,
        'contact': _contactController.text.isEmpty ? null : _contactController.text,
        'start_lease': _startLeaseController.text.isEmpty ? null : _startLeaseController.text,
        'end_lease': _endLeaseController.text.isEmpty ? null : _endLeaseController.text,
        'price_lease': int.tryParse(_priceController.text),
        'occupancy': int.tryParse(_occupancyController.text),
        'status': _status,
      }).eq('id', widget.unit['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return true to tell previous screen to refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Unit ${widget.unit['unit_code']}'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _clearTenantInfo,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade100),
            child: const Text('Clear Tenant'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Status & Price ---
              const Text('Unit Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: ['Available', 'Occupied'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _status = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price (₱)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // --- Tenant Info ---
              const Text('Tenant Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact #', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _startLeaseController, decoration: const InputDecoration(labelText: 'Start Lease (YYYY-MM-DD)', border: OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _endLeaseController, decoration: const InputDecoration(labelText: 'End Lease (YYYY-MM-DD)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _occupancyController, decoration: const InputDecoration(labelText: 'Current Occupancy (Pax)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}