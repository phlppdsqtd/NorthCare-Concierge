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

  // ── Lookup maps (must match exact DB values) ────────────────────────────────

  static const Map<String, String> _furnishMap = {
    'fully furnished': 'Fully Furnished',
    'fully-furnished': 'Fully Furnished',
    'full furnished': 'Fully Furnished',
    'fully furnish': 'Fully Furnished',
    'semi furnished': 'Semi Furnished',
    'semi-furnished': 'Semi Furnished',
    'semifurnished': 'Semi Furnished',
    'partially furnished': 'Semi Furnished',
    'semi furnish': 'Semi Furnished',
    'unfurnished': 'Unfurnished',
    'not furnished': 'Unfurnished',
    'bare': 'Unfurnished',
    'no furnish': 'Unfurnished',
  };

  static const Map<String, String> _unitTypeMap = {
    'studio': 'Studio',
    '1-bedroom': '1-Bedroom',
    '1 bedroom': '1-Bedroom',
    'one bedroom': '1-Bedroom',
    'one-bedroom': '1-Bedroom',
    '2-bedroom': '2-Bedroom',
    '2 bedroom': '2-Bedroom',
    'two bedroom': '2-Bedroom',
    'two-bedroom': '2-Bedroom',
  };

  static const Map<String, String> _restroomMap = {
    'private restroom': 'Private',
    'private bathroom': 'Private',
    'private cr': 'Private',
    'private toilet': 'Private',
    'own restroom': 'Private',
    'own bathroom': 'Private',
    'own cr': 'Private',
    'shared restroom': 'Shared',
    'shared bathroom': 'Shared',
    'shared cr': 'Shared',
    'shared toilet': 'Shared',
    'common restroom': 'Shared',
    'common bathroom': 'Shared',
  };

  // ── Extractors ──────────────────────────────────────────────────────────────

  String? _extractUnitCode(String text) {
    final match = RegExp(r'\b[A-Za-z]{1,2}\d{3}\b').firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  String? _extractBuilding(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('northgate') || lower.contains('north gate')) return 'NorthGate';
    if (lower.contains('northway') || lower.contains('north way')) return 'NorthWay';
    if (lower.contains('northpoint') || lower.contains('north point') || lower.contains('atrium')) return 'NorthPoint';
    return null;
  }

  String? _extractFromMap(String text, Map<String, String> map) {
    final lower = text.toLowerCase();
    for (final entry in map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractUnitType(String text) => _extractFromMap(text, _unitTypeMap);
  String? _extractFurnish(String text) => _extractFromMap(text, _furnishMap);
  String? _extractRestroom(String text) => _extractFromMap(text, _restroomMap);

  int? _extractMaxPrice(String text) {
    final lower = text.toLowerCase().replaceAll(',', '');

    final kMatch = RegExp(
            r'(?:under|below|less\s+than)\s*(?:php|₱)?\s*(\d+)\s*k')
        .firstMatch(lower);
    if (kMatch != null) return int.parse(kMatch.group(1)!) * 1000;

    final strictMatch = RegExp(
            r'(?:under|below|less\s+than)\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (strictMatch != null) return int.parse(strictMatch.group(1)!);

    final looseMatch = RegExp(
            r'(?:max(?:imum)?|at\s+most|up\s+to)\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (looseMatch != null) return int.parse(looseMatch.group(1)!);

    return null;
  }

  int? _extractMinPrice(String text) {
    final lower = text.toLowerCase().replaceAll(',', '');

    final kMatch = RegExp(
            r'(?:above|over|more\s+than|greater\s+than|at\s+least|minimum|starting\s+(?:at|from))\s*(?:php|₱)?\s*(\d+)\s*k')
        .firstMatch(lower);
    if (kMatch != null) return int.parse(kMatch.group(1)!) * 1000;

    final numMatch = RegExp(
            r'(?:above|over|more\s+than|greater\s+than|at\s+least|minimum|starting\s+(?:at|from))\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (numMatch != null) return int.parse(numMatch.group(1)!);

    return null;
  }

  int? _extractCapacity(String text) {
    final lower = text.toLowerCase();
    final match = RegExp(
            r'(?:for|fits?|accommodate[sd]?|capacity\s+of|up\s+to)?\s*(\d+)\s*(?:people|persons?|pax|tenants?|occupants?)')
        .firstMatch(lower);
    if (match != null) return int.parse(match.group(1)!);
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
        final maxPrice = _extractMaxPrice(userText);
        final minPrice = _extractMinPrice(userText);
        final unitType = _extractUnitType(userText);
        final furnish = _extractFurnish(userText);
        final restroom = _extractRestroom(userText);
        final capacity = _extractCapacity(userText);

        // Debug log — remove before final submission
        debugPrint("── Chat filters ──────────────────────────");
        debugPrint("unitCode : $unitCode");
        debugPrint("building : $building");
        debugPrint("unitType : $unitType");
        debugPrint("furnish  : $furnish");
        debugPrint("restroom : $restroom");
        debugPrint("minPrice : $minPrice");
        debugPrint("maxPrice : $maxPrice");
        debugPrint("capacity : $capacity");
        debugPrint("──────────────────────────────────────────");

        final hasFilters = unitType != null || maxPrice != null ||
            minPrice != null || furnish != null || restroom != null ||
            building != null || capacity != null;

        if (unitCode != null) {
          dbContext = await _repository.getUnitByCode(unitCode);

        } else if (_matches(userText, [
          'available', 'vacant', 'free unit', 'open unit', 'for rent', 'empty',
        ])) {
          dbContext = await _repository.getAvailableUnits(
            unitType: unitType,
            furnish: furnish,
            restroom: restroom,
            building: building,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minCapacity: capacity,
          );

        } else if (hasFilters) {
          dbContext = await _repository.getUnits(
            unitType: unitType,
            furnish: furnish,
            restroom: restroom,
            building: building,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minCapacity: capacity,
          );

        } else if (_matches(userText, [
          'all unit', 'list unit', 'show unit', 'what unit', 'show all',
          'what do you offer', 'what are your units', 'unit do you have',
          'price', 'rent', 'monthly', 'how much', 'cost', 'rate',
          'studio', 'bedroom', 'furnished', 'furnish', 'restroom',
          'curfew', 'sqm', 'room size', 'capacity', 'unit', 'building',
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