import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _apiKey = 'AIzaSyCBABlaIG-nLJy89I8Jvln2Q3H94yChxi4';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          "Hello! I am the NorthCare AI Concierge. I can help you with unit availability, pricing, and amenities. How can I assist you today?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Gemini ────────────────────────────────────────────────────────────────

  Future<String> _askGemini(String userPrompt, String dbContext) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

    final systemPrompt = '''
You are the official AI Concierge for the NorthCare Property Management System.
You assist prospective renters and the general public inquiring about units.
You manage three apartment buildings in Bacolod City: D\' NorthGate, D\' NorthWay, and NorthPoint Atrium.

Tone: Professional, welcoming, concise, and helpful.

General Knowledge:
- Location: All properties are along BS Aquino Drive, Bacolod City, near the University of St. La Salle, The Doctors\' Hospital, and Riverside Medical Center.
- Unit Types: Studios, 1-Bedroom, and 2-Bedroom units.
- Pet Policy: Small pets allowed with prior approval and a pet deposit.
- Maintenance: Direct tenants to the "Report Maintenance Issue" form in the app.
- Viewings / Inquiries: Direct prospective renters to the "Submit Unit Inquiry" form in the app.

Database Context (use this to answer the user\'s question):
$dbContext

Strict Privacy Rules — you MUST follow these at all times:
- NEVER reveal the names, contact numbers, or any personal information of current tenants.
- NEVER reveal lease start dates, lease end dates, or lease terms of occupied units.
- NEVER confirm or deny who is living in any specific unit.
- If asked about tenant identity or personal details, politely say that tenant information is confidential and redirect the user to the inquiry form.
- You may only share: unit code, building, unit type, capacity, room size, furnishing, restroom type, curfew, price, and availability status.

Additional Rules:
- Answer ONLY using the database context provided. Do NOT invent information.
- If the data does not contain what the user needs, say the property manager can assist via the inquiry form.
- Keep responses concise and organized.
''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": userPrompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      return "Sorry, I could not connect right now. (${response.statusCode})";
    }
  }

  // ── Supabase helpers (public-safe fields only) ────────────────────────────

  Future<String> _getAvailableUnits() async {
    final rows = await Supabase.instance.client
        .from('units')
        .select(
            'building, unit_code, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .eq('status', 'Available');

    if ((rows as List).isEmpty) return "No units are currently available.";

    return rows.map((u) {
      return "Unit ${u['unit_code']} at ${u['building']}: "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month, status: ${u['status']}";
    }).join('\n');
  }

  Future<String> _getUnitByCode(String unitCode) async {
    final row = await Supabase.instance.client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .eq('unit_code', unitCode)
        .maybeSingle();

    if (row == null) return "No unit found with code $unitCode.";

    return "Unit ${row['unit_code']} at ${row['building']}: "
        "${row['unit_type']}, capacity ${row['capacity']}, "
        "room size ${row['room_size']} sqm, furnishing: ${row['furnish']}, "
        "restroom: ${row['restroom']}, curfew: ${row['curfew']}, "
        "₱${row['price_lease']}/month, status: ${row['status']}";
  }

  Future<String> _getUnitsByBuilding(String building) async {
    final rows = await Supabase.instance.client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status')
        .ilike('building', '%$building%');

    if ((rows as List).isEmpty) {
      return "No units found for building matching '$building'.";
    }

    return rows.map((u) {
      return "Unit ${u['unit_code']} (${u['status']}): "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month";
    }).join('\n');
  }

  Future<String> _getAllUnits() async {
    final rows = await Supabase.instance.client
        .from('units')
        .select(
            'unit_code, building, unit_type, capacity, room_size, furnish, restroom, curfew, price_lease, status');

    if ((rows as List).isEmpty) return "No units found.";

    return rows.map((u) {
      return "Unit ${u['unit_code']} at ${u['building']} (${u['status']}): "
          "${u['unit_type']}, capacity ${u['capacity']}, "
          "room size ${u['room_size']} sqm, furnishing: ${u['furnish']}, "
          "restroom: ${u['restroom']}, curfew: ${u['curfew']}, "
          "₱${u['price_lease']}/month";
    }).join('\n');
  }

  // ── Intent detection ──────────────────────────────────────────────────────

  String? _extractUnitCode(String text) {
    final match = RegExp(r'\b[A-Za-z]{1,2}\d{3}\b').firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  String? _extractBuilding(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('northgate') || lower.contains('north gate')) {
      return 'NorthGate';
    }
    if (lower.contains('northway') || lower.contains('north way')) {
      return 'NorthWay';
    }
    if (lower.contains('northpoint') ||
        lower.contains('north point') ||
        lower.contains('atrium')) {
      return 'NorthPoint';
    }
    return null;
  }

  bool _matches(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  bool _isSensitiveQuery(String text) {
    return _matches(text, [
      'who lives', 'who is in', 'who stays', 'tenant name', 'occupant',
      'renter name', 'who rents', 'contact number', 'phone number',
      'personal info', 'resident name', 'who is renting', 'who is staying',
      'tell me who', 'name of the tenant', 'name of tenant',
    ]);
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    String dbContext = "No specific database data retrieved for this query.";

    try {
      if (_isSensitiveQuery(userText)) {
        // Block sensitive queries — pass a directive to Gemini instead of data
        dbContext =
            "The user is asking for confidential tenant information. Do not provide any personal details.";
      } else {
        final unitCode = _extractUnitCode(userText);
        final building = _extractBuilding(userText);

        if (unitCode != null) {
          dbContext = await _getUnitByCode(unitCode);
        } else if (building != null) {
          dbContext = await _getUnitsByBuilding(building);
        } else if (_matches(userText, [
          'available', 'vacant', 'free unit', 'open unit', 'for rent', 'empty',
        ])) {
          dbContext = await _getAvailableUnits();
        } else if (_matches(userText, [
          'all unit', 'list unit', 'show unit', 'what unit',
          'units available', 'what do you offer', 'what are your units',
          'show all', 'unit do you have',
        ])) {
          dbContext = await _getAllUnits();
        } else if (_matches(userText, [
          'price', 'rent', 'monthly', 'how much', 'cost', 'rate',
          'studio', '1-bedroom', '2-bedroom', 'bedroom', 'furnished',
          'furnish', 'restroom', 'curfew', 'sqm', 'room size', 'capacity',
          'unit', 'building',
        ])) {
          dbContext = await _getAllUnits();
        }
      }

      final aiText = await _askGemini(userText, dbContext);

      setState(() {
        _messages.add(ChatMessage(text: aiText, isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I could not connect right now. Please try again later.",
          isUser: false,
        ));
      });
      debugPrint("Chat Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Concierge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.teal
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about units, pricing, amenities...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}