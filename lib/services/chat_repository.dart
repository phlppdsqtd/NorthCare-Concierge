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

    // Apply filters only if provided
    if (status != null) query = query.eq('status', status);
    if (unitType != null) query = query.ilike('unit_type', '%$unitType%');
    if (furnish != null) query = query.ilike('furnish', '%$furnish%');
    if (restroom != null) query = query.ilike('restroom', '%$restroom%');
    if (building != null) query = query.ilike('building', '%$building%');
    if (minCapacity != null) query = query.gte('capacity', minCapacity);
    if (maxCapacity != null) query = query.lte('capacity', maxCapacity);

    // 👉 Apply price filters once here
    if (minPrice != null) query = query.gte('price_lease', minPrice);
    if (maxPrice != null) query = query.lte('price_lease', maxPrice);

    final rows = await query;

    // Debugging info
    print('Query parameters: status=$status, unitType=$unitType, furnish=$furnish, restroom=$restroom, building=$building, minPrice=$minPrice, maxPrice=$maxPrice, minCapacity=$minCapacity, maxCapacity=$maxCapacity');
    print('Rows returned: ${rows.length}');
    if (rows.isNotEmpty) print('First row: ${rows.first}');

    if ((rows as List).isEmpty) return "No units matched your criteria.";

    return rows.map((u) => _formatUnit(u)).join('\n');
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
      status: 'Available',   // Only show units marked Available
      unitType: unitType,
      furnish: furnish,
      restroom: restroom,
      building: building,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minCapacity: minCapacity,
    );
  }

  Future<String> getUnitByCode(String unitCode) async {
    final row = await _client
        .from('units')
        .select(
          'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status',
        )
        .eq('unit_code', unitCode)
        .maybeSingle();

    print('getUnitByCode: unitCode=$unitCode, row=$row');

    if (row == null) return "No unit found with code $unitCode.";

    return _formatUnit(row);
  }

  Future<String> getUnitsByBuilding(String building) async {
    return getUnits(building: building);
  }

  Future<String> getAllUnits() async {
    return getUnits();
  }
}
