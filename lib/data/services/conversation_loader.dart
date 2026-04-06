import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_node.dart';

/// Loads ConversationFlow objects from JSON assets.
class ConversationLoader {
  final Map<String, ConversationFlow> _cache = {};

  Future<ConversationFlow> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final json = await rootBundle.loadString(assetPath);
    final flow = ConversationFlow.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
    _cache[assetPath] = flow;
    return flow;
  }

  Future<ConversationFlow> loadOnboarding() =>
      load('assets/data/onboarding.json');
}
