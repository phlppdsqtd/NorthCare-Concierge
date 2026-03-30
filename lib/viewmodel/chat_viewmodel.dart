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

  // ── Lookup maps ─────────────────────────────────────────────────────────────

  static const Map<String, String> _furnishMap = {
    'fully furnished':     'Fully Furnished',
    'fully-furnished':     'Fully Furnished',
    'full furnished':      'Fully Furnished',
    'fully furnish':       'Fully Furnished',
    'semi furnished':      'Semi Furnished',
    'semi-furnished':      'Semi Furnished',
    'semifurnished':       'Semi Furnished',
    'partially furnished': 'Semi Furnished',
    'semi furnish':        'Semi Furnished',
    'unfurnished':         'Unfurnished',
    'not furnished':       'Unfurnished',
    'bare':                'Unfurnished',
    'no furnish':          'Unfurnished',
  };

  static const Map<String, String> _unitTypeMap = {
    'studio':      'Studio',
    '1-bedroom':   '1-Bedroom',
    '1 bedroom':   '1-Bedroom',
    'one bedroom': '1-Bedroom',
    'one-bedroom': '1-Bedroom',
    '2-bedroom':   '2-Bedroom',
    '2 bedroom':   '2-Bedroom',
    'two bedroom': '2-Bedroom',
    'two-bedroom': '2-Bedroom',
  };

  static const Map<String, String> _restroomMap = {
    'private restroom': 'Private',
    'private bathroom': 'Private',
    'private cr':       'Private',
    'private toilet':   'Private',
    'own restroom':     'Private',
    'own bathroom':     'Private',
    'own cr':           'Private',
    'shared restroom':  'Shared',
    'shared bathroom':  'Shared',
    'shared cr':        'Shared',
    'shared toilet':    'Shared',
    'common restroom':  'Shared',
    'common bathroom':  'Shared',
  };

  static const List<String> _allStatusKeywords = [
    'all units', 'all occupied', 'occupied',
    'regardless', 'any status', 'both',
  ];

  static const List<String> _availabilityKeywords = [
    'available', 'vacant', 'free unit', 'open unit', 'for rent', 'empty',
  ];

  static const List<String> _generalListingKeywords = [
    'all unit', 'list unit', 'show unit', 'what unit', 'show all',
    'what do you offer', 'what are your units', 'unit do you have',
    'price', 'rent', 'monthly', 'how much', 'cost', 'rate',
    'studio', 'bedroom', 'furnished', 'furnish', 'restroom',
    'curfew', 'sqm', 'room size', 'capacity', 'unit', 'building',
  ];

  // ── Extractors ──────────────────────────────────────────────────────────────

  String? _extractUnitCode(String text) {
    final match = RegExp(r'\b[A-Za-z]{1,2}\d{3}\b').firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  /// Returns safe partial building search terms (no apostrophes).
  /// Uses short unique substrings that ilike can match safely.
  List<String> _extractBuildings(String text) {
    final lower = text.toLowerCase();
    final buildings = <String>[];
    if (lower.contains('northgate') || lower.contains('north gate')) {
      buildings.add('NorthGate');
    }
    if (lower.contains('northway') || lower.contains('north way')) {
      buildings.add('NorthWay');
    }
    if (lower.contains('northpoint') || lower.contains('north point') ||
        lower.contains('atrium')) {
      buildings.add('NorthPoint');
    }
    return buildings;
  }

  String? _extractFromMap(String text, Map<String, String> map) {
    final lower = text.toLowerCase();
    for (final entry in map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractUnitType(String text) => _extractFromMap(text, _unitTypeMap);
  String? _extractFurnish(String text)   => _extractFromMap(text, _furnishMap);
  String? _extractRestroom(String text)  => _extractFromMap(text, _restroomMap);

  /// Extracts explicit price ranges only:
  /// "between X and Y", "₱X to ₱Y", "Xk to Yk"
  Map<String, int>? _extractPriceRange(String text) {
    final lower = text.toLowerCase().replaceAll(',', '');

    final betweenMatch = RegExp(
            r'between\s*(?:php|₱)?\s*(\d+)\s*(?:and|to|-)\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (betweenMatch != null) {
      return {
        'min': int.parse(betweenMatch.group(1)!),
        'max': int.parse(betweenMatch.group(2)!),
      };
    }

    // Requires ₱ or php prefix to avoid false matches
    final rangeMatch = RegExp(
            r'(?:php|₱)\s*(\d{3,})\s*(?:to|-)\s*(?:php|₱)?\s*(\d{3,})')
        .firstMatch(lower);
    if (rangeMatch != null) {
      return {
        'min': int.parse(rangeMatch.group(1)!),
        'max': int.parse(rangeMatch.group(2)!),
      };
    }

    // "Xk to Yk" shorthand
    final kRangeMatch = RegExp(
            r'(\d+(?:\.\d+)?)\s*k\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*k')
        .firstMatch(lower);
    if (kRangeMatch != null) {
      return {
        'min': (double.parse(kRangeMatch.group(1)!) * 1000).round(),
        'max': (double.parse(kRangeMatch.group(2)!) * 1000).round(),
      };
    }

    return null;
  }

  /// Price ceiling: "under/below/less than X"
  int? _extractMaxPrice(String text) {
    if (_extractPriceRange(text) != null) return null;
    final lower = text.toLowerCase().replaceAll(',', '');

    final kMatch = RegExp(
            r'(?:under|below|less\s+than)\s*(?:php|₱)?\s*(\d+)\s*k')
        .firstMatch(lower);
    if (kMatch != null) return int.parse(kMatch.group(1)!) * 1000;

    final numMatch = RegExp(
            r'(?:under|below|less\s+than)\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (numMatch != null) return int.parse(numMatch.group(1)!);

    final looseMatch = RegExp(
            r'(?:max(?:imum)?|at\s+most|up\s+to)\s*(?:php|₱)?\s*(\d+)')
        .firstMatch(lower);
    if (looseMatch != null) return int.parse(looseMatch.group(1)!);

    return null;
  }

  /// Price floor: "above/over/more than/greater than X"
  int? _extractMinPrice(String text) {
    if (_extractPriceRange(text) != null) return null;
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

  /// Capacity: "for 2 people", "3 pax", "fits 4"
  int? _extractCapacity(String text) {
    final lower = text.toLowerCase();
    final match = RegExp(
            r'(?:for|fits?|accommodate[sd]?|capacity\s+of|up\s+to)?\s*'
            r'(\d+)\s*(?:people|persons?|pax|tenants?|occupants?)')
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
      'who lives', 'who is in', 'who stays', 'tenant name',
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
        final unitCode   = _extractUnitCode(userText);
        final buildings  = _extractBuildings(userText);
        final priceRange = _extractPriceRange(userText);
        final maxPrice   = priceRange?['max'] ?? _extractMaxPrice(userText);
        final minPrice   = priceRange?['min'] ?? _extractMinPrice(userText);
        final unitType   = _extractUnitType(userText);
        final furnish    = _extractFurnish(userText);
        final restroom   = _extractRestroom(userText);
        final capacity   = _extractCapacity(userText);

        final isAvailabilityQuery = _matches(userText, _availabilityKeywords);
        final wantsAllStatus      = _matches(userText, _allStatusKeywords);
        final String? statusFilter = isAvailabilityQuery
            ? 'Available'
            : wantsAllStatus
                ? null
                : 'Available';

        final hasFilters = unitType != null || maxPrice != null ||
            minPrice != null || furnish != null || restroom != null ||
            buildings.isNotEmpty || capacity != null;

        if (unitCode != null) {
          dbContext = await _repository.getUnitByCode(unitCode);

        } else if (buildings.length > 1) {
          // Multi-building: fetch each with safe partial building name
          final results = <String>[];
          for (final b in buildings) {
            final result = await _repository.getUnits(
              status:      statusFilter,
              building:    b,
              unitType:    unitType,
              furnish:     furnish,
              restroom:    restroom,
              minPrice:    minPrice,
              maxPrice:    maxPrice,
              minCapacity: capacity,
            );
            if (result != "No units matched your criteria.") {
              results.add(result);
            }
          }
          dbContext = results.isNotEmpty
              ? results.join('\n')
              : "No units matched your criteria.";

        } else if (hasFilters) {
          dbContext = await _repository.getUnits(
            status:      statusFilter,
            unitType:    unitType,
            furnish:     furnish,
            restroom:    restroom,
            building:    buildings.isNotEmpty ? buildings.first : null,
            minPrice:    minPrice,
            maxPrice:    maxPrice,
            minCapacity: capacity,
          );

        } else if (_matches(userText, _generalListingKeywords)) {
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