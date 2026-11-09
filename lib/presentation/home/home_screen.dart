// ═════════════════════════════════════════════════════════════════════════════
// AI OTURUMU BAŞLANGIÇ REHBERİ — home_screen.dart
// Bu dosyayı okuyan bir LLM için: aşağıdaki açıklamalar proje mimarisini ve
// isimlendirme kurallarını özetler. Yeni bir oturumda bu bloğu oku.
// ═════════════════════════════════════════════════════════════════════════════
//
// ── SOHBET KUTUSU ───────────────────────────────────────────────────────
// Ana menünün üstünde alt barla aynı biçim ve camda tek satırlık kutu (home_chat_box.dart).
// Tek mesaj görünür; açılışta selamlama, sonra fal durumu / günlük limit mesajları
// (_say). Menüye dönüşte gelen mesaj 3 sn sonra, karta dokunuşa cevap anında.
//
// ── GÜNLÜK KREDİ SİSTEMİ ─────────────────────────────────────────────────
// Her aktif fal türü için günde 1 hak vardır. _remainingCredits map'i:
//   {'motivasyon': 0|1, 'olumlama': 0|1, 'ozlusoz': 0|1,
//    'tarot': 0|1, 'kahve': 0|1, 'astroloji': 0|1}
//
// Hak durumu SharedPreferences'tan okunur:
//   '{tür}_bugun_tarih' == bugünün ISO tarihi  →  kredi = 0 (kullanıldı)
//   farklı veya kayıt yok                     →  kredi = 1 (kullanılabilir)
//
// İkon rozeti: credits >= 0 → badge göster. credits = 1 → mavi yıldız.
//              credits = 0  → gri yıldız (kullanıldı).
//              credits = -1 → badge yok (kullanılmayan özel kod, şu an yok).
// Kilitli/pasif ikonlar: credits sabit 1 (henüz implemente edilmemiş).
// Aktif fal ikonuna tıklanınca kredi 0 ise → uyarı balonu göster, gitme.
// Aktif fal ikonuna tıklanınca kredi 1 ise → ekrana git (context.push),
//   dönüşte _refreshCredits() → eğer fal tamamlanmamışsa (geri basıldıysa)
//   date key set edilmemiştir, kredi otomatik 1'e döner.
//
// ── MENÜ YAPISI (tek ana menü) — Anıl, 2026-11-05 / 2026-11-08 ────────────
// Sayfa YOK; yukarıdan aşağı kaydırılır (_buildGrid). TEK düzen (menu_layout.dart):
// "Favoriler" 3×2 (en çok açılan 6) + "Diğer Türler" (27'nin tamamı, büyük ikonlu dizilim).
// Varsayılan sıra = eski sayfa 1 + 2 + 3 (_page1Items/_page2Items/_page3Items); kart rengi
// eski sayfa rengini korur (pembe / mavi / yeşil).
// Izgara cam barın ARKASINA uzanır (alt pay = güvenli alan + bar). Sayfa göstergesi
// ve hazırlanan fal yuvarlakları kaldırıldı; fal durumu bardaki zarf rozetinde.
// Sola kaydırma (yatay > dikey×1.5) → gelen kutusu. Bardaki eve tekrar dokunuş →
// liste başa kayar (mainTabReselectProvider).
//
// ── UNITY .ASSET DÖNÜŞÜM NOTU (metin motoru) ─────────────────────────────
// Unity .asset dosyalarında `aciklama:` ve `element:` alanları YAML LİSTESİDİR.
// Tek bir .asset dosyasında birden fazla `- "..."` maddesi olabilir.
// Her madde AYRI bir JSON girdisi olmalı — sadece ilk maddeyi almak veri kaybı!
// Etkilenen klasörler: Motivasyon, Ozlusoz, AstroTakvim, GunlukAstroloji,
//   Biyoritim, CanliSohbet, JaponFali, KaderKitabi (ve muhtemelen diğerleri).
// Parse kodu: her `- "..."` başlangıcında yeni entry aç, devam satırlarını
//   (4+ boşluklu) önceki entry'ye birleştir. Bkz. CLAUDE.md → "Kaynak Yapısı".
//
// ── NAVIGASYON ────────────────────────────────────────────────────────────
// Router: go_router. Ana rotalar:
//   /home → HomeScreen   /motivation → MotivationScreen
//   /olumlama → OlumlamaScreen   /ozlusoz → OzluSozScreen
//   /tarot → TarotTypeScreen   /coffee → CoffeeScreen
//   /astrology → AstrologyScreen   /settings → SettingsScreen
//   /inbox-full → InboxFullScreen
//
// Tarot akışı: /tarot → TarotTypeScreen → tip seçimi → TarotScreen (klasik)
//              veya SingleTarotScreen (aşk/dilek/şans).
//              Fal gönderilince tarotSentProvider=true, context.go('/home').
//
// ── KULLANICI PROFİLİ ─────────────────────────────────────────────────────
// userProfileProvider (Riverpod) → UserProfile modeli.
// Alanlar: name, age, gender ('erkek'/'kadin'/'lgbt'), job, maritalStatus,
//          birthDate (YYYY-MM-DD), birthCity, zodiacSign, birthTime (HH:MM),
//          risingSign, moonSign, planet, profilePicIndex, customPhotoPath.
// toVariableMap() → {{isim}}, {{yas}}, {{meslek}}, {{medeni_durum}} vb.
//   placeholder'larını gerçek veriye çevirir (VariableReplacer.replace()).
// Türkçe çekim ekleri: {{isime}}, {{isimi}}, {{isimden}}, {{isimcigim}}.
//
// ── ADMIN PANELİ ─────────────────────────────────────────────────────────
// Kullanıcı Bilgileri ekranında sol üstte yönetici ikonu — yönetici kapısı
// lib/core/utils/admin_gate.dart (kişisel veri içermez). Admin panelinde günlük
// hakları sıfırlama butonu bulunur.
//
// ═════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/sonuc_reklami.dart';
import '../../core/widgets/bir_tane_daha.dart';
import '../../data/models/inbox_item.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/magnus_ses/magnus_fal_adlari.dart';
import '../../core/magnus_ses/magnus_hafiza.dart';
import '../../core/magnus_ses/magnus_rota_gozlemci.dart';
import '../../core/magnus_ses/magnus_ses.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../core/widgets/startup_disclaimer.dart';
import '../../core/widgets/tab_swipe.dart';
import '../../core/widgets/word_safe_text.dart';
import '../../data/providers.dart';
import '../shell/main_tabs.dart';
import 'home_chat_box.dart';
import 'menu_layout.dart';

/// Ana menünün (menu layer 1, ikonlar) düz arka plan rengi (Anıl'ın örneği: rgb 12,15,20).
const Color kHomeBackground = Color(0xFF0C0F14);

/// Sohbet kutusunun güvenli alandan uzaklığı ve kutu ile menü arası.
const double kHomeChatTop = 6;
const double kHomeChatGap = 10;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Tek ana menü (Anıl, 2026-11-05): 3 sütun × 9 satır, yukarıdan aşağı kaydırmalı.
  final ScrollController _gridScrollCtrl = ScrollController();

  final GlobalKey<HomeChatBoxState> _chatBox = GlobalKey<HomeChatBoxState>();
  final List<String> _chatPending = [];
  // Açılışta perde kalkınca açılır. Mesajlar beklemeden gelir (Anıl, 2026-11-09: 3 sn gecikmeler kaldırıldı).
  bool _chatGateOpen = false;
  bool _greeted = false;
  VoidCallback? _perdeDinleyici; // açılış perdesi kalkınca sohbeti açar
  String _selamlama = ''; // async yüklenir

  // Magnus'un sesi: hafıza + seçim beyni (core/magnus_ses).
  MagnusHafiza? _hafiza;
  MagnusSes? _ses;
  late final AppLifecycleListener _yasam;
  DateTime _oturumBas = DateTime.now();
  DateTime? _arkaPlanBas;
  String? _falGirisUstId; // fala girerken gelen kutusunun en üstündeki öğe
  DateTime? _onemliMesajAni; // fal durumu / hak mesajı yakın zamanda söylendi

  /// Arka planda bu kadar kaldıysa dönüş yeni bir "geliş" sayılır.
  static const _yeniGelisEsigi = Duration(seconds: 60);

  MagnusBaglam _baglam() => MagnusBaglam(
        now: DateTime.now(),
        profile: ref.read(userProfileProvider),
        isEn: ref.read(localeProvider) == 'en',
        gelenKutusu: ref.read(inboxProvider),
        oturumSaniye: DateTime.now().difference(_oturumBas).inSeconds,
      );

  bool get _menuGorunur =>
      mounted &&
      ref.read(mainTabProvider) == MainTab.home &&
      !Navigator.of(context, rootNavigator: true).canPop();

  /// Magnus şimdi kendiliğinden konuşabilir mi? Metin seçilmeden ÖNCE bakılır: söylenmeyen söz
  /// tekrarsız listeye yazılmasın, tek seferlik sözler boşa gitmesin.
  bool get _sesKonusabilir {
    if (!_menuGorunur || !_chatGateOpen || _chatPending.isNotEmpty) return false;
    final an = _onemliMesajAni;
    return an == null || DateTime.now().difference(an) > const Duration(seconds: 7);
  }

  void _sesSoyle(String? metin) {
    if (metin != null && mounted) _chatBox.currentState?.say(metin, now: true);
  }

  void _sekmeDonus(int onceki) {
    final kaynak = onceki == MainTab.inbox ? DonusKaynagi.gelenKutusu : DonusKaynagi.profil;
    Timer(const Duration(milliseconds: 400), () {
      final ses = _ses;
      if (ses == null || !_sesKonusabilir) return;
      _sesSoyle(ses.sekmeDonus(_baglam(), kaynak));
    });
  }

  void _falGirdi(String tur) {
    _hafiza?.falGirdi(tur, DateTime.now());
    final kutu = ref.read(inboxProvider);
    _falGirisUstId = kutu.isEmpty ? null : kutu.first.id;
  }

  void _falCikti(String tur, Duration sure) {
    final hafiza = _hafiza, ses = _ses;
    // Geçiş reklamı yalnız fal gelen kutusuna gönderilip uygulama kendiliğinden menüye dönerken
    // (reklam.md). Fal türünden geri tuşuyla menüye dönüşte YOK (Anıl, 2026-11-09). Sınırlar
    // AdPacing'de; hazır reklam yoksa sessizce atlanır.
    final hedef = MagnusRotaGozlemci.sonHedefRota;
    final ustKutu = mounted ? ref.read(inboxProvider) : const <InboxItem>[];
    final kutuyaDustu = ustKutu.isNotEmpty && ustKutu.first.id != _falGirisUstId;
    if (mounted &&
        !kSonucOncesiReklam &&
        kutuyaDustu &&
        AdPacing.dogalAraMi(tur, sure,
            menuyeDonuyor: hedef == null || hedef == '/home', kutuyaDustu: true)) {
      unawaited(AdService.instance.maybeShowInterstitial(tamamlananFal: hafiza?.tamamlananFal ?? 0));
    }
    if (hafiza == null || ses == null || !mounted) return;
    // Sonuç mesajları (hazırlanıyor, hak bitti) ekran kapandıktan hemen sonra gelir; biraz beklenir.
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final kutu = ref.read(inboxProvider);
      final tamam = kutu.isNotEmpty && kutu.first.id != _falGirisUstId;
      final esik = kAnlikFallar.contains(tur) ? 6 : 20;
      final vazgecti = !tamam && sure.inSeconds < esik && _menuGorunur && _chatPending.isEmpty;
      // Sonucu ekranda gösteren fal yeterince açık kaldıysa "tamamlanan fal" sayılır (reklam eşiği).
      if (!tamam && kAnlikFallar.contains(tur) && sure >= AdPacing.sonucGorulduMinSure) {
        hafiza.falTamamlandi();
      }
      hafiza.falCikti(tur, DateTime.now(), vazgecti: vazgecti, tamam: tamam);
      if (_sesKonusabilir) _sesSoyle(ses.falDonus(_baglam(), tur, sure, vazgecti: vazgecti));
    });
  }

  void _arkaPlanaGecti() {
    final now = DateTime.now();
    _arkaPlanBas = now;
    _hafiza?.sureEkle(now.difference(_oturumBas), now);
  }

  void _onPlanaGeldi() {
    final now = DateTime.now();
    final bas = _arkaPlanBas;
    if (bas == null) return; // bildirim perdesi gibi kısa kesintide oturum sürer
    _arkaPlanBas = null;
    _oturumBas = now;
    final hafiza = _hafiza, ses = _ses;
    if (hafiza == null || ses == null) return;
    if (now.difference(bas) < _yeniGelisEsigi) return;
    final bilgi = hafiza.girisKaydet(now);
    Timer(const Duration(milliseconds: 1200), () {
      if (!_sesKonusabilir) return;
      _sesSoyle(ses.giris(_baglam(), bilgi));
    });
  }

  /// Az önce hazır olan fal varsa haber verir.
  void _hazirOlaniSoyle() {
    final ses = _ses;
    if (ses == null || !_sesKonusabilir) return;
    final now = DateTime.now();
    for (final i in ref.read(inboxProvider)) {
      final an = DateTime.tryParse(i.unlockAt ?? '');
      if (an == null || i.isRead || i.isLocked) continue;
      if (now.difference(an).inSeconds < 90) {
        _sesSoyle(ses.hazirOldu(_baglam(), i));
        return;
      }
    }
  }

  /// Magnus'un yeni mesajı.
  void _say(String text) {
    if (!mounted) return;
    if (_chatGateOpen) {
      _onemliMesajAni = DateTime.now();
      _chatBox.currentState?.say(text, now: true);
      return;
    }
    _chatPending.add(text); // perde kalkınca söylenir
    if (_perdeDinleyici == null) _kapiyiAc();
  }

  void _flushChat() {
    final box = _chatBox.currentState;
    if (box == null) return;
    if (_chatPending.isNotEmpty) _onemliMesajAni = DateTime.now();
    _chatPending.forEach(box.say);
    _chatPending.clear();
  }

  void _selamla() {
    if (_greeted || _selamlama.isEmpty) return;
    _greeted = true;
    _chatBox.currentState?.say(_selamlama);
  }

  void _selamlamaHazir(String metin) {
    _selamlama = metin;
    if (_chatGateOpen) _selamla();
  }

  // Günlük kalan kredi: 1 = hak var, 0 = kullanıldı
  Map<String, int> _remainingCredits = {};

  // Kilit açılma zamanlayıcısı — en erken unlockAt'e göre kurulur
  Timer? _unlockTimer;

  /// Hak bitince ödüllü +1 hak teklif edilen türler (docs/reklam_duzeni.md). Diğerlerinde ek hak yok.
  static const _odulluHakTurleri = {
    'kahve', 'tarot', 'dertortagi', 'acigercekler', 'askuyumu',
    'iching', 'japonfali', 'tavsanfali', 'kadercarki',
    // Durugörü: hak soru başına, teklif kendi ekranında (durugoru_screen.dart).
  };

  // Pref anahtarları — her fal türü için tamamlanma tarihi
  static const _creditPrefKeys = {
    'motivasyon':  'motivasyon_bugun_tarih',
    // 'olumlama' günlük limit yok — badge gösterilmez
    'ozlusoz':     'ozlusoz_bugun_tarih',
    'tarot':       'tarot_bugun_tarih',
    'kahve':       'kahve_bugun_tarih',
    'astroloji':   'astroloji_bugun_tarih',
    'kaderkitabi': 'kaderkitabi_bugun_tarih',
    'dertortagi':   'dertortagi_bugun_tarih',
    'acigercekler': 'acigercekler_bugun_tarih',
    'durugoru':     'durugoru_bugun_tarih',
    'iching':       'iching_bugun_tarih',
    'japonfali':    'japonfali_bugun_tarih',
    'tavsanfali':   'tavsanfali_bugun_tarih',
    'kadercarki':   'kadercarki_bugun_tarih',
    'askuyumu':     'askuyumu_bugun_tarih',
    // 'numeroloji' burada yok — limit ekran içinden yönetilir
  };

  String get _today => DateTime.now().toIso8601String().substring(0, 10);


  bool _selamlamaYuklendi = false;

  @override
  void initState() {
    super.initState();
    _yasam = AppLifecycleListener(onPause: _arkaPlanaGecti, onResume: _onPlanaGeldi);
    MagnusRotaGozlemci.girdi = _falGirdi;
    MagnusRotaGozlemci.cikti = _falCikti;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleUnlockTimer();
      _refreshCredits();
      _checkTarotSent();
      _checkKahveSent();
      _checkDurugoruSent();
      _checkRuyaSent();
      _checkIchingSent();
      _checkJaponFaliSent();
      _checkElFaliSent();
      _checkYuzFaliSent();
    });
  }

  void _checkTarotSent() {
    final sent = ref.read(tarotSentProvider);
    if (!sent) return;
    ref.read(tarotSentProvider.notifier).state = false;
    // Tarot tamamlandı → günlük krediyi işaretle
    SharedPreferences.getInstance().then((p) {
      p.setString('tarot_bugun_tarih', _today);
      _refreshCredits();
    });
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).tarotSentBubble(name));
  }

  void _checkKahveSent() {
    final sent = ref.read(kahveSentProvider);
    if (!sent) return;
    ref.read(kahveSentProvider.notifier).state = false;
    // Kahve falı tamamlandı → günlük krediyi işaretle
    SharedPreferences.getInstance().then((p) {
      p.setString('kahve_bugun_tarih', _today);
      _refreshCredits();
    });
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).kahveSentBubble(name));
  }

  void _checkDurugoruSent() {
    final sent = ref.read(durugoruSentProvider);
    if (!sent) return;
    ref.read(durugoruSentProvider.notifier).state = false;
    _refreshCredits();
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).durugoruSentBubble(name));
  }

  void _checkRuyaSent() {
    final sent = ref.read(ruyaSentProvider);
    if (!sent) return;
    ref.read(ruyaSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).ruyaSentBubble(name));
  }

  void _checkIchingSent() {
    final sent = ref.read(ichingSentProvider);
    if (!sent) return;
    ref.read(ichingSentProvider.notifier).state = false;
    // I-Ching günlük krediyi işaretle
    SharedPreferences.getInstance().then((p) {
      p.setString('iching_bugun_tarih', _today);
      _refreshCredits();
    });
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).ichingSentBubble(name));
  }

  void _checkJaponFaliSent() {
    final sent = ref.read(japonFaliSentProvider);
    if (!sent) return;
    ref.read(japonFaliSentProvider.notifier).state = false;
    // Japon Falı günlük krediyi işaretle
    SharedPreferences.getInstance().then((p) {
      p.setString('japonfali_bugun_tarih', _today);
      _refreshCredits();
    });
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).japonSentBubble(name));
  }

  void _checkElFaliSent() {
    final sent = ref.read(elFaliSentProvider);
    if (!sent) return;
    ref.read(elFaliSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).elFaliSentBubble(name));
  }

  void _checkYuzFaliSent() {
    final sent = ref.read(yuzFaliSentProvider);
    if (!sent) return;
    ref.read(yuzFaliSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    _say(ref.read(l10nProvider).yuzFaliSentBubble(name));
  }

  bool _listenersAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_selamlamaYuklendi) {
      _selamlamaYuklendi = true;
      // Selamlama JSON'u arka planda yüklenir; menü GÖRÜNÜR görünmez kutuda belirir.
      // ⚠️ Her açılışta 6 sn'lik yasal perde menünün ÜSTÜNDE durur; sohbet perde KALKINCA açılır.
      _loadSelamlama();
      _acilisBandiniPlanla();
    }
    if (!_listenersAttached) {
      _listenersAttached = true;
      ref.listenManual(tarotSentProvider, (_, sent) {
        if (sent) _checkTarotSent();
      });
      ref.listenManual(kahveSentProvider, (_, sent) {
        if (sent) _checkKahveSent();
      });
      ref.listenManual(durugoruSentProvider, (_, sent) {
        if (sent) _checkDurugoruSent();
      });
      ref.listenManual(ruyaSentProvider, (_, sent) {
        if (sent) _checkRuyaSent();
      });
      ref.listenManual(ichingSentProvider, (_, sent) {
        if (sent) _checkIchingSent();
      });
      ref.listenManual(japonFaliSentProvider, (_, sent) {
        if (sent) _checkJaponFaliSent();
      });
      ref.listenManual(elFaliSentProvider, (_, sent) {
        if (sent) _checkElFaliSent();
      });
      ref.listenManual(yuzFaliSentProvider, (_, sent) {
        if (sent) _checkYuzFaliSent();
      });
    }
  }

  /// Açılış selamlaması: menü görünür olur olmaz (açılış perdesi kalkınca).
  void _kapiyiAc() {
    void ac() {
      if (!mounted) return;
      _chatGateOpen = true;
      _selamla();
      _flushChat();
    }

    if (_chatBox.currentState != null) {
      ac();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => ac()); // kutu ilk karede kurulur
    }
  }

  void _acilisBandiniPlanla() {
    if (!StartupDisclaimer.perdeAcik.value) {
      _kapiyiAc();
      return;
    }
    late final VoidCallback dinle;
    dinle = () {
      if (StartupDisclaimer.perdeAcik.value) return;
      StartupDisclaimer.perdeAcik.removeListener(dinle);
      _perdeDinleyici = null;
      if (mounted) _kapiyiAc();
    };
    _perdeDinleyici = dinle;
    StartupDisclaimer.perdeAcik.addListener(dinle);
  }

  @override
  void dispose() {
    final d = _perdeDinleyici;
    if (d != null) StartupDisclaimer.perdeAcik.removeListener(d);
    _unlockTimer?.cancel();
    _yasam.dispose();
    MagnusRotaGozlemci.girdi = null;
    MagnusRotaGozlemci.cikti = null;
    _gridScrollCtrl.dispose();
    super.dispose();
  }

  /// En erken kilitli tarot öğesine göre timer kur.
  /// Timer ateşlenince Riverpod state'i rebuild etmek için invalidate et.
  void _scheduleUnlockTimer() {
    _unlockTimer?.cancel();
    final items = ref.read(inboxProvider);
    DateTime? earliest;
    for (final item in items) {
      if (item.unlockAt == null) continue;
      try {
        final t = DateTime.parse(item.unlockAt!);
        if (t.isAfter(DateTime.now())) {
          if (earliest == null || t.isBefore(earliest)) earliest = t;
        }
      } catch (_) {}
    }
    if (earliest == null) return;
    final delay = earliest.difference(DateTime.now());
    if (delay.isNegative) return;
    _unlockTimer = Timer(delay, () {
      if (!mounted) return;
      // inboxProvider'ı yenile → readyUnreadCountProvider → flare yansır
      ref.invalidate(inboxProvider);
      setState(() {});
      _hazirOlaniSoyle();
      _scheduleUnlockTimer(); // sonraki kilit için tekrar kur
    });
  }


  // ─── Günlük kredi yükleme ─────────────────────────────────────────────────
  Future<void> _refreshCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today;
    if (!mounted) return;
    setState(() {
      _remainingCredits = {
        for (final e in _creditPrefKeys.entries)
          e.key: (prefs.getString(e.value) == today) ? 0 : 1,
      };
    });
  }

  // ─── Birleşik fal tıklama yöneticisi ─────────────────────────────────────
  Future<void> _onFortuneItemTap(String type, String route) async {
    final remaining = _remainingCredits[type] ?? 1;
    if (remaining <= 0) {
      // Hak bitti: docs'taki türlerde ödüllü +1 hak teklifi (kullanıcı seçerse); sınır dolu ya da
      // reklam hazır değilse eski mesaj.
      if (await _hakTeklifiCozuldu(type, () => _onFortuneItemTap(type, route))) return;
      if (!mounted) return;
      _showDailyLimitBubble(type);
      return;
    }
    if (!mounted) return;
    if (_acilirAcilmazReklamli.contains(type)) {
      if (_girisReklami) return;
      _girisReklami = true;
      try {
        await sonucOncesiReklam();
      } finally {
        _girisReklami = false;
      }
      if (!mounted) return;
    }
    final result = await context.push<String?>(route);
    if (!mounted) return;
    if (result == kBirTaneDaha) {
      await _refreshCredits(); // sonuç ekranında reklam izlendi, hak verildi → fal yeniden açılır
      if (mounted) await _onFortuneItemTap(type, route);
      return;
    }
    if (result == 'hazirlanıyor') {
      _showHazirlaniyorBubble(type);
    } else if (result == 'zaten_okundu') {
      // Kader Kitabı o gün okunmuşsa "okudun" mesajı kitapta DEĞİL, ana menü sohbetinde
      // söylenir (Anıl, 2026-11-06). Ekran kendini kapatıp bu sonucu döndürür.
      _showDailyLimitBubble(type);
    }
    await _refreshCredits();
  }

  /// Hak bitti: ödüllü +1 hak teklif edilebiliyorsa teklif eder, true döner (eski mesaj gösterilmez).
  /// Kullanıcı ödülü kazanırsa o türün "bugün aldın" tarihi silinir ve [devam] çalışır.
  Future<bool> _hakTeklifiCozuldu(String type, Future<void> Function() devam) async {
    final anahtar = _creditPrefKeys[type];
    if (anahtar == null) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return true;
    // Ekrandaki sayaç eski olabilir (uygulama gece yarısını arka planda geçirdi): yeni günün hakkı
    // için reklam istenmez.
    if (prefs.getString(anahtar) != _today) {
      await _refreshCredits();
      if (mounted) await devam();
      return true;
    }
    if (!_odulluHakTurleri.contains(type)) return false;
    if (_hakTeklifte) return true; // reklam beklenirken ikinci dokunuş
    _hakTeklifte = true;
    try {
      await AdService.instance.odulluBekle();
      if (!mounted) return true;
      if (!AdService.instance.odulMumkun(OdulTuru.hakBitti, falTuru: type)) return false;
      final kazandi = await ref.hakBittiTeklifi(context, type);
      if (!kazandi) return true;
      await prefs.remove(anahtar); // ekran kapanmış olsa da izlenen reklamın hakkı verilir
    } finally {
      _hakTeklifte = false;
    }
    if (!mounted) return true;
    await _refreshCredits();
    if (mounted) await devam();
    return true;
  }

  bool _hakTeklifte = false;

  // ─── Günlük limitli fallar (I-Ching, Japon Falı, Tavşan) — git/gel yok (go) ──
  Future<void> _onDailyFalTap(String type, String route) async {
    final remaining = _remainingCredits[type] ?? 1;
    if (remaining <= 0) {
      if (await _hakTeklifiCozuldu(type, () => _onDailyFalTap(type, route))) return;
      if (!mounted) return;
      _showDailyLimitBubble(type);
      return;
    }
    // Dönüşte rozeti yenile (Tavşan Falı gibi ekranda tamamlanan fallar için).
    context.push<String?>(route).then((sonuc) async {
      if (!mounted) return;
      await _refreshCredits();
      if (sonuc == kBirTaneDaha && mounted) await _onDailyFalTap(type, route);
    });
  }

  // ─── Navigasyon yardımcısı ────────────────────────────────────────────────
  Future<void> _pushDirekt(String route) async {
    if (!mounted) return;
    await context.push(route);
  }

  /// Ritüeli olmayan, sonucu hemen gösteren türler: önce reklam, kapanınca fal (reklam.md).
  Future<void> _reklamlaGir(String route) async {
    if (_girisReklami) return;
    _girisReklami = true;
    try {
      await sonucOncesiReklam();
    } finally {
      _girisReklami = false;
    }
    await _pushDirekt(route);
  }

  bool _girisReklami = false;

  /// Hak kullanan ama ritüeli olmayan türler.
  static const _acilirAcilmazReklamli = {'olumlama', 'ozlusoz', 'kaderkitabi'};

  void _showHazirlaniyorBubble(String type) {
    final msg = ref.read(l10nProvider).hazirlaniyorMessage(type);
    _say(msg);
  }

  void _showDailyLimitBubble(String type) {
    final s           = ref.read(l10nProvider);
    final name        = ref.read(userProfileProvider).name;
    final fortuneName = s.fortuneDisplayName(type);
    final customMsg   = s.fortuneLimitMessage(type);
    final limitText   = customMsg ?? s.dailyLimitBubble(fortuneName, name);
    _say(limitText);
  }

  // ─── Satır 1-3 (eski sayfa 1) ───────────────────────────────────────────────
  List<_MenuItem> _page1Items(BuildContext context) {
    final s = ref.read(l10nProvider);
    return [
        _MenuItem(s.coffeeFortune, 'assets/images/menu/ozelfal.png',
            _remainingCredits['kahve'] ?? 1,
            () => _onFortuneItemTap('kahve', '/coffee')),
        _MenuItem(s.tarot, 'assets/images/menu/tarot.png',
            _remainingCredits['tarot'] ?? 1,
            () => _onFortuneItemTap('tarot', '/tarot')),
        _MenuItem(s.astrology, 'assets/images/astroloji.png',
            -1, () => _reklamlaGir('/astroloji')),
        _MenuItem(s.numerology, 'assets/images/menu/numeroloji.png',
            -1,
            () => _onFortuneItemTap('numeroloji', '/numeroloji')),
        _MenuItem(s.durugoru, 'assets/images/menu/durugoru.png',
            _remainingCredits['durugoru'] ?? 1,
            () => _onFortuneItemTap('durugoru', '/durugoru')),
        _MenuItem(s.faceFortune, 'assets/images/menu/yuzfali.png', 1,
            () => _pushDirekt('/yuz_fali_kimin')),
        _MenuItem(s.palmReading, 'assets/images/menu/elfali.png', 1,
            () => _pushDirekt('/el_fali')),
        _MenuItem(s.astroCalendar, 'assets/images/aytakvimi.png',
            -1, () => _reklamlaGir('/astrotakvim')),
        _MenuItem(s.biorhythm, 'assets/images/falbg/biyoritim.png',
            -1, () => _reklamlaGir('/biyoritim')),
      ];
  }

  // ─── Satır 4-6 (eski sayfa 2) ───────────────────────────────────────────────
  List<_MenuItem> _page2Items(BuildContext context) {
    final s = ref.read(l10nProvider);
    return [
        _MenuItem(s.motivation, 'assets/images/motivasyon_yeni.png',
            -1,
            () async {
              await _reklamlaGir('/motivation');
              if (!mounted) return;
              await _refreshCredits();
            }),
        _MenuItem(s.companion, 'assets/images/menu/dertortagi.png',
            _remainingCredits['dertortagi'] ?? 1,
            () => _onFortuneItemTap('dertortagi', '/dertortagi')),
        _MenuItem(s.affirmation, 'assets/images/olumlama.png',
            -1,
            () => _onFortuneItemTap('olumlama', '/olumlama')),
        _MenuItem(s.quotes, 'assets/images/ozlusozler.png',
            -1,
            () => _onFortuneItemTap('ozlusoz', '/ozlusoz')),
        _MenuItem(s.bitterTruths, 'assets/images/acigercekler.PNG',
            _remainingCredits['acigercekler'] ?? 1,
            () => _onFortuneItemTap('acigercekler', '/acigercekler')),
        _MenuItem(s.fatebook, 'assets/images/tefeulyeni.png',
            _remainingCredits['kaderkitabi'] ?? 1,
            () => _onFortuneItemTap('kaderkitabi', '/kaderkitabi')),
        _MenuItem(s.prophecy, 'assets/images/menu/kehanet.png', 1,
            () => _onFortuneItemTap('kehanet', '/kehanet')),
        _MenuItem(s.intention, 'assets/images/menu/mistikfallar.png', 1,
            () => _pushDirekt('/niyet')),
        _MenuItem(s.japaneseFortune, 'assets/images/japonfali.png',
            _remainingCredits['japonfali'] ?? 1,
            () => _onDailyFalTap('japonfali', '/japonfali')),
      ];
  }

  // ─── Satır 7-9 (eski sayfa 3) ───────────────────────────────────────────────
  List<_MenuItem> _page3Items(BuildContext context) {
    final s = ref.read(l10nProvider);
    return [
        _MenuItem(s.iching, 'assets/images/ichingikon.png',
            _remainingCredits['iching'] ?? 1,
            () => _onDailyFalTap('iching', '/iching')),
        _MenuItem(s.loveCompatibility, 'assets/images/askuyumu.png',
            _remainingCredits['askuyumu'] ?? 1,
            () => _onFortuneItemTap('askuyumu', '/ask_uyumu')),
        _MenuItem(s.wheelOfFate, 'assets/images/kadercarkimenu.png',
            _remainingCredits['kadercarki'] ?? 1,
            () => _onFortuneItemTap('kadercarki', '/kadercarki')),
        _MenuItem(s.dreamReading, 'assets/images/menu/ruyaozel.png', 1,
            () => _pushDirekt('/ruya_yorumu')),
        // Rüya Yorumu ile Doğum Haritası arası: Tavşan Falı (günde 1, 2026-11-05)
        _MenuItem(s.rabbitFortune, 'assets/images/tavsanfali/tavsanfali_menu.jpg',
            _remainingCredits['tavsanfali'] ?? 1,
            () => _onDailyFalTap('tavsanfali', '/tavsanfali')), // günde 1: bugün çektiyse balon (Anıl)
        _MenuItem(s.birthChart, 'assets/images/dogum.png',
            1, () => _reklamlaGir('/dogumharitasi')),
        // Rüya Yorumu'nun altı: Kısmetim Kim? (2026-11-05)
        _MenuItem(s.whoIsMyDestiny, 'assets/images/kismetim/kismetim_menu.jpg', 1,
            () => _pushDirekt('/kismetim')),
        // Kısmetim'in sağı: Arabam Ne? (2026-11-05)
        _MenuItem(s.whatIsMyCar, 'assets/images/arabam/arabam_menu.jpg', 1,
            () => _pushDirekt('/arabam')),
        // Arabam'ın sağı (son yer): Evim Neresi? (2026-11-05)
        _MenuItem(s.whereIsMyHome, 'assets/images/evim/evim_menu.jpg', 1,
            () => _pushDirekt('/evim')),
      ];
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider); // profil değişince rebuild tetikle
    ref.watch(localeProvider);      // dil değişince menü etiketleri + balonlar yenilensin

    // Sekme değişimleri (eskiden push/pop dönüşünde yapılan işler):
    //  - Ana menüden çıkarken kilit zamanlayıcısını tazele (eski: bilgi butonu basışı).
    //  - Kullanıcı Bilgileri'nden dönünce günlük hakları yenile (admin reset vb.).
    ref.listen<int>(mainTabProvider, (prev, next) {
      if (next != MainTab.home) _scheduleUnlockTimer();
      // Ana menüye HER dönüşte (Codex: ayarlar→reset→inbox→ana menü yolu kaçıyordu).
      if (next == MainTab.home && prev != MainTab.home && mounted) {
        _refreshCredits();
        if (prev != null) _sekmeDonus(prev);
      }
    });
    // Ana menüdeyken bardaki eve tekrar dokunuş → listenin başına kaydır (iOS alışkanlığı).
    // Yalnız ana menü görünürken (başka sekmeye tekrar dokunuş listeyi başa sarmasın).
    // Dil değişince kutuda eski dilde yazı kalmasın.
    // Yeni fal gelince kilit zamanlayıcısı kurulsun (hazır olunca haber vermek için).
    ref.listen(inboxProvider, (_, __) => _scheduleUnlockTimer());
    ref.listen<String>(localeProvider, (prev, next) {
      if (prev == next) return;
      final name = ref.read(userProfileProvider).name;
      _chatBox.currentState
        ?..clear()
        ..say(next == 'en'
            ? (name.isNotEmpty ? 'Welcome $name!' : 'Welcome!')
            : (name.isNotEmpty ? 'Hoş geldin $name!' : 'Hoş geldin!'));
    });
    ref.listen<int>(mainTabReselectProvider, (_, __) {
      if (ref.read(mainTabProvider) == MainTab.home) _scrollGridToTop();
    });

    // ── Ana menü arka planı: DÜMDÜZ koyu renk (Anıl, 2026-11-05 "ikonların olduğu yerden
    // background'u kaldırıp bg'yi dümdüz bu renk yap" — örnek görselden ölçüldü #0C0F14).
    // Eski welcomscreenbackground.jpg + %42 karartma kaldırıldı.
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: kHomeBackground,
      extendBody: true,
      body: Stack(
        children: [
          // ── Menu layer 1: tek ana menü, 3×9, yukarıdan aşağı kaydırmalı ─────
          // Alt kenar SafeArea'ya kesilmez: ızgara cam barın ARKASINA kadar uzanır.
          // Sola kaydırma → gelen kutusu (barda ana menünün sağındaki sekme).
          // Yön kilitli: dikey kaydırma bir kez başladıysa sekme değişmez.
          Positioned.fill(
            child: TabSwipe(
              onSwipeLeft: () =>
                  selectMainTab(context, MainTab.inbox, entry: TabEntry.right),
              child: _buildGrid(
                context,
                topExtra: topInset + kHomeChatTop + kGlassBarHeight + kHomeChatGap,
              ),
            ),
          ),
          // ── Sohbet kutusu: alt barla aynı biçim ve cam, menü ARKASINDAN kayar ────
          Positioned(
            top: topInset + kHomeChatTop,
            left: kGlassBarSide,
            right: kGlassBarSide,
            height: kGlassBarHeight,
            child: HomeChatBox(key: _chatBox, tint: ref.watch(glassTintProvider)),
          ),
        ],
      ),
    );
  }

  /// Eski sayfa renkleri: her 3 satırlık grup kendi çerçeve rengini korur
  /// (satır 1-3 pembe, 4-6 mavi, 7-9 yeşil).
  static const _groupColors = [
    Color(0xFFDD00CC), // eski sayfa 1 — pembe
    Color(0xFF0099FF), // eski sayfa 2 — mavi
    Color(0xFF00CC77), // eski sayfa 3 — yeşil
  ];

  void _scrollGridToTop() {
    if (!mounted || !_gridScrollCtrl.hasClients) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce || !TickerMode.valuesOf(context).enabled) {
      _gridScrollCtrl.jumpTo(0);
    } else {
      _gridScrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  /// Menü (Anıl, 2026-11-08): tek düzen — Favoriler + büyük ikonlu Diğer Türler (menu_layout.dart).
  Widget _buildGrid(BuildContext context, {required double topExtra}) {
    final base = [
      ..._page1Items(context),
      ..._page2Items(context),
      ..._page3Items(context),
    ];
    SharedPreferences? prefs;
    try {
      prefs = ref.read(sharedPrefsProvider);
    } catch (_) {}
    // Her dokunuş kullanım sayımına yazılır (Favoriler sıralaması bir SONRAKİ açılışta).
    final items = [
      for (final it in base)
        _MenuItem(it.title, it.imagePath, it.credits, () {
          MenuUsage.increment(prefs, it.imagePath);
          it.onTap();
        }),
    ];
    Color colorOf(int i) => _groupColors[(i ~/ 9).clamp(0, _groupColors.length - 1)];
    final ids = [for (final it in items) it.imagePath];

    // Son satır cam barın üstünde rahatça görünsün: alt güvenli alan + bar + nefes payı.
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + kGlassBarGap + kGlassBarHeight + 14;
    const gap = 8.0;
    const grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      childAspectRatio: 0.75,
    );
    Widget cells(List<int> idx) => SliverGrid(
          gridDelegate: grid,
          delegate: SliverChildBuilderDelegate(
            (context, k) => _MenuCard(item: items[idx[k]], color: colorOf(idx[k])),
            childCount: idx.length,
          ),
        );
    Widget space(double h) => SliverToBoxAdapter(child: SizedBox(height: h));
    // Büyük ikon: 3×3 hücre kadar (en = 3 hücre + 2 aralık, boy = 3 hücre boyu + 2 aralık).
    Widget big(int i) => SliverLayoutBuilder(builder: (context, c) {
          final cw = (c.crossAxisExtent - 2 * gap) / 3;
          final h = 3 * (cw / 0.75) + 2 * gap;
          return SliverToBoxAdapter(
            child: SizedBox(
              height: h,
              child: _MenuCard(item: items[i], color: colorOf(i), big: true),
            ),
          );
        });
    Widget header(String text) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(
              text,
              style: AppTextStyles.cardLabel.copyWith(
                fontSize: 13,
                letterSpacing: 2.2,
                color: AppColors.bone.withValues(alpha: 0.85),
              ),
            ),
          ),
        );

    final s = ref.read(l10nProvider);
    final List<Widget> slivers;
    switch (sessionMenuLayout) {
      case MenuLayout.grid: // yalnız görsel test düzenekleri
        slivers = [cells(List<int>.generate(items.length, (i) => i))];
      case MenuLayout.standard:
        // Favoriler (en çok açılan 6) + Diğer Türler (27'nin tamamı, büyük ikonlu dizilim).
        final favs = orderByUsage(ids, sessionUsage(prefs)).take(6).toList();
        final bigs = sessionBigPicks(ids, prefs);
        final rest = [for (var i = 0; i < items.length; i++) if (!bigs.contains(i)) i];
        final half = (rest.length + 1) ~/ 2; // 24 küçük → 12 + 12
        slivers = [
          header(s.menuFavorites),
          cells(favs),
          space(22),
          header(s.menuOtherTypes),
          if (bigs.isNotEmpty) ...[big(bigs[0]), space(gap)],
          cells(rest.sublist(0, half)),
          if (bigs.length > 1) ...[space(gap), big(bigs[1])],
          space(gap),
          cells(rest.sublist(half)),
          if (bigs.length > 2) ...[space(gap), big(bigs[2])],
        ];
    }
    return CustomScrollView(
      key: ValueKey('homeMenu_${sessionMenuLayout.name}'),
      controller: _gridScrollCtrl,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Layer 2'nin canlı yüksekliği kadar boşluk; başlık gizliyken boy değişirse menü
        // yerinde kalır (kaydırma ofseti düzeltilir).
        // Menü TAM EKRAN en üstten başlar; bant ayrı overlay katmanı (ızgarayı itmez). Üst boşluk sabit.
        SliverToBoxAdapter(child: SizedBox(height: topExtra)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
        space(bottomPad),
      ],
    );
  }

  // ── Ana Menü 1. Sohbet Balonu ──────────────────────────────────────────────
  // App açılışında bir kez hesaplanır (didChangeDependencies).
  // Her build'de yeniden çağrılmaz — typewriter RangeError'ı önler.
  /// Hafızayı açar, bu gelişi kaydeder ve karşılamayı hazırlar.
  Future<void> _loadSelamlama() async {
    final profile = ref.read(userProfileProvider);
    final yedek = ref.read(localeProvider) == 'en'
        ? (profile.name.isNotEmpty ? 'Welcome ${profile.name}!' : 'Welcome!')
        : (profile.name.isNotEmpty ? 'Hoş geldin ${profile.name}!' : 'Hoş geldin!');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hafiza = MagnusHafiza(prefs);
      MagnusHafiza.aktif = hafiza;
      final bilgi = hafiza.girisKaydet(DateTime.now());
      final ses = MagnusSes(prefs, hafiza);
      await ses.yukle();
      if (!mounted) return;
      _hafiza = hafiza;
      _ses = ses;
      _selamlamaHazir(ses.giris(_baglam(), bilgi) ?? yedek);
    } catch (e) {
      debugPrint('Magnus sesi açılamadı: $e');
      if (mounted) _selamlamaHazir(yedek);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri modelleri
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  final String title;
  final String imagePath;
  final int credits;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.imagePath, this.credits, this.onTap);
}

// ─────────────────────────────────────────────────────────────────────────────
// Menü kartı
// ─────────────────────────────────────────────────────────────────────────────

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  final Color color; // sayfa rengi (eski çerçeve rengi)

  /// Düzen 2'nin büyük ikonu (3×3 hücre): etiket, rozet ve köşe orantılı büyür.
  final bool big;
  const _MenuCard({required this.item, required this.color, this.big = false});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _down = false;

  static const _radiusSmall = BorderRadius.all(Radius.circular(14));
  static const _radiusBig = BorderRadius.all(Radius.circular(20));
  BorderRadius get _radius => widget.big ? _radiusBig : _radiusSmall;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97, // 0.95 "oyuncak" hissi veriyordu (Codex)
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (down) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Gerçek boş slot (başlıksız) → "mühürlü kapı".
    if (item.title.isEmpty) return _SealedCard(color: widget.color);

    // Gece Grimuarı menü kartı (2026-11): neon sayfa çerçevesi/glow KALKTI. Görsel
    // filmli (basınca renk biraz sızar), kemik cam kenarı, alt-orta Cinzel etiket,
    // sağ üstte cam kredi kapsülü.
    return Semantics(
      button: true,
      label: item.title,
      excludeSemantics: true,
      onTap: item.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: GestureDetector(
          onTapDown: (_) => _press(true),
          onTapUp: (_) {
            _press(false);
            HapticFeedback.mediumImpact(); // fal ikonu titreşimi (Anıl 2026-11-05)
            item.onTap();
          },
          onTapCancel: () => _press(false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 6),
              ],
            ),
            child: ClipRRect(
              borderRadius: _radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FilmedImage(widget.big ? menuImageFor(item.imagePath) : item.imagePath,
                      active: _down, vignette: 0.40),
                  // Etiket örtüsü: alttan %45, mürekkep %85 → şeffaf.
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.45],
                          colors: [Color(0xCC000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: widget.big ? 16 : 6,
                    right: widget.big ? 16 : 6,
                    bottom: widget.big ? 20 : 9,
                    // Kelime ortasından bölünmez: dar ekran + büyük yazıda küçülür (WordSafeText).
                    child: WordSafeText(
                      item.title,
                      style: AppTextStyles.cardLabel.copyWith(
                        fontSize: widget.big ? 22 : 11.5,
                        letterSpacing: widget.big ? 2.0 : 1.0,
                        height: 1.15,
                        color: _down ? AppColors.bone : AppColors.bone.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  if (item.credits >= 0)
                    Positioned(
                      top: widget.big ? 12 : 6,
                      right: widget.big ? 12 : 6,
                      child: widget.big
                          ? Transform.scale(
                              scale: 1.5,
                              alignment: Alignment.topRight,
                              child: _CreditBadge(count: item.credits))
                          : _CreditBadge(count: item.credits),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: _radius,
                          border: Border.all(color: widget.color, width: widget.big ? 2 : 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boş slot: "mühürlü kapı" — soluk cam, ortada kapalı göz mühürü + "Mühürlü".
/// Basma animasyonu yok; dokununca hafif titreşim (sanat yönetmeni).
class _SealedCard extends StatelessWidget {
  final Color color;
  const _SealedCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final label = ref.watch(l10nProvider).sealed;
      return Semantics(
        label: label,
        child: GestureDetector(
          onTap: () => HapticFeedback.selectionClick(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6)],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(28, 28),
                    painter: _SealGlyphPainter(Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Mühür glifi: halka içinde kapalı göz (kirpikli yay) — 24'lük ızgara.
class _SealGlyphPainter extends CustomPainter {
  final Color color;
  const _SealGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(12 * k, 12 * k), 10.5 * k, p);
    final lid = Path()
      ..moveTo(6.5 * k, 11.0 * k)
      ..quadraticBezierTo(12 * k, 16.5 * k, 17.5 * k, 11.0 * k);
    canvas.drawPath(lid, p);
    const lashes = [
      [8.6, 13.2, 7.8, 15.0],
      [12.0, 14.1, 12.0, 16.1],
      [15.4, 13.2, 16.2, 15.0],
    ];
    for (final l in lashes) {
      canvas.drawLine(Offset(l[0] * k, l[1] * k), Offset(l[2] * k, l[3] * k), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SealGlyphPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı widget'lar
// ─────────────────────────────────────────────────────────────────────────────

/// Kredi rozeti: sağ üstte küçük cam kapsül, mum altını rakam (bitmişse kül).
class _CreditBadge extends StatelessWidget {
  final int count;
  const _CreditBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final used = count <= 0;
    final c = used ? Colors.white30 : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: used ? Colors.white30 : const Color(0xFF00E5FF), size: 9),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyles.meta.copyWith(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTextStyles.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
