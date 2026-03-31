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
    'all occupied', 'occupied',
    'regardless', 'any status',
    'show occupied', 'include occupied',
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

  List<String> _extractUnitCodes(String text) {
    final matches = RegExp(r'\b[A-Za-z]{1,2}\d{3}\b').allMatches(text);
    return matches.map((m) => m.group(0)!.toUpperCase()).toSet().toList();
  }

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

  /// Explicit range: "between X and Y", "₱X to ₱Y", "Xk to Yk"
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

    // requires ₱/php prefix to avoid false matches
    final rangeMatch = RegExp(
            r'(?:php|₱)\s*(\d{3,})\s*(?:to|-)\s*(?:php|₱)?\s*(\d{3,})')
        .firstMatch(lower);
    if (rangeMatch != null) {
      return {
        'min': int.parse(rangeMatch.group(1)!),
        'max': int.parse(rangeMatch.group(2)!),
      };
    }

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

  /// Price ceiling — expanded to cover more natural phrases
  int? _extractMaxPrice(String text) {
    if (_extractPriceRange(text) != null) return null;
    final lower = text.toLowerCase().replaceAll(',', '');

    // Handle "Xk" shorthand first
    final kMatch = RegExp(
            r'(?:under|below|less\s+than|cheaper\s+than|not\s+more\s+than|no\s+more\s+than|at\s+most|max(?:imum)?|up\s+to)\s*(?:php|₱)?\s*(\d+)\s*k')
        .firstMatch(lower);
    if (kMatch != null) return int.parse(kMatch.group(1)!) * 1000;

    // Handle plain numbers — strip ₱ before matching
    final clean = lower.replaceAll('₱', '').replaceAll('php', '');
    final numMatch = RegExp(
            r'(?:under|below|less\s+than|cheaper\s+than|not\s+more\s+than|no\s+more\s+than|at\s+most|max(?:imum)?|up\s+to)\s*(\d+)')
        .firstMatch(clean);
    if (numMatch != null) return int.parse(numMatch.group(1)!);

    return null;
  }

  /// Price floor — expanded to cover more natural phrases
  int? _extractMinPrice(String text) {
    if (_extractPriceRange(text) != null) return null;
    final lower = text.toLowerCase().replaceAll(',', '');

    final kMatch = RegExp(
            r'(?:above|over|more\s+than|greater\s+than|at\s+least|minimum|pricier\s+than|costlier\s+than|starting\s+(?:at|from))\s*(?:php|₱)?\s*(\d+)\s*k')
        .firstMatch(lower);
    if (kMatch != null) return int.parse(kMatch.group(1)!) * 1000;

    final clean = lower.replaceAll('₱', '').replaceAll('php', '');
    final numMatch = RegExp(
            r'(?:above|over|more\s+than|greater\s+than|at\s+least|minimum|pricier\s+than|costlier\s+than|starting\s+(?:at|from))\s*(\d+)')
        .firstMatch(clean);
    if (numMatch != null) return int.parse(numMatch.group(1)!);

    return null;
  }

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
            "DATABASE RESULT: 0 units found. The user is asking for confidential tenant information. Do not provide any personal details.";
      } else {
        final unitCodes  = _extractUnitCodes(userText);
        final buildings  = _extractBuildings(userText);
        final priceRange = _extractPriceRange(userText);
        final maxPrice   = priceRange?['max'] ?? _extractMaxPrice(userText);
        final minPrice   = priceRange?['min'] ?? _extractMinPrice(userText);
        final unitType   = _extractUnitType(userText);
        final furnish    = _extractFurnish(userText);
        final restroom   = _extractRestroom(userText);
        final capacity   = _extractCapacity(userText);

        // When unit codes are present, ignore building extractor
        final buildingsToQuery = unitCodes.isEmpty ? buildings : <String>[];

        final isAvailabilityQuery = _matches(userText, _availabilityKeywords);
        final wantsAllStatus      = _matches(userText, _allStatusKeywords);
        final String? statusFilter = isAvailabilityQuery
            ? 'Available'
            : wantsAllStatus
                ? null
                : 'Available';

        final hasFilters = unitType != null || maxPrice != null ||
            minPrice != null || furnish != null || restroom != null ||
            buildingsToQuery.isNotEmpty || capacity != null;

        debugPrint("── Chat filters ──────────────────────────");
        debugPrint("unitCodes : $unitCodes");
        debugPrint("buildings : $buildingsToQuery");
        debugPrint("unitType  : $unitType");
        debugPrint("furnish   : $furnish");
        debugPrint("restroom  : $restroom");
        debugPrint("minPrice  : $minPrice");
        debugPrint("maxPrice  : $maxPrice");
        debugPrint("capacity  : $capacity");
        debugPrint("status    : $statusFilter");
        debugPrint("──────────────────────────────────────────");

        if (unitCodes.isNotEmpty) {
          final results = <String>[];
          for (final code in unitCodes) {
            results.add(await _repository.getUnitByCode(code));
          }
          dbContext = results.join('\n');

        } else if (buildingsToQuery.length > 1) {
          final results = <String>[];
          for (final b in buildingsToQuery) {
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
            results.add(result);
          }
          dbContext = results.join('\n');

        } else if (hasFilters) {
          dbContext = await _repository.getUnits(
            status:      statusFilter,
            unitType:    unitType,
            furnish:     furnish,
            restroom:    restroom,
            building:    buildingsToQuery.isNotEmpty ? buildingsToQuery.first : null,
            minPrice:    minPrice,
            maxPrice:    maxPrice,
            minCapacity: capacity,
          );

        } else if (_matches(userText, _generalListingKeywords)) {
          dbContext = await _repository.getAllUnits();
        }
      }

      // If database returned nothing, respond directly without calling AI
      if (dbContext.contains('DATABASE RESULT: 0 units found') ||
          dbContext.contains('does not exist')) {
        messages.add(ChatMessage(
          text:
              "I'm sorry, no units matched your criteria in our current listings. "
              "For more assistance, please submit a Unit Inquiry form in the app "
              "and our property manager will get back to you.",
          isUser: false,
        ));
      } else {
        final aiText = await _gemini.ask(userText, dbContext);
        messages.add(ChatMessage(text: aiText, isUser: false));
      }
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