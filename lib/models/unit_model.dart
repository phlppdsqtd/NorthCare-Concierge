class Unit {
  final String id;
  final String? building;
  final String? unitCode;
  final String? firstName;
  final String? lastName;
  final String? contact;
  final int? termLease;
  final int? occupancy;
  final int? capacity;
  final int? roomSize;
  final String? unitType;
  final String? furnish;
  final String? restroom;
  final String? curfew;
  final double? priceLease;
  final String? startLease;
  final String? endLease;
  final String? status;

  Unit({
    required this.id,
    this.building,
    this.unitCode,
    this.firstName,
    this.lastName,
    this.contact,
    this.termLease,
    this.occupancy,
    this.capacity,
    this.roomSize,
    this.unitType,
    this.furnish,
    this.restroom,
    this.curfew,
    this.priceLease,
    this.startLease,
    this.endLease,
    this.status,
  });

  // Converts the Supabase Map data into a Unit Object
  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'].toString(),
      building: json['building']?.toString(),
      unitCode: json['unit_code']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      contact: json['contact']?.toString(),
      
      // Integers
      termLease: json['term_lease'] as int?,
      occupancy: json['occupancy'] as int?,
      capacity: json['capacity'] as int?,
      roomSize: json['room_size'] as int?,
      
      // Strings
      unitType: json['unit_type']?.toString(),
      furnish: json['furnish']?.toString(),
      restroom: json['restroom']?.toString(),
      curfew: json['curfew']?.toString(),
      
      // Safe parsing for numeric types (in case they come in as int or double)
      priceLease: (json['price_lease'] as num?)?.toDouble(),
      
      // Dates (handled as strings in Dart until parsed)
      startLease: json['start_lease']?.toString(),
      endLease: json['end_lease']?.toString(),
      status: json['status']?.toString(),
    );
  }
}