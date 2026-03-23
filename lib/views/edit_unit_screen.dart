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
  late TextEditingController _occupancyController; 
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
    
    _capacityController = TextEditingController(text: widget.unit.capacity?.toString() ?? 'N/A');
    _occupancyController = TextEditingController(text: widget.unit.occupancy?.toString() ?? '0'); 
    
    _termLeaseController = TextEditingController(text: widget.unit.termLease?.toString() ?? '12'); 
    
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
    _occupancyController.dispose(); 
    _termLeaseController.dispose();
    _startLeaseController.dispose();
    _endLeaseController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_startLeaseController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_startLeaseController.text);
      } catch (e) {
        // Fallback
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal.shade700),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startLeaseController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        
        int term = int.tryParse(_termLeaseController.text) ?? 12; 
        DateTime endDate = DateTime(picked.year, picked.month + term, picked.day);
        _endLeaseController.text = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  InputDecoration _inputDecor(String label, IconData icon, {bool isReadOnly = false}) {
    return InputDecoration(
      labelText: label,
      // Removed isDense to let the fields breathe normally again
      prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey.shade400 : Colors.teal.shade600),
      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AdminInboxViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          '${widget.unit.building} - ${widget.unit.unitCode}', 
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Status Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.analytics_outlined, color: Colors.teal.shade700, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _inputDecor('Unit Status', Icons.label_outline),
                        items: ['Available', 'Occupied']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w500))))
                            .toList(),
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Kept the shrunk gap between cards
            const SizedBox(height: 8),

            // Tenant Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.grey.shade700, size: 22),
                        const SizedBox(width: 8),
                        const Text("Tenant Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // First Name and Last Name combined into a Row to save vertical space
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _firstNameController,
                            decoration: _inputDecor('First Name', Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lastNameController,
                            decoration: _inputDecor('Last Name', Icons.badge_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Increased breathing room
                    TextField(
                      controller: _contactController,
                      decoration: _inputDecor('Contact Number', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            
            // Kept the shrunk gap between cards
            const SizedBox(height: 8),

            // Lease & Capacity Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: Colors.grey.shade700, size: 22),
                        const SizedBox(width: 8),
                        const Text("Lease & Capacity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _capacityController,
                            enabled: false, 
                            decoration: _inputDecor('Capacity', Icons.groups_outlined, isReadOnly: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _occupancyController, 
                            decoration: _inputDecor('Occupancy', Icons.person_add_alt_1_outlined),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Increased breathing room
                    TextField(
                      controller: _termLeaseController,
                      enabled: false, 
                      decoration: _inputDecor('Term (Months)', Icons.schedule_outlined, isReadOnly: true),
                    ),
                    const SizedBox(height: 16), // Increased breathing room
                    TextField(
                      controller: _startLeaseController,
                      readOnly: true, 
                      decoration: _inputDecor('Start Lease', Icons.calendar_today_outlined).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.edit_calendar, color: Colors.teal.shade600),
                          onPressed: () => _selectStartDate(context),
                        ),
                      ),
                      onTap: () => _selectStartDate(context),
                    ),
                    const SizedBox(height: 16), // Increased breathing room
                    TextField(
                      controller: _endLeaseController,
                      enabled: false, 
                      decoration: _inputDecor('End Lease (Auto)', Icons.event_available_outlined, isReadOnly: true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await viewModel.updateUnit(widget.unit.id, {
                    'first_name': _firstNameController.text.trim(),
                    'last_name': _lastNameController.text.trim(),
                    'contact': _contactController.text.trim(),
                    'occupancy': int.tryParse(_occupancyController.text.trim()) ?? 0, 
                    'start_lease': _startLeaseController.text.trim(),
                    'end_lease': _endLeaseController.text.trim(),
                    'status': _status,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Unit updated successfully', style: TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.teal.shade800,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}