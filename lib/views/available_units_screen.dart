import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inquiry_screen.dart'; // So they can immediately inquire!

class AvailableUnitsScreen extends StatefulWidget {
  const AvailableUnitsScreen({super.key});

  @override
  State<AvailableUnitsScreen> createState() => _AvailableUnitsScreenState();
}

class _AvailableUnitsScreenState extends State<AvailableUnitsScreen> {
  // Fetch ONLY units where status is 'Available'
  final Future<List<Map<String, dynamic>>> _availableUnits = Supabase.instance.client
      .from('units')
      .select()
      .eq('status', 'Available')
      .order('price_lease', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Units'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _availableUnits,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No units are currently available. Check back soon!'));
          }

          final units = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${unit['building']} - Unit ${unit['unit_code']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Available', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('${unit['unit_type']} | ${unit['room_size']} sqm | ${unit['capacity']} pax', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      // Added Term Lease beside Furnishing
                      Text('Furnishing: ${unit['furnish']} | Lease: ${unit['term_lease'] ?? '12'} months', style: const TextStyle(color: Colors.grey)),
                      Text('Bathroom: ${unit['restroom']} | Curfew: ${unit['curfew']}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₱${unit['price_lease']} / month',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: () {
                              // UPDATED: Send them straight to the inquiry form WITH context!
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => InquiryScreen(
                                    prefilledMessage: 'Hi, I am interested in ${unit['building']} - Unit ${unit['unit_code']}. Is this still available?',
                                  )
                                )
                              );
                            },
                            child: const Text('Inquire Now'),
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