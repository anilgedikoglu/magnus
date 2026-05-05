import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton reklam yöneticisi.
///
/// Kullanım:
///   await AdService.instance.initialize();   // main() içinde
///   await AdService.instance.showInterstitial();
///   await AdService.instance.showRewarded(onRewarded: ..., onFailed: ...);
///
/// TODO: Gerçek ID'leri aşağıdaki 3 satırda güncelle.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Reklam ID'leri ─────────────────────────────────────────────────────────
  static const _interstitialId = 'ca-app-pub-6470338276121414/7632109672';
  static const _rewardedId     = 'ca-app-pub-6470338276121414/2337219262';

  InterstitialAd? _interstitialAd;
  RewardedAd?     _rewardedAd;
  bool _interstitialLoading = false;
  bool _rewardedLoading     = false;

  /// Geçiş reklamı çağrı sayacı.
  /// Her 3 çağrıdan 1'inde reklam gösterilir (1 göster, 2 atla).
  int _interstitialCallCount = 0;

  // ── Başlatma ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (kDebugMode) return; // emülatörde video codec crash — release'de yükle
    _loadInterstitial();
    _loadRewarded();
  }

  // ── Interstitial ────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (kDebugMode) return;
    if (_interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          debugPrint('[AdService] Interstitial yüklenemedi: $err');
        },
      ),
    );
  }

  /// Geçiş reklamını gösterir. Kapanınca (veya yüklü değilse hemen) döner.
  ///
  /// [throttle] true (varsayılan) → her 3 çağrıdan 1'inde gösterilir.
  /// [throttle] false → her çağrıda gösterilir (olumlama/özlü sözler gibi
  ///   kendi sıklık mantığını ekranda yöneten yerler bunu kullanır).
  Future<void> showInterstitial({VoidCallback? onClosed, bool throttle = true}) async {
    if (throttle) {
      _interstitialCallCount++;
      // 1. çağrı → göster, 2. ve 3. çağrı → atla, 4. çağrı → göster, ...
      if (_interstitialCallCount % 3 != 1) {
        onClosed?.call();
        return;
      }
    }

    final ad = _interstitialAd;
    _interstitialAd = null;
    if (ad == null) {
      onClosed?.call();
      _loadInterstitial();
      return;
    }
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        onClosed?.call();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
        onClosed?.call();
        if (!completer.isCompleted) completer.complete();
        debugPrint('[AdService] Interstitial gösterilemedi: $err');
      },
    );
    await ad.show();
    await completer.future;
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (kDebugMode) return;
    if (_rewardedLoading || _rewardedAd != null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (err) {
          _rewardedLoading = false;
          debugPrint('[AdService] Rewarded yüklenemedi: $err');
        },
      ),
    );
  }

  /// Rewarded reklamı gösterir.
  /// - Reklam yüklüyse: gösterilir, kapanınca [onRewarded] çağrılır.
  /// - Reklam yüklü değilse: [onFailed] hemen çağrılır (içerik engellenmez).
  /// Not: Rewarded gösterilse bile kullanıcı izlemeden kapatırsa [onFailed] çağrılır.
  Future<void> showRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) async {
    final ad = _rewardedAd;
    _rewardedAd = null;
    if (ad == null) {
      onFailed();
      _loadRewarded();
      return;
    }
    bool earned = false;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (earned) {
          onRewarded();
        } else {
          onFailed();
        }
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadRewarded();
        onFailed();
        if (!completer.isCompleted) completer.complete();
        debugPrint('[AdService] Rewarded gösterilemedi: $err');
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    await completer.future;
  }
}
