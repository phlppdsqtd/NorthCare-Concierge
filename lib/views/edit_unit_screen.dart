import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_inbox_viewmodel.dart';
import '../models/unit_model.dart';

class EditUnitScreen extends StatefulWidget {
  final Unit unit;

  const EditUnitScreen({super.key, required this.unit});

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactController;
  late TextEditingController _capacityController;
  late TextEditingController _occupancyController; // <-- Added Occupancy Controller
  late TextEditingController _termLeaseController;
  late TextEditingController _startLeaseController;
  late TextEditingController _endLeaseController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.unit.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.unit.lastName ?? '');
    _contactController = TextEditingController(text: widget.unit.contact ?? '');
    
    // Capacity & Occupancy
    _capacityController = TextEditingController(text: widget.unit.capacity?.toString() ?? 'N/A');
    _occupancyController = TextEditingController(text: widget.unit.occupancy?.toString() ?? '0'); // Default to 0
    
    // Term
    _termLeaseController = TextEditingController(text: widget.unit.termLease?.toString() ?? '12'); // Default to 12 if null
    
    // Dates
    _startLeaseController = TextEditingController(text: widget.unit.startLease ?? '');
    _endLeaseController = TextEditingController(text: widget.unit.endLease ?? '');
    
    _status = widget.unit.status ?? 'Available';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _capacityController.dispose();
    _occupancyController.dispose(); // <-- Dispose it
    _termLeaseController.dispose();
    _startLeaseController.dispose();
    _endLeaseController.dispose();
    super.dispose();
  }

  // --- Auto-Calculation Logic for Dates ---
  Future<void> _selectStartDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_startLeaseController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_startLeaseController.text);
      } catch (e) {
        // Fallback to now if parse fails
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        // Format YYYY-MM-DD
        _startLeaseController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        
        // Auto-calculate End Lease based on Term Months
        int term = int.tryParse(_termLeaseController.text) ?? 12; // fallback to 12 months
        // Add term months to the start date
        DateTime endDate = DateTime(picked.year, picked.month + term, picked.day);
        _endLeaseController.text = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AdminInboxViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.unit.building} - ${widget.unit.unitCode}'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tenant Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact #', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 30),
            const Text(
              "Lease & Capacity Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            
            // Read-Only & Editable Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityController,
                    enabled: false, // Not editable
                    decoration: const InputDecoration(labelText: 'Capacity (Max)', border: OutlineInputBorder(), filled: true),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _occupancyController, // <-- Editable Occupancy
                    decoration: const InputDecoration(labelText: 'Current Occupancy', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _termLeaseController,
              enabled: false, // Not editable
              decoration: const InputDecoration(labelText: 'Term (Months)', border: OutlineInputBorder(), filled: true),
            ),
            const SizedBox(height: 15),
            
            // Date Selection
            TextField(
              controller: _startLeaseController,
              readOnly: true, // Only allow DatePicker to modify this
              decoration: InputDecoration(
                labelText: 'Start Lease (YYYY-MM-DD)', 
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectStartDate(context),
                ),
              ),
              onTap: () => _selectStartDate(context),
            ),
            const SizedBox(height: 15),
            
            // Auto-Calculated End Date
            TextField(
              controller: _endLeaseController,
              enabled: false, // Auto-calculated, not manually editable
              decoration: const InputDecoration(
                labelText: 'End Lease (Auto-Calculated)', 
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Unit Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                'Available',
                'Occupied',
                'Maintenance',
                'Reserved',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                ),
                onPressed: () async {
                  await viewModel.updateUnit(widget.unit.id, {
                    'first_name': _firstNameController.text.trim(),
                    'last_name': _lastNameController.text.trim(),
                    'contact': _contactController.text.trim(),
                    'occupancy': int.tryParse(_occupancyController.text.trim()) ?? 0, // <-- Parse to integer for DB
                    'start_lease': _startLeaseController.text.trim(),
                    'end_lease': _endLeaseController.text.trim(),
                    'status': _status,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unit updated successfully')),
                    );
                  }
                },
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}