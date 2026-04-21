// ── AI NOTU: providers.dart ───────────────────────────────────────────────────
// Uygulamanın tüm Riverpod provider'ları burada tanımlıdır.
//
// Temel provider'lar:
//   userProfileProvider       → UserProfile StateNotifier (Hive kalıcı)
//                               ref.watch ile profil değişince rebuild tetiklenir
//   inboxProvider             → List<InboxItem> StateNotifier (fal sonuçları)
//   readyUnreadCountProvider  → kilitli olmayan okunmamış inbox sayısı
//   tarotSentProvider         → bool, tarot falı gönderilince true olur
//                               HomeScreen bunu dinler → Balon 3 eklenir +
//                               tarot_bugun_tarih set edilir
//   fortuneServiceProvider    → AI fal servisi (OpenAI/Gemini)
//   onboardingCompleteProvider → bool, onboarding tamamlandı mı
//
// Kullanım örneği:
//   final profile = ref.read(userProfileProvider);
//   await ref.read(userProfileProvider.notifier).save(profile.copyWith(...));
// ─────────────────────────────────────────────────────────────────────────────
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
      birthTime: profile.birthTime,
      risingSign: profile.risingSign,
      moonSign: profile.moonSign,
      planet: profile.planet,
      profilePicIndex: profile.profilePicIndex,
      customPhotoPath: profile.customPhotoPath,
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

/// Kilitli olmayan (açılmış) okunmamış öğe sayısı — ana menü flare için
final readyUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).where((e) => !e.isRead && !e.isLocked).length;
});

/// Tarot falı gönderildiğinde ana menüye bildirim için
final tarotSentProvider = StateProvider<bool>((ref) => false);

/// Kahve falı gönderildiğinde ana menüye bildirim için
final kahveSentProvider = StateProvider<bool>((ref) => false);

/// Durugörü seçimi yapıldığında ana menüye bildirim için
final durugoruSentProvider = StateProvider<bool>((ref) => false);

// ─── Onboarding state ─────────────────────────────────────────────────────────

final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).onboardingComplete;
});
