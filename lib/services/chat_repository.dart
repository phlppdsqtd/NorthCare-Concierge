// lib/services/chat_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  Future<String> getAvailableUnits() async {
    final rows = await _client
        .from('units')
        .select(
            'building, unit_code, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .eq('status', 'Available');

    if ((rows as List).isEmpty) return "No units are currently available.";

    return rows.map((u) {
      return "Unit ${u['unit_code']} at ${u['building']}: "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month, status: ${u['status']}";
    }).join('\n');
  }

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

  Future<String> getAllUnits() async {
    final rows = await _client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status');

    if ((rows as List).isEmpty) return "No units found.";

    return rows.map((u) {
      return "Unit ${u['unit_code']} at ${u['building']} (${u['status']}): "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month";
    }).join('\n');
  }
}