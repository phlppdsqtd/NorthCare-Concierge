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
    // SAFETY CHECK: Supabase Postgres will crash if you send an empty string "" to a Date column.
    // We must convert empty strings to actual nulls before sending to the DB.
    final safeUpdates = Map<String, dynamic>.from(updates);
    
    if (safeUpdates['start_lease'] != null && safeUpdates['start_lease'].toString().trim().isEmpty) {
      safeUpdates['start_lease'] = null;
    }
    if (safeUpdates['end_lease'] != null && safeUpdates['end_lease'].toString().trim().isEmpty) {
      safeUpdates['end_lease'] = null;
    }

    try {
      await _supabase.from('units').update(safeUpdates).eq('id', id);
      await fetchData();
    } catch (e) {
      debugPrint('Error updating unit: $e');
      rethrow; // Rethrow so the UI can catch it if needed
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> clearUnitTenant(String unitId) async {
    try {
      // Switched to use your existing _supabase instance variable for cleaner code
      await _supabase
          .from('units')
          .update({
            'first_name': null,
            'last_name': null,
            'contact': null,
            'occupancy': 0,
            'start_lease': null,
            'end_lease': null,
            'status': 'Available', // Resetting status
          })
          .eq('id', unitId);
          
      await fetchData(); // Refresh the lists after clearing
    } catch (e) {
      debugPrint('Error clearing unit: $e');
    }
  }
}