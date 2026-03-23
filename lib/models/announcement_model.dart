class Announcement {
  final String id;
  final String? title;
  final String? message;
  final DateTime? createdAt;

  Announcement({required this.id, this.title, this.message, this.createdAt});

  // Converts Supabase data into an Announcement Object
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title'],
      message: json['message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
