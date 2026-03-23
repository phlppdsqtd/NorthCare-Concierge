import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inquiry_screen.dart';

class AvailableUnitsScreen extends StatefulWidget {
  const AvailableUnitsScreen({super.key});

  @override
  State<AvailableUnitsScreen> createState() => _AvailableUnitsScreenState();
}

class _AvailableUnitsScreenState extends State<AvailableUnitsScreen> {
  final Future<List<Map<String, dynamic>>> _availableUnits = Supabase.instance.client
      .from('units')
      .select()
      .eq('status', 'Available')
      .order('price_lease', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Softer background
      appBar: AppBar(
        title: const Text('Available Units', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _availableUnits,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No units are currently available.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  Text('Check back soon!', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final units = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // '${unit['building']} - Unit ${unit['unit_code']}',
                              '${unit['building']} - ${unit['unit_code']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text('Available', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.king_bed_outlined, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text('${unit['unit_type']} | ${unit['room_size']} sqm | ${unit['capacity']} pax', 
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
                            Text('Furnishing: ${unit['furnish']} • Lease: ${unit['term_lease'] ?? '12'} mo', 
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Bathroom: ${unit['restroom']} • Curfew: ${unit['curfew']}', 
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monthly Rate', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                              Text(
                                '₱${unit['price_lease']}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.teal.shade700),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.mail_outline, size: 18),
                            label: const Text('Inquire', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => InquiryScreen(
                                    prefilledMessage: 'Hi, I am interested in ${unit['building']} - Unit ${unit['unit_code']}. Is this still available?',
                                  )
                                )
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}