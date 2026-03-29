// lib/services/chat_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  /// General method: fetch units with optional filters
  Future<String> getUnits({Map<String, dynamic>? filters}) async {
    var query = _client.from('units').select(
      'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status',
    );

    // Apply filters dynamically
    filters?.forEach((key, value) {
      if (value == null) return;
      
      if (key == 'furnish' && value == 'Any Furnished') {
        // Exclude bare units if they ask for general "furnished"
        query = query.neq('furnish', 'Unfurnished');
        
      } else if (key == 'min_price') {
        // Handle minimum price (e.g., "above 15k")
        query = query.gte('price_lease', value);
        
      } else if (key == 'max_price') {
        // Handle maximum price (e.g., "under 15k")
        query = query.lte('price_lease', value);
        
      } else if (key == 'capacity') {
        // Find units that fit AT LEAST the requested capacity
        query = query.gte('capacity', value);
        
      } else {
        // Standard exact match for everything else (strings, bools, etc.)
        query = query.eq(key, value);
      }
    });

    final rows = await query;

    if ((rows as List).isEmpty) return "No units matched your criteria.";

    return rows.map((u) {
      return "Unit ${u['unit_code']} at ${u['building']} (${u['status']}): "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month";
    }).join('\n');
  }

  /// Simple: all available units
  Future<String> getAvailableUnits() async {
    return getUnits(filters: {"status": "Available"});
  }

  /// Simple: unit by code
  Future<String> getUnitByCode(String unitCode) async {
    final row = await _client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .eq('unit_code', unitCode)
        .maybeSingle();

    if (row == null) return "No unit found with code $unitCode.";

    return "Unit ${row['unit_code']} at ${row['building']}: "
        "${row['unit_type']}, capacity ${row['capacity']}, "
        "room size ${row['room_size']} sqm, furnishing: ${row['furnish']}, "
        "restroom: ${row['restroom']}, curfew: ${row['curfew']}, "
        "₱${row['price_lease']}/month, status: ${row['status']}";
  }

  /// Simple: units by building
  Future<String> getUnitsByBuilding(String building) async {
    final rows = await _client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .ilike('building', '%$building%');

    if ((rows as List).isEmpty) {
      return "No units found for building matching '$building'.";
    }

    return rows.map((u) {
      return "Unit ${u['unit_code']} (${u['status']}): "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month";
    }).join('\n');
  }

  /// Simple: all units
  Future<String> getAllUnits() async {
    return getUnits();
  }
}