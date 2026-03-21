class Unit {
  final String id;
  final String? building;
  final String? unitCode;
  final String? status;
  final double? price;
  final String? firstName;
  final String? lastName;
  final String? contactNo;
  final String? startLease;
  final String? endLease;
  final int? occupancy;

  Unit({
    required this.id,
    this.building,
    this.unitCode,
    this.status,
    this.price,
    this.firstName,
    this.lastName,
    this.contactNo,
    this.startLease,
    this.endLease,
    this.occupancy,
  });

  // This converts the Supabase Map data into a Unit Object
  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'].toString(),
      building: json['building'],
      unitCode: json['unit_code'],
      status: json['status'],
      price: (json['price'] as num?)?.toDouble(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      contactNo: json['contact_no'],
      startLease: json['start_lease'],
      endLease: json['end_lease'],
      occupancy: json['occupancy'] as int?,
    );
  }
}
