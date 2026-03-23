import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importing your new models
import '../models/unit_model.dart';
import '../models/inquiry_model.dart';
import '../models/maintenance_model.dart';
import '../models/announcement_model.dart';

class AdminInboxViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Type-safe lists using your new Models
  List<Inquiry> inquiries = [];
  List<MaintenanceRequest> maintenanceRequests = [];
  List<Unit> units = [];
  List<Announcement> announcements = [];
  bool isLoading = false;

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();
    try {
      // 1. Fetch Inquiries
      final inquiryResponse = await _supabase
          .from('inquiries')
          .select()
          .order('created_at', ascending: false);
      inquiries = (inquiryResponse as List)
          .map((data) => Inquiry.fromJson(data))
          .toList();

      // 2. Fetch Maintenance
      final maintenanceResponse = await _supabase
          .from('maintenance_requests')
          .select()
          .order('created_at', ascending: false);
      maintenanceRequests = (maintenanceResponse as List)
          .map((data) => MaintenanceRequest.fromJson(data))
          .toList();

      // 3. Fetch Units
      final unitResponse = await _supabase
          .from('units')
          .select()
          .order('building', ascending: true)
          .order('unit_code', ascending: true);
      units = (unitResponse as List)
          .map((data) => Unit.fromJson(data))
          .toList();

      // 4. Fetch Announcements
      final announcementResponse = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      announcements = (announcementResponse as List)
          .map((data) => Announcement.fromJson(data))
          .toList();
      print("DEBUG: Fetched ${announcements.length} announcements");
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Database Actions
  Future<void> toggleStatus(
    String table,
    String id,
    String currentStatus,
  ) async {
    final newStatus = currentStatus == 'pending' ? 'resolved' : 'pending';
    await _supabase.from(table).update({'status': newStatus}).eq('id', id);
    await fetchData();
  }

  Future<void> deleteRecord(String table, String id) async {
    await _supabase.from(table).delete().eq('id', id);
    await fetchData();
  }

  Future<void> createAnnouncement(String title, String message) async {
    await _supabase.from('announcements').insert({
      'title': title,
      'message': message,
    });
    await fetchData();
  }

  Future<void> updateAnnouncement(
    String id,
    String title,
    String message,
  ) async {
    await _supabase
        .from('announcements')
        .update({'title': title, 'message': message})
        .eq('id', id);
    await fetchData();
  }

  Future<void> updateUnit(String id, Map<String, dynamic> updates) async {
    await _supabase.from('units').update(updates).eq('id', id);
    await fetchData();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
