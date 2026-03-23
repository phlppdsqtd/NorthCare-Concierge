// lib/viewmodel/chat_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_repository.dart';
import '../services/gemini_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();
  final GeminiService _gemini = GeminiService();

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          "Hello! I am the NorthCare AI Concierge. I can help you with unit availability, pricing, and amenities. How can I assist you today?",
      isUser: false,
    ),
  ];

  bool isLoading = false;

  // ── Intent helpers ──────────────────────────────────────────────────────────

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

  // ── Send message ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    messages.add(ChatMessage(text: userText, isUser: true));
    isLoading = true;
    notifyListeners();

    String dbContext = "No specific database data retrieved for this query.";

    try {
      if (_isSensitiveQuery(userText)) {
        dbContext =
            "The user is asking for confidential tenant information. Do not provide any personal details.";
      } else {
        final unitCode = _extractUnitCode(userText);
        final building = _extractBuilding(userText);

        if (unitCode != null) {
          dbContext = await _repository.getUnitByCode(unitCode);
        } else if (building != null) {
          dbContext = await _repository.getUnitsByBuilding(building);
        } else if (_matches(userText, [
          'available', 'vacant', 'free unit', 'open unit', 'for rent', 'empty',
        ])) {
          dbContext = await _repository.getAvailableUnits();
        } else if (_matches(userText, [
          'all unit', 'list unit', 'show unit', 'what unit',
          'units available', 'what do you offer', 'what are your units',
          'show all', 'unit do you have',
        ])) {
          dbContext = await _repository.getAllUnits();
        } else if (_matches(userText, [
          'price', 'rent', 'monthly', 'how much', 'cost', 'rate',
          'studio', '1-bedroom', '2-bedroom', 'bedroom', 'furnished',
          'furnish', 'restroom', 'curfew', 'sqm', 'room size', 'capacity',
          'unit', 'building',
        ])) {
          dbContext = await _repository.getAllUnits();
        }
      }

      final aiText = await _gemini.ask(userText, dbContext);
      messages.add(ChatMessage(text: aiText, isUser: false));
    } catch (e) {
      messages.add(ChatMessage(
        text: "Sorry, I could not connect right now. Please try again later.",
        isUser: false,
      ));
      debugPrint("Chat Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}