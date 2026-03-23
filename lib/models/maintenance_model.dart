class MaintenanceRequest {
  final String id;
  final DateTime? createdAt;
  final String? buildingName;
  final String? unitNumber;
  final String? tenantName;
  final String? issueCategory;
  final String? description;
  final String? status;

  MaintenanceRequest({
    required this.id,
    this.createdAt,
    this.buildingName,
    this.unitNumber,
    this.tenantName,
    this.issueCategory,
    this.description,
    this.status,
  });

  // Converts Supabase data into a MaintenanceRequest Object
  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'].toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      buildingName: json['building_name'],
      unitNumber: json['unit_number'],
      tenantName: json['tenant_name'],
      issueCategory: json['issue_category'],
      description: json['description'],
      status: json['status'],
    );
  }
}
