import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/inbox_item.dart';

/// Single source of truth for local persistence.
/// Uses SharedPreferences for simplicity (no code-gen required).
class StorageService {
  static const _profileKey = 'user_profile';
  static const _inboxKey = 'inbox_items';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ─── User Profile ─────────────────────────────────────────────────────────

  UserProfile? loadProfile() {
    final json = _prefs.getString(_profileKey);
    if (json == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  bool get hasCompletedOnboarding {
    final profile = loadProfile();
    return profile?.onboardingComplete ?? false;
  }

  // ─── Inbox ────────────────────────────────────────────────────────────────

  List<InboxItem> loadInbox() {
    final json = _prefs.getString(_inboxKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInbox(List<InboxItem> items) async {
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_inboxKey, json);
  }

  Future<void> addInboxItem(InboxItem item) async {
    final items = loadInbox();
    // Newest first
    items.insert(0, item);
    // Max 20 fal — en eski (son) öğeyi sil
    if (items.length > 20) {
      items.removeRange(20, items.length);
    }
    await saveInbox(items);
  }

  Future<void> markInboxItemRead(String id) async {
    final items = loadInbox();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      items[index].isRead = true;
      await saveInbox(items);
    }
  }

  Future<void> deleteInboxItem(String id) async {
    final items = loadInbox();
    items.removeWhere((e) => e.id == id);
    await saveInbox(items);
  }

  int get unreadCount {
    return loadInbox().where((e) => !e.isRead).length;
  }
}
