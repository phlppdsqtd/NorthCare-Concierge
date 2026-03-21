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
  // Controllers for the fields seen in your Supabase 'units' table
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactController;
  late TextEditingController _occupancyController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.unit.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.unit.lastName ?? '',
    );
    _contactController = TextEditingController(
      text: widget.unit.contactNo ?? '',
    );
    _occupancyController = TextEditingController(
      text: widget.unit.occupancy?.toString() ?? '0',
    );
    _status = widget.unit.status ?? 'Available';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _occupancyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AdminInboxViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.unit.building} - ${widget.unit.unitCode}'),
        backgroundColor: Colors.teal.shade700,
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
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact #',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _occupancyController,
              decoration: const InputDecoration(
                labelText: 'Current Occupancy (Pax)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
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
                  // Map the controller values back to Supabase columns
                  await viewModel.updateUnit(widget.unit.id, {
                    'first_name': _firstNameController.text.trim(),
                    'last_name': _lastNameController.text.trim(),
                    'contact_no': _contactController.text.trim(),
                    'occupancy': int.tryParse(_occupancyController.text) ?? 0,
                    'status': _status,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit updated successfully'),
                      ),
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
