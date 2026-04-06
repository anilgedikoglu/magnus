import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_profile.dart';
import 'models/inbox_item.dart';
import 'services/storage_service.dart';
import 'services/fortune_service.dart';
import 'services/conversation_loader.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPrefsProvider));
});

final fortuneServiceProvider = Provider<FortuneService>((ref) {
  return FortuneService();
});

final conversationLoaderProvider = Provider<ConversationLoader>((ref) {
  return ConversationLoader();
});

// ─── User Profile ─────────────────────────────────────────────────────────────

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.loadProfile() ?? UserProfile.empty();
  }

  Future<void> save(UserProfile profile) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(profile);
    state = profile;
  }

  void update(UserProfile Function(UserProfile) fn) {
    state = fn(state);
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    final completed = UserProfile(
      name: profile.name,
      age: profile.age,
      gender: profile.gender,
      job: profile.job,
      maritalStatus: profile.maritalStatus,
      birthDate: profile.birthDate,
      birthCity: profile.birthCity,
      zodiacSign: profile.zodiacSign,
      onboardingComplete: true,
    );
    await save(completed);
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

// ─── Inbox ────────────────────────────────────────────────────────────────────

class InboxNotifier extends Notifier<List<InboxItem>> {
  @override
  List<InboxItem> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.loadInbox();
  }

  Future<void> addItem(InboxItem item) async {
    final storage = ref.read(storageServiceProvider);
    await storage.addInboxItem(item);
    state = storage.loadInbox();
  }

  Future<void> markRead(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.markInboxItemRead(id);
    state = storage.loadInbox();
  }

  Future<void> deleteItem(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteInboxItem(id);
    state = storage.loadInbox();
  }

  int get unreadCount => state.where((e) => !e.isRead).length;
}

final inboxProvider =
    NotifierProvider<InboxNotifier, List<InboxItem>>(InboxNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).where((e) => !e.isRead).length;
});

// ─── Onboarding state ─────────────────────────────────────────────────────────

final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).onboardingComplete;
});
