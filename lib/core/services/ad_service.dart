import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_pacing.dart';

/// Singleton reklam yöneticisi. Düzen: docs/reklam_duzeni.md.
///
///   await AdService.instance.initialize();           // main() içinde (UMP arka planda sürer)
///   AdService.instance.maybeShowInterstitial(...)    // yalnız doğal arada (fal kapanışı)
///   AdService.instance.showRewardedFor(...)          // yalnız kullanıcı "izle" deyince
///
/// Kurallar: ödül YALNIZ `onUserEarnedReward` gelince verilir; `canRequestAds` (UMP) olmadan reklam
/// istenmez; iOS'ta ATT yok, istekler `nonPersonalizedAds: true`.
class AdService {
  AdService._();

  /// Yalnız testlerde alt sınıf için.
  @visibleForTesting
  AdService.forTest();

  static AdService instance = AdService._();

  // ── Reklam ID'leri (platforma ÖZEL — AdMob'da iOS ve Android ayrı uygulamalar) ─
  // Android app:  ca-app-pub-6470338276121414~6209031577
  // iOS app:      ca-app-pub-6470338276121414~5546686598
  // Bir platformun reklam birimi diğerinde reklam GÖSTERMEZ → Platform.isIOS şart.
  static String get _interstitialId => Platform.isIOS
      ? 'ca-app-pub-6470338276121414/7944769167'  // iOS — Geçiş
      : 'ca-app-pub-6470338276121414/7632109672'; // Android — Geçiş
  static String get _rewardedId => Platform.isIOS
      ? 'ca-app-pub-6470338276121414/5318605820'  // iOS — Ödüllü
      : 'ca-app-pub-6470338276121414/2337219262'; // Android — Ödüllü

  /// iOS'ta ATT yok → kişiselleştirilmemiş reklam. Android'de varsayılan (UMP kararı geçerli).
  static AdRequest _request() =>
      Platform.isIOS ? const AdRequest(nonPersonalizedAds: true) : const AdRequest();

  /// Yükleme hatasında en çok bu kadar yeniden dene (10 sn, 30 sn, 90 sn).
  static const _retryDelays = [Duration(seconds: 10), Duration(seconds: 30), Duration(seconds: 90)];

  /// Yüklenen reklam 1 saat sonra geçersiz olur; süresi dolmuşu gösterince gelir yazılmaz.
  static const reklamOmru = Duration(minutes: 55);

  /// [yuklendi] anında yüklenen reklamın süresi [simdi] itibarıyla doldu mu?
  @visibleForTesting
  static bool suresiDoldu(DateTime yuklendi, DateTime simdi) =>
      simdi.difference(yuklendi) >= reklamOmru;

  InterstitialAd? _interstitialAd;
  RewardedAd?     _rewardedAd;
  DateTime? _interstitialYuklendi;
  DateTime? _rewardedYuklendi;

  /// Hazır ödüllü reklam değişince arayüz (gelen kutusundaki "hemen aç" işareti) güncellenir.
  final ValueNotifier<bool> odulluHazir = ValueNotifier<bool>(false);
  bool _interstitialLoading = false;
  bool _rewardedLoading     = false;
  int _interstitialRetry = 0;
  int _rewardedRetry     = 0;
  bool _reklamDevam = false; // tam ekran reklam gösteriliyor → ikincisi başlamaz

  /// Admin modunda reklamlar tamamen devre dışı bırakılır.
  bool _adsDisabled = false;

  /// UMP sonucu: false iken hiçbir reklam istenmez.
  bool _canRequestAds = false;
  bool _sdkBasladi = false;
  bool _sdkHazir = false;
  int _rizaDenemesi = 0;
  static const _rizaBeklemeleri = [Duration(seconds: 30), Duration(minutes: 2), Duration(minutes: 10)];

  AdPacing? _pacing;

  /// Kalıcı sıklık sayaçları (initialize'da kurulur; testte elle verilebilir).
  AdPacing? get pacing => _pacing;
  @visibleForTesting
  set pacing(AdPacing? p) => _pacing = p;

  /// Admin mod toggle — settings admin panelinden veya godag bypass'tan çağrılır.
  void setAdsDisabled(bool value) => _adsDisabled = value;
  bool get adsDisabled => _adsDisabled;

  bool get canRequestAds => _canRequestAds;

  // ── Başlatma ────────────────────────────────────────────────────────────────

  /// Hızlı döner (uygulama açılışını bekletmez): sayaçları yükler, rıza + SDK başlatmayı arka planda sürdürür.
  Future<void> initialize() async {
    try {
      _pacing ??= AdPacing(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('[AdService] Sayaçlar yüklenemedi: $e');
    }
    _yasamDongusu ??= AppLifecycleListener(
      onHide: () => _arkaPlanBas = DateTime.now(),
      onShow: _onPlanaDondu,
      onResume: reklamlariTazele,
    );
    unawaited(_rizaVeBaslat());
  }

  AppLifecycleListener? _yasamDongusu;
  DateTime? _arkaPlanBas;

  /// Uzun arka plandan dönüş yeni oturumdur; yoksa oturum sınırı günlerce sıfırlanmazdı.
  void _onPlanaDondu() {
    final bas = _arkaPlanBas;
    _arkaPlanBas = null;
    if (bas != null && DateTime.now().difference(bas) >= AdPacing.oturumAraligi) {
      _pacing?.yeniOturum();
    }
  }

  /// Süresi dolanı atar, eksik reklamı yükler (uygulamaya dönüşte ve teklif öncesi).
  void reklamlariTazele() {
    if (_adsDisabled || !_canRequestAds || !_sdkHazir) return;
    final simdi = DateTime.now();
    if (!_reklamDevam) {
      final yg = _interstitialYuklendi;
      if (_interstitialAd != null && yg != null && suresiDoldu(yg, simdi)) {
        _interstitialAd!.dispose();
        _interstitialAd = null;
        _interstitialYuklendi = null;
      }
      final yo = _rewardedYuklendi;
      if (_rewardedAd != null && yo != null && suresiDoldu(yo, simdi)) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
        _rewardedYuklendi = null;
        odulluHazir.value = false;
      }
    }
    _loadInterstitial();
    _loadRewarded();
  }

  /// UMP: her açılışta bilgi güncellenir, gerekirse form gösterilir; hata olursa akış bozulmaz.
  Future<void> _rizaVeBaslat() async {
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
              if (e != null) debugPrint('[AdService] Rıza formu: ${e.message}');
              if (!done.isCompleted) done.complete();
            });
          } catch (e) {
            debugPrint('[AdService] Rıza formu hatası: $e');
            if (!done.isCompleted) done.complete();
          }
        },
        (FormError e) {
          debugPrint('[AdService] Rıza bilgisi alınamadı: ${e.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } catch (e) {
      debugPrint('[AdService] UMP hatası: $e');
    }
    await _rizaDurumunuYenile();
    // İnternet yokken ya da geçici hatada rıza bilinmez; o oturum reklamsız kalmasın.
    if (!_canRequestAds && _rizaDenemesi < _rizaBeklemeleri.length) {
      Timer(_rizaBeklemeleri[_rizaDenemesi++], () => unawaited(_rizaVeBaslat()));
    }
  }

  Future<void> _rizaDurumunuYenile() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      _canRequestAds = false;
      debugPrint('[AdService] canRequestAds okunamadı: $e');
    }
    if (!_canRequestAds) return;
    if (!_sdkBasladi) {
      _sdkBasladi = true;
      try {
        await MobileAds.instance.initialize();
        _sdkHazir = true;
      } catch (e) {
        debugPrint('[AdService] MobileAds başlatılamadı: $e');
        _sdkBasladi = false;
        return;
      }
    }
    if (kDebugMode) return; // emülatörde video codec crash — release'de yükle
    _loadInterstitial();
    _loadRewarded();
  }

  /// Kullanıcı Bilgileri 3. kart: UMP gizlilik seçenekleri gerekiyor mu?
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      final done = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {
        if (e != null) debugPrint('[AdService] Gizlilik seçenekleri: ${e.message}');
        if (!done.isCompleted) done.complete();
      });
      await done.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } catch (e) {
      debugPrint('[AdService] Gizlilik formu hatası: $e');
    }
    await _rizaDurumunuYenile();
  }

  // ── Interstitial ────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (kDebugMode || _adsDisabled || !_canRequestAds) return;
    if (_interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: _request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialYuklendi = DateTime.now();
          _interstitialLoading = false;
          _interstitialRetry = 0;
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          debugPrint('[AdService] Interstitial yüklenemedi: $err');
          if (_interstitialRetry < _retryDelays.length) {
            Timer(_retryDelays[_interstitialRetry++], _loadInterstitial);
          }
        },
      ),
    );
  }

  /// Doğal arada (fal kapanıp menüye dönerken) geçiş reklamı gösterir. Gösterildiyse true.
  /// Sınırlar [AdPacing]'den: 90 sn aralık, ödüllüden 120 sn, oturumda 3, günde 6, [tamamlananFal] ≥ 1.
  /// Hazır reklam yoksa ya da sınır doluysa sessizce false; hiçbir akışı bekletmez.
  Future<bool> maybeShowInterstitial({required int tamamlananFal, DateTime? now}) async {
    if (_adsDisabled || !_canRequestAds || _reklamDevam) return false;
    final pacing = _pacing;
    final t = now ?? DateTime.now();
    if (pacing == null || !pacing.canShowInterstitial(t, tamamlananFal: tamamlananFal)) return false;
    reklamlariTazele(); // süresi dolmuş reklam gösterilmesin
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitialAd = null;
    _reklamDevam = true;
    final completer = Completer<void>();
    void finish() {
      if (completer.isCompleted) return;
      completer.complete();
      _reklamDevam = false;
      _loadInterstitial();
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        debugPrint('[AdService] Interstitial gösterilemedi: $err');
        finish();
      },
    );
    var gosterildi = false;
    try {
      await pacing.recordInterstitial(t); // gösterim denemesi sayılır (üst üste denemeyi önler)
      await ad.show();
      gosterildi = true;
    } catch (e) {
      debugPrint('[AdService] Interstitial show hatası: $e');
      ad.dispose();
      finish();
    }
    return gosterildi;
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (kDebugMode || _adsDisabled || !_canRequestAds) return;
    if (_rewardedLoading || _rewardedAd != null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: _request(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedYuklendi = DateTime.now();
          _rewardedLoading = false;
          _rewardedRetry = 0;
          odulluHazir.value = true;
        },
        onAdFailedToLoad: (err) {
          _rewardedLoading = false;
          debugPrint('[AdService] Rewarded yüklenemedi: $err');
          if (_rewardedRetry < _retryDelays.length) {
            Timer(_retryDelays[_rewardedRetry++], _loadRewarded);
          }
        },
      ),
    );
  }

  /// Hazır bir ödüllü reklam var mı?
  bool get isRewardedReady => _rewardedAd != null;

  /// Bu ödül için teklif yapılabilir mi? Admin modunda her zaman true (ödül doğrudan verilir).
  /// Normalde: rıza var + hazır reklam var + kalıcı sınırlar uygun.
  ///
  /// Dokunuş anında çağrılır: reklam hazır değilse ya da süresi dolduysa yenisini ister.
  bool odulMumkun(OdulTuru tur, {String? falTuru}) {
    reklamlariTazele();
    return odulTeklifiHazir(tur, falTuru: falTuru);
  }

  /// Reklam yükleniyorsa kısa süre bekler: art arda dokunuşta teklif kaçmasın, kutu bedava açılmasın.
  Future<void> odulluBekle({Duration enFazla = const Duration(milliseconds: 2500)}) async {
    if (_adsDisabled || !_canRequestAds) return;
    reklamlariTazele(); // süresi dolmuş reklam "hazır" sayılmasın
    if (isRewardedReady) return;
    final bitis = DateTime.now().add(enFazla);
    while (_rewardedLoading && !isRewardedReady && DateTime.now().isBefore(bitis)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// [odulMumkun]'un yan etkisiz hâli (build içinde kullanılır).
  bool odulTeklifiHazir(OdulTuru tur, {String? falTuru}) {
    if (_adsDisabled) return true;
    if (!_canRequestAds || !isRewardedReady) return false;
    final pacing = _pacing;
    return pacing != null && pacing.canOfferReward(tur, DateTime.now(), falTuru: falTuru);
  }

  /// Ödüllü reklamı izletir. **true yalnız `onUserEarnedReward` geldiyse.** Kapatma/hata/hazır
  /// değil → false (ödül yok). Admin modunda reklam yok, ödül doğrudan verilir (true).
  Future<bool> showRewardedFor(OdulTuru tur, {String? falTuru}) async {
    if (_adsDisabled) return true;
    reklamlariTazele(); // teklif penceresi açıkken süresi dolmuş olabilir
    final pacing = _pacing;
    final ad = _rewardedAd;
    if (!_canRequestAds || _reklamDevam || pacing == null || ad == null ||
        !pacing.canOfferReward(tur, DateTime.now(), falTuru: falTuru)) {
      return false;
    }
    _rewardedAd = null;
    _rewardedYuklendi = null;
    odulluHazir.value = false;
    _reklamDevam = true;
    var earned = false;
    final completer = Completer<bool>();
    void finish() {
      if (completer.isCompleted) return;
      _reklamDevam = false;
      _loadRewarded();
      completer.complete(earned);
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        debugPrint('[AdService] Rewarded gösterilemedi: $err');
        earned = false;
        finish();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (e) {
      debugPrint('[AdService] Rewarded show hatası: $e');
      ad.dispose();
      earned = false;
      finish();
    }
    final sonuc = await completer.future;
    if (sonuc) await pacing.recordReward(tur, DateTime.now(), falTuru: falTuru);
    return sonuc;
  }
}
