// lib/services/chat_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  String _formatUnit(Map<String, dynamic> u) {
    return "Unit Code: ${u['unit_code']} | "
        "Building: ${u['building']} | "
        "Status: ${u['status']} | "
        "Type: ${u['unit_type']} | "
        "Capacity: ${u['capacity']} pax | "
        "Room size: ${u['room_size']} sqm | "
        "Furnishing: ${u['furnish']} | "
        "Restroom: ${u['restroom']} | "
        "Curfew: ${u['curfew']} | "
        "Price: ₱${u['price_lease']}/month";
  }

  Future<String> getUnits({
    String? status,
    String? unitType,
    String? furnish,
    String? restroom,
    String? building,
    int? minPrice,
    int? maxPrice,
    int? minCapacity,
    int? maxCapacity,
  }) async {
    var query = _client.from('units').select(
          'unit_code, building, unit_type, capacity, room_size, '
          'furnish, restroom, curfew, price_lease, status',
        );

    if (status != null)      query = query.eq('status', status);
    if (unitType != null)    query = query.ilike('unit_type', '%$unitType%');
    if (furnish != null)     query = query.ilike('furnish', '%$furnish%');
    if (restroom != null)    query = query.ilike('restroom', '%$restroom%');
    if (building != null)    query = query.ilike('building', '%$building%');
    if (minCapacity != null) query = query.gte('capacity', minCapacity);
    if (maxCapacity != null) query = query.lte('capacity', maxCapacity);
    if (minPrice != null)    query = query.gte('price_lease', minPrice);
    if (maxPrice != null)    query = query.lte('price_lease', maxPrice);

    final rows = await query;
    final list = rows as List;

    if (list.isEmpty) {
      return "DATABASE RESULT: 0 units found. No units matched your criteria. "
          "Do NOT invent or suggest any units.";
    }

    final header = "DATABASE RESULT: ${list.length} unit(s) found. "
        "List ALL of them exactly as shown — do not add, remove, or modify any:\n";
    return header + list.map((u) => _formatUnit(u)).join('\n');
  }

  Future<String> getAvailableUnits({
    String? unitType,
    String? furnish,
    String? restroom,
    String? building,
    int? minPrice,
    int? maxPrice,
    int? minCapacity,
  }) async {
    return getUnits(
      status:      'Available',
      unitType:    unitType,
      furnish:     furnish,
      restroom:    restroom,
      building:    building,
      minPrice:    minPrice,
      maxPrice:    maxPrice,
      minCapacity: minCapacity,
    );
  }

  Future<String> getUnitByCode(String unitCode) async {
    final row = await _client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, '
            'furnish, restroom, curfew, price_lease, status')
        .eq('unit_code', unitCode)
        .maybeSingle();

    if (row == null) {
      return "DATABASE RESULT: Unit $unitCode does not exist. "
          "Do NOT invent details for this unit code.";
    }
    return "DATABASE RESULT: 1 unit found.\n${_formatUnit(row)}";
  }

  Future<String> getUnitsByBuilding(String building) async {
    return getUnits(building: building);
  }

  Future<String> getAllUnits() async {
    return getUnits();
  }
}