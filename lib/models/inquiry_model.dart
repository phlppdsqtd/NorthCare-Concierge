class Inquiry {
  final String id;
  final DateTime? createdAt;
  final String? name;
  final String? contactInfo;
  final String? unitType;
  final String? message;
  final String? status;

  Inquiry({
    required this.id,
    this.createdAt,
    this.name,
    this.contactInfo,
    this.unitType,
    this.message,
    this.status,
  });

  // Converts Supabase data into an Inquiry Object
  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'].toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      name: json['name'],
      contactInfo: json['contact_info'],
      unitType: json['unit_type'],
      message: json['message'],
      status: json['status'],
    );
  }
}
