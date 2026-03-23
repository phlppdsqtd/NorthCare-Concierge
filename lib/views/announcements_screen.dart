import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final future = Supabase.instance.client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
        // backgroundColor: Colors.teal.shade700,
        // foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No announcements yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for updates.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final a = data[index];

              final createdAt = a['created_at'] != null
                  ? DateFormat('MMM d, yyyy • h:mm a')
                      .format(DateTime.parse(a['created_at']))
                  : '';

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () => _showAnnouncementDialog(context, a),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.teal),
                  ),
                  title: Text(
                    a['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['message'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          createdAt,
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===================== EXPAND / "ZOOM" VIEW =====================
  void _showAnnouncementDialog(BuildContext context, Map<String, dynamic> a) {
    final createdAt = a['created_at'] != null
        ? DateFormat('MMMM d, yyyy • h:mm a')
            .format(DateTime.parse(a['created_at']))
        : '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign, color: Colors.teal),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        a['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    createdAt,
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),

                Text(
                  a['message'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}