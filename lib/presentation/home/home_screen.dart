// ═════════════════════════════════════════════════════════════════════════════
// AI OTURUMU BAŞLANGIÇ REHBERİ — home_screen.dart
// Bu dosyayı okuyan bir LLM için: aşağıdaki açıklamalar proje mimarisini ve
// isimlendirme kurallarını özetler. Yeni bir oturumda bu bloğu oku.
// ═════════════════════════════════════════════════════════════════════════════
//
// ── BALON SİSTEMİ (Chat Header) ───────────────────────────────────────────
// Ana menünün en üstünde Magnus karakterinin konuşma balonları sıralanır.
// Balonlar dizi halinde yazılır; her biri tamamlanınca bir sonraki başlar
// (typewriter animasyonu, 30ms/karakter).
//
//   Balon 1 : Selamlama balonu — her uygulama açılışında 6 selamlamadan biri
//             rastgele seçilir (isim dahil, örn. "Hoş geldin Anıl!").
//             Renk: yeşil-camgöbeği gradient (#1A6B5A → #1A5E6B).
//
//   Balon 2 : Sabit metin — "Magnus'un ana menüsü karşında!"
//             Renk: mor gradient (#3A1F8C → #4835A6).
//
//   Balon 3+ : Dinamik ekstra balonlar (_extraBubbles listesi).
//             Şu anda tetiklenen durumlar:
//             • Tarot falı gönderildi → turuncu uyarı balonu + mor balon
//             • Günlük fal hakkı doldu → kırmızımsı uyarı + mor balon
//             Uyarı rengi: (#5C2508 → #7A3510), border: #CC6622
//
// Chat header yüksekliği: SizedBox(height: 155). Bir balon yaklaşık 45-55px
// kaplar. Balonlar NonScrollable ScrollView içinde aşağı kayar.
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
// ── SAYFA YAPISI (3×3 Grid) ───────────────────────────────────────────────
// Üç sayfa, her biri 9 ikonluk 3×3 ızgara:
//   Sayfa 1: Kahve Falı, Tarot, Astroloji,
//            Numeroloji, Durugörü, Yüz Falı,
//            AstroTakvim, Biyoritim, Doğum Haritası
//   Sayfa 2: Motivasyon, Dert Ortağı, Olumlama,
//            Özlü Sözler, Acı Gerçekler, Kader Kitabı,
//            Kehanet, Niyet, Japon Falı
//   Sayfa 3: I-Ching, Aşk Uyumu, Kader Çarkı, Rüya Yorumu, + 5 yer tutucu (yakında)
//
// Sayfa geçişi: alt bardaki Önceki/Sonraki butonları VEYA yatay swipe
//   (Listener ile — GestureDetector değil, jest arenası sorunu olmaz).
//   Eşik: 50px yatay hareket. Geçiş animasyonu: 380ms easeInOut.
//
// Sayfa göstergesi: üç ince dikdörtgen (36×3px), aktif sayfa parlak mor.
//   Grid'in içine Stack overlay olarak yerleştirilmiştir (alt kenar).
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
// Settings ekranında sol üst köşede sarı dişli çark — sadece şu profil
// bilgileri eşleşince görünür: name='Anıl', maritalStatus='evli',
// birthDate='1983-10-14', job='kamusektoru', zodiacSign='Terazi',
// birthTime='13:30', birthCity='Ankara'. Admin panelinde günlük hakları
// sıfırlama butonu bulunur.
//
// ═════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/inbox_item.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../data/providers.dart';
import '../shell/main_tabs.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Başlangıç sayfası homePageProvider'dan (yeniden mount'ta bar ile uyuşsun);
  // keepPage:false → PageStorage eski konumu geri yükleyip provider'ı ezmesin (Codex).
  late final PageController _pageController;
  final ScrollController _chatScrollCtrl = ScrollController();
  int _currentPage = 0;
  /// Programatik sayfa animasyonunun hedefi (sürerken onPageChanged ara değerleri
  /// provider'a yazılmaz → bardaki kapsül doğrudan hedefe kayar, geri sekmez).
  int? _animTarget;
  static const _totalPages = 3;

  final List<_ExtraBubble> _extraBubbles = [];
  int _typingIndex = 0; // hangi balon şu an yazılıyor
  String _selamlama = ''; // async yüklenir — JSON'dan

  // Günlük kalan kredi: 1 = hak var, 0 = kullanıldı
  Map<String, int> _remainingCredits = {};

  // Kilit açılma zamanlayıcısı — en erken unlockAt'e göre kurulur
  Timer? _unlockTimer;

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
    'kadercarki':   'kadercarki_bugun_tarih',
    'askuyumu':     'askuyumu_bugun_tarih',
    // 'numeroloji' burada yok — limit ekran içinden yönetilir
  };

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  double? _swipeStartX;

  void _onBubbleComplete(int index) {
    if (!mounted) return;
    setState(() {
      if (index == _typingIndex) _typingIndex++;
    });
    // Sonraki balon başlayınca scroll'u güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _selamlamaYuklendi = false;

  @override
  void initState() {
    super.initState();
    _currentPage = ref.read(homePageProvider).clamp(0, _totalPages - 1);
    _pageController = PageController(initialPage: _currentPage, keepPage: false);
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
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).tarotSentBubble(name),
        gradient: const [Color(0xFF7A3A00), Color(0xFF9C5200)],
        borderColor: const Color(0xFFE8820C),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).kahveSentBubble(name),
        gradient: const [Color(0xFF7A3A00), Color(0xFF9C5200)],
        borderColor: const Color(0xFFE8820C),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkDurugoruSent() {
    final sent = ref.read(durugoruSentProvider);
    if (!sent) return;
    ref.read(durugoruSentProvider.notifier).state = false;
    _refreshCredits();
    final name = ref.read(userProfileProvider).name;
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).durugoruSentBubble(name),
        gradient: const [Color(0xFF7A3A00), Color(0xFF9C5200)],
        borderColor: const Color(0xFFE8820C),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkRuyaSent() {
    final sent = ref.read(ruyaSentProvider);
    if (!sent) return;
    ref.read(ruyaSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).ruyaSentBubble(name),
        gradient: const [Color(0xFF1A0A4C), Color(0xFF2D1580)],
        borderColor: const Color(0xFF7B5CF6),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).ichingSentBubble(name),
        gradient: const [Color(0xFF0A1A10), Color(0xFF0F2D1A)],
        borderColor: const Color(0xFFB8941F),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).japonSentBubble(name),
        gradient: const [Color(0xFF2A0008), Color(0xFF4A0012)],
        borderColor: const Color(0xFFCC2244),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkElFaliSent() {
    final sent = ref.read(elFaliSentProvider);
    if (!sent) return;
    ref.read(elFaliSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).elFaliSentBubble(name),
        gradient: const [Color(0xFF1A0A2E), Color(0xFF2D1255)],
        borderColor: const Color(0xFF9B3FCC),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkYuzFaliSent() {
    final sent = ref.read(yuzFaliSentProvider);
    if (!sent) return;
    ref.read(yuzFaliSentProvider.notifier).state = false;
    final name = ref.read(userProfileProvider).name;
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).yuzFaliSentBubble(name),
        gradient: const [Color(0xFF1A0A2E), Color(0xFF2D1255)],
        borderColor: const Color(0xFF9B3FCC),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _listenersAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_selamlamaYuklendi) {
      _selamlamaYuklendi = true;
      _loadSelamlama();
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

  @override
  void dispose() {
    _unlockTimer?.cancel();
    _pageController.dispose();
    _chatScrollCtrl.dispose();
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
      _scheduleUnlockTimer(); // sonraki kilit için tekrar kur
    });
  }


  // Başa sarma (modulo) yok: _animateHomeTo sınırlar (Codex: sarma, art arda
  // aksiyonda son sayfadan 1. sayfaya atlatabiliyordu).
  void _goNext() {
    _scheduleUnlockTimer(); // sayfa değişiminde kilit kontrolü
    _animateHomeTo(_currentPage + 1);
  }

  void _goPrev() {
    _scheduleUnlockTimer();
    _animateHomeTo(_currentPage - 1);
  }

  /// Sayfa geçişinin TEK sahibi (swipe, semantik aksiyon, bardaki Ev1/2/3) — iki
  /// animasyon yarışmasın (Codex). Hedef ÖNCE yerel duruma yazılır, sonra provider'a:
  /// provider dinleyicisi hedefi görüp tekrar tetiklemez.
  void _animateHomeTo(int page) {
    page = page.clamp(0, _totalPages - 1);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Gizli sekmedeyken (TickerMode kapalı) animasyon ilerlemez → anında atla.
    final visible = TickerMode.valuesOf(context).enabled;
    if (!_pageController.hasClients || !visible || reduce) {
      _animTarget = null;
      setState(() => _currentPage = page);
      if (_pageController.hasClients) _pageController.jumpToPage(page);
      _syncPageProvider(page);
      return;
    }
    _animTarget = page;
    setState(() => _currentPage = page);
    _syncPageProvider(page);
    _pageController
        .animateToPage(page,
            duration: const Duration(milliseconds: 380), curve: Curves.easeInOut)
        .whenComplete(() {
      if (_animTarget == page) _animTarget = null;
    });
  }

  void _syncPageProvider(int page) {
    final n = ref.read(homePageProvider.notifier);
    if (n.state != page) n.state = page;
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
      _showDailyLimitBubble(type);
      return;
    }
    if (!mounted) return;
    final result = await context.push<String?>(route);
    if (!mounted) return;
    if (result == 'hazirlanıyor') {
      _showHazirlaniyorBubble(type);
    }
    await _refreshCredits();
  }

  // ─── Günlük limitli fallar (I-Ching, Japon Falı) — reklam yok, git/gel yok (go) ──
  void _onDailyFalTap(String type, String route) {
    final remaining = _remainingCredits[type] ?? 1;
    if (remaining <= 0) {
      _showDailyLimitBubble(type);
      return;
    }
    context.push(route);
  }

  // ─── Navigasyon yardımcısı ────────────────────────────────────────────────
  Future<void> _pushWithAd(String route) async {
    if (!mounted) return;
    await context.push(route);
  }

  void _showHazirlaniyorBubble(String type) {
    final msg = ref.read(l10nProvider).hazirlaniyorMessage(type);
    // Fal türüne göre balonda ikon göster
    final String? bubbleIcon = switch (type) {
      'kahve'     => 'assets/images/inbox_icons/kahve.png',
      'japonfali' => 'assets/images/inbox_icons/japonfali.png',
      _           => null,
    };
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: msg,
        gradient: const [Color(0xFF2A1060), Color(0xFF3D1F88)],
        borderColor: const Color(0xFF7755CC),
        iconPath: bubbleIcon,
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showDailyLimitBubble(String type) {
    final s           = ref.read(l10nProvider);
    final name        = ref.read(userProfileProvider).name;
    final fortuneName = s.fortuneDisplayName(type);
    final customMsg   = s.fortuneLimitMessage(type);
    final limitText   = customMsg ?? s.dailyLimitBubble(fortuneName, name);
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: limitText,
        gradient: const [Color(0xFF5C2508), Color(0xFF7A3510)],
        borderColor: const Color(0xFFCC6622),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Sayfa 1 ──────────────────────────────────────────────────────────────
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
            -1, () => _pushWithAd('/astroloji')),
        _MenuItem(s.numerology, 'assets/images/menu/numeroloji.png',
            -1,
            () => _onFortuneItemTap('numeroloji', '/numeroloji')),
        _MenuItem(s.durugoru, 'assets/images/menu/durugoru.png',
            _remainingCredits['durugoru'] ?? 1,
            () => _onFortuneItemTap('durugoru', '/durugoru')),
        _MenuItem(s.faceFortune, 'assets/images/menu/yuzfali.png', 1,
            () => _pushWithAd('/yuz_fali_kimin')),
        _MenuItem(s.palmReading, 'assets/images/menu/elfali.png', 1,
            () => _pushWithAd('/el_fali')),
        _MenuItem(s.astroCalendar, 'assets/images/aytakvimi.png',
            -1, () => _pushWithAd('/astrotakvim')),
        _MenuItem(s.biorhythm, 'assets/images/falbg/biyoritim.png',
            -1, () => _pushWithAd('/biyoritim')),
      ];
  }

  // ─── Sayfa 2 ──────────────────────────────────────────────────────────────
  List<_MenuItem> _page2Items(BuildContext context) {
    final s = ref.read(l10nProvider);
    return [
        _MenuItem(s.motivation, 'assets/images/motivasyon_yeni.png',
            -1,
            () async {
              if (!mounted) return;
              await context.push('/motivation');
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
            () => _pushWithAd('/niyet')),
        _MenuItem(s.japaneseFortune, 'assets/images/japonfali.png',
            _remainingCredits['japonfali'] ?? 1,
            () => _onDailyFalTap('japonfali', '/japonfali')),
      ];
  }

  // ─── Sayfa 3 ──────────────────────────────────────────────────────────────
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
            () => _pushWithAd('/ruya_yorumu')),
        // boş slot — rüya yorumu ile doğum haritası arasında
        _MenuItem('', 'assets/images/soon_placeholder.png', -1, () {}),
        _MenuItem(s.birthChart, 'assets/images/dogum.png',
            1, () => _pushWithAd('/dogumharitasi')),
        // 3 yer tutucu — ikon eklendikçe buralar dolacak
        ...List.generate(3, (_) =>
            _MenuItem('', 'assets/images/soon_placeholder.png', -1, () {})),
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
      if (next == MainTab.home && prev != MainTab.home && mounted) _refreshCredits();
    });
    // Bardaki Ev1/Ev2/Ev3 → o sayfaya git. Hedef (sürüyorsa) ya da mevcut sayfayla
    // aynıysa yeni komut değildir (kendi yazdığımız değer) → yok say.
    ref.listen<int>(homePageProvider, (_, next) {
      final cur = _animTarget ?? _currentPage;
      if (next != cur) _animateHomeTo(next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Ana menü arka planı ───────────────────────────────────────────
          // Gece Grimuarı: görsel filmlenir (doygunluk 0.15, parlaklık 0.62) → mürekkep
          // örtüsü + kenar vinyeti. Renkli neon gökyüzü yerine isli gece camı.
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(FilmedImage.matrix(0.15, 0.62)),
              child: Image.asset(
                'assets/images/welcomscreenbackground.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.45, 1.0],
                    colors: [Color(0x8C07080B), Color(0x4007080B), Color(0xA607080B)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    stops: [0.55, 1.0],
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
            ),
          ),
          // ── İçerik ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ─── Chat header (sabit) ──────────────────────────────────
                _buildChatHeader(),

                // ─── Animasyonlu 3×3 grid ─────────────────────────────────
                Expanded(
                  child: Listener(
                    onPointerDown:  (e) => _swipeStartX = e.position.dx,
                    onPointerUp:    (e) {
                      final dx = e.position.dx - (_swipeStartX ?? e.position.dx);
                      _swipeStartX = null;
                      if (dx < -50) {
                        // Sola swipe
                        if (_currentPage == _totalPages - 1) {
                          // Son sayfadan sola → gelen kutusu sekmesi (sağdan gelir)
                          selectMainTab(context, MainTab.inbox, entry: TabEntry.right);
                        } else {
                          _goNext();
                        }
                      } else if (dx > 50) {
                        // Sağa swipe
                        if (_currentPage == 0) {
                          // İlk sayfadan sağa → kullanıcı bilgileri sekmesi (soldan gelir)
                          selectMainTab(context, MainTab.profile);
                        } else {
                          _goPrev();
                        }
                      }
                    },
                    onPointerCancel: (_) => _swipeStartX = null,
                    // Ok butonları kalktı → ekran okuyucu için sayfa değiştirme aksiyonu
                    // (Codex: VoiceOver/TalkBack kullanıcısı özel swipe'a mahkûm kalmasın).
                    child: Semantics(
                      value: '${_currentPage + 1} / $_totalPages',
                      // value ile birlikte artış/azalış değerleri de verilmeli (semantics assert'i).
                      increasedValue: _currentPage < _totalPages - 1
                          ? '${_currentPage + 2} / $_totalPages'
                          : null,
                      decreasedValue:
                          _currentPage > 0 ? '$_currentPage / $_totalPages' : null,
                      onIncrease: _currentPage < _totalPages - 1 ? _goNext : null,
                      onDecrease: _currentPage > 0 ? _goPrev : null,
                      child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      clipBehavior: Clip.none,
                      itemCount: _totalPages,
                      onPageChanged: (p) {
                        // Programatik geçiş sürerken ara sayfa YOK sayılır: hedef zaten
                        // _currentPage'de. (Codex: ara değer swipe/semantik kararlarını
                        // bozuyor, "artır" aynı hedefi yeniden başlatabiliyordu.)
                        if (_animTarget != null) return;
                        setState(() => _currentPage = p);
                        _syncPageProvider(p);
                      },
                      itemBuilder: (context, pageIndex) {
                        final items = pageIndex == 0
                            ? _page1Items(context)
                            : pageIndex == 1
                                ? _page2Items(context)
                                : _page3Items(context);
                        return _buildGrid(items);
                      },
                    ),
                    ),
                  ),
                ),
                // ─── Sayfa göstergesi — grid'e yapışık, sabit pozisyon ────
                _buildPageIndicator(),

                // ─── Alt bar ─────────────────────────────────────────────
                _buildBottomBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    // Tüm balonları tek listede birleştir (sabit 2 + dinamik ekstralar)
    final bubbles = [
      _ExtraBubble(
        text: _selamlama, // initState/didChangeDependencies'te bir kez hesaplandı
        gradient: const [Color(0xFF1A6B5A), Color(0xFF1A5E6B)],
        borderColor: const Color(0xFF2DAAA0),
      ),
      _ExtraBubble(
        text: ref.read(l10nProvider).magnusMainMenu,
        gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
        borderColor: const Color(0xFF7B5ECC),
      ),
      ..._extraBubbles,
    ];

    // Şu an ekranda görünen balon sayısı
    // (_typingIndex balon tamamlandıkça artar; bubbles.length ile sınırla)
    final visibleCount = (_typingIndex + 1).clamp(0, bubbles.length);

    return SizedBox(
      height: 155,
      child: SingleChildScrollView(
        controller: _chatScrollCtrl,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < bubbles.length; i++)
              if (i <= _typingIndex) ...[
                if (i > 0) const SizedBox(height: 8),
                // Görünen balon sayısına göre eskilere doğru opasite düşür
                Opacity(
                  opacity: visibleCount >= 3
                      ? (i == visibleCount - 1 ? 1.0 : (i == visibleCount - 2 ? 0.60 : 0.30))
                      : visibleCount == 2
                          ? (i == 0 ? 0.60 : 1.0)
                          : 1.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MagnusAvatar(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RepaintBoundary(
                          child: _TypewriterChatBubble(
                            key: ValueKey(i),
                            text: bubbles[i].text,
                            gradient: bubbles[i].gradient,
                            borderColor: bubbles[i].borderColor,
                            isActive: i == _typingIndex,
                            enableMarquee: i == 0,
                            onComplete: () => _onBubbleComplete(i),
                            iconPath: bubbles[i].iconPath,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  // Gece Grimuarı: sayfa başına renk YOK — etkin sayfa mum altını uzun çizgi,
  // diğerleri kül kısa çizgi (sanat yönetmeni).
  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 24 : 8,
            height: 3,
            decoration: BoxDecoration(
              color: active ? AppColors.gold : AppColors.ash.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
        children: items.map((item) => _MenuCard(item: item)).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // Alt bar artık MainTabsScreen'de: cam GlassTabBar 3 ekranda da aynı yerde ve
    // sabit duruyor. Burada yalnız hazırlanan fallar satırı + barın yer tutucusu.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, kGlassBarGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Hazırlanan fallar progress satırı — sabit 50px, içerik yoksa şeffaf ──
          Consumer(builder: (_, cref, __) {
            final items = cref.watch(inboxProvider);
            // Yeşil halka durumu: (1) hazırlanan (kilitli) fal kalmadı +
            // (2) okunmamış (hazır) en az 1 fal var → küçük ikonları gizle,
            // bunun yerine inbox butonu yeşil çemberle uyarı verir.
            final hasLocked   = items.any((e) => e.isLocked);
            final readyUnread = items.where((e) => !e.isRead && !e.isLocked).length;
            final greenRing   = !hasLocked && readyUnread > 0;
            final cooking = items
                .where((e) => e.unlockAt != null && (e.isLocked || !e.isRead))
                .toList()
              ..sort((a, b) => (a.unlockAt!).compareTo(b.unlockAt!));
            return SizedBox(
              height: 50,
              child: (cooking.isEmpty || greenRing)
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _FortuneProgressRow(items: cooking),
                    ),
            );
          }),
          // ── Cam alt bar yer tutucusu (bar MainTabsScreen'de, üstte overlay) ──
          const SizedBox(height: kGlassBarHeight),
        ],
      ),
    );
  }

  // ── Ana Menü 1. Sohbet Balonu ──────────────────────────────────────────────
  // App açılışında bir kez hesaplanır (didChangeDependencies).
  // Her build'de yeniden çağrılmaz — typewriter RangeError'ı önler.
  Future<void> _loadSelamlama() async {
    try {
      final profile = ref.read(userProfileProvider);
      final vars = profile.toVariableMap();
      final isEn = ref.read(localeProvider) == 'en';
      final prefs = await SharedPreferences.getInstance();
      final raw = await rootBundle.loadString('assets/data/karsilamalar.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String metin;

      // ─── 1. İLK KEZ GELİŞ ───────────────────────────────────────
      final ilkGirisDone = prefs.getBool('ilk_giris_yapildi') ?? false;
      if (!ilkGirisDone) {
        await prefs.setBool('ilk_giris_yapildi', true);
        metin = (isEn ? data['ilk_giris_en'] as String? : null) ??
            data['ilk_giris'] as String? ??
            (isEn ? 'And here I am! Welcome {{isim}}.' : 'Ve işte karşındayım! Hoş geldin {{isim}}.');
        metin = VariableReplacer.replace(metin, vars);
        if (!mounted) return;
        setState(() => _selamlama = metin);
        return;
      }

      // ─── Günlük ziyaret sayacı ───────────────────────────────────
      final visitDate = prefs.getString('karsilama_tarih') ?? '';
      int visitCount;
      if (visitDate != todayStr) {
        visitCount = 1;
        await prefs.setString('karsilama_tarih', todayStr);
        await prefs.setInt('karsilama_sayi', 1);
      } else {
        visitCount = (prefs.getInt('karsilama_sayi') ?? 0) + 1;
        await prefs.setInt('karsilama_sayi', visitCount);
      }

      final karsilamalar = (data['karsilamalar'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final biliyormuydun = (data['biliyormuydun'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // ─── 2. ÖZEL GÜN (sadece günün ilk ziyaretinde) ─────────────
      if (visitCount == 1) {
        final ozelGunler = (data['ozel_gunler'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        Map<String, dynamic>? ozelEslesme;
        for (final og in ozelGunler) {
          final ay  = og['ay'] as int;
          final gun = og['gun'] as int;
          if (ay == 0 && gun == 0) {
            if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
              try {
                final bd = DateTime.parse(profile.birthDate!);
                if (bd.month == now.month && bd.day == now.day) {
                  ozelEslesme = og;
                  break;
                }
              } catch (_) {}
            }
          } else if (ay == now.month && gun == now.day) {
            ozelEslesme = og;
            break;
          }
        }
        if (ozelEslesme != null) {
          final ozMetin = (isEn ? ozelEslesme['metin_en'] as String? : null) ??
              ozelEslesme['metin'] as String;
          metin = VariableReplacer.replace(ozMetin, vars);
          if (!mounted) return;
          setState(() => _selamlama = metin);
          return;
        }
      }

      // ─── 3. ZİYARET SAYISINA GÖRE METİN SEÇİMİ ─────────────────
      // ziyaret=1..5 spesifik, ziyaret=6 → 6+ için catch-all
      final ziyaretKey = visitCount.clamp(1, 6);
      var havuz = karsilamalar
          .where((e) => (e['ziyaret'] as int? ?? 1) == ziyaretKey)
          .toList();
      if (havuz.isEmpty) {
        havuz = karsilamalar
            .where((e) => (e['ziyaret'] as int? ?? 1) == 6)
            .toList();
      }

      // %10 Biliyor muydun? (yalnızca 1. ziyarette)
      List<Map<String, dynamic>> secimHavuzu = havuz;
      String noRepeatKey = 'karsilama_gosterilen_$ziyaretKey';
      if (visitCount == 1 && biliyormuydun.isNotEmpty &&
          Random().nextDouble() < 0.10) {
        secimHavuzu = biliyormuydun;
        noRepeatKey = 'karsilama_gosterilen_biliyormuydun';
      }

      metin = secimHavuzu.isNotEmpty
          ? _noRepeatSec(prefs, noRepeatKey, secimHavuzu, isEn)
          : (profile.name.isNotEmpty
              ? (isEn ? 'Welcome ${profile.name}!' : 'Hoş geldin ${profile.name}!')
              : (isEn ? 'Welcome!' : 'Hoş geldin!'));

      metin = VariableReplacer.replace(metin, vars);
      if (!mounted) return;
      setState(() => _selamlama = metin);
    } catch (e) {
      final name = ref.read(userProfileProvider).name;
      if (!mounted) return;
      setState(() => _selamlama = name.isNotEmpty ? 'Hoş geldin $name!' : 'Hoş geldin!');
    }
  }

  /// No-repeat seçim: havuzdaki tüm metinler gösterilmeden aynısı tekrar gelmez.
  String _noRepeatSec(SharedPreferences prefs, String key,
      List<Map<String, dynamic>> havuz, [bool isEn = false]) {
    final shown = prefs.getStringList(key) ?? [];
    final allIds = havuz.map((e) => '${e['id']}').toList();

    // Gösterilmemiş olanlar
    var available = havuz.where((e) => !shown.contains('${e['id']}')).toList();

    // Hepsi bitti → son gösterileni koruyarak sıfırla
    if (available.isEmpty) {
      final lastId = shown.isNotEmpty ? shown.last : null;
      final resetShown = lastId != null ? [lastId] : <String>[];
      prefs.setStringList(key, resetShown);
      available = havuz.where((e) => e['id'].toString() != lastId).toList();
      if (available.isEmpty) available = List.from(havuz);
    }

    available.shuffle(Random());
    final pick = available.first;

    // Seçimi kaydet (listeyi gereksiz şişirmemek için sadece son N ID tut)
    final updated = [...shown, '${pick['id']}'];
    // Havuzdan fazla ID biriktirme — en fazla havuz.length kadar tut
    final trimmed = updated.length > allIds.length
        ? updated.sublist(updated.length - allIds.length)
        : updated;
    prefs.setStringList(key, trimmed);

    return (isEn ? pick['metin_en'] as String? : null) ?? pick['metin'] as String;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri modelleri
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraBubble {
  final String text;
  final List<Color> gradient;
  final Color borderColor;
  final String? iconPath; // opsiyonel — balon içinde sol tarafta küçük ikon
  const _ExtraBubble({
    required this.text,
    required this.gradient,
    required this.borderColor,
    this.iconPath,
  });
}

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
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _down = false;

  static const _radius = BorderRadius.all(Radius.circular(14));

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
    if (item.title.isEmpty) return const _SealedCard();

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
            item.onTap();
          },
          onTapCancel: () => _press(false),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: _radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FilmedImage(item.imagePath, active: _down, vignette: 0.40),
                  // Etiket örtüsü: alttan %45, mürekkep %85 → şeffaf.
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.45],
                          colors: [Color(0xD907080B), Color(0x0007080B)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 9,
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        fontSize: 11.5,
                        letterSpacing: 1.0,
                        height: 1.15,
                        color: _down ? AppColors.bone : AppColors.bone.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  if (item.credits >= 0)
                    Positioned(top: 6, right: 6, child: _CreditBadge(count: item.credits)),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: GlassRimPainter(radius: _radius, selected: _down),
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
  const _SealedCard();

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
              color: const Color(0x4D1C1C1E),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: const Color(0x0FE8E2D6), width: 0.8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(28, 28),
                    painter: _SealGlyphPainter(AppColors.ash.withValues(alpha: 0.40)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: AppColors.ash.withValues(alpha: 0.55),
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
    final c = used ? AppColors.ash : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xA607080B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.rim, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: c, size: 9),
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

// ─────────────────────────────────────────────────────────────────────────────
// Typewriter balonu
// ─────────────────────────────────────────────────────────────────────────────

class _TypewriterChatBubble extends StatefulWidget {
  final String text;
  final List<Color> gradient;
  final Color borderColor;
  final bool isActive;
  final bool enableMarquee;
  final VoidCallback onComplete;
  final String? iconPath;

  const _TypewriterChatBubble({
    super.key,
    required this.text,
    required this.gradient,
    required this.borderColor,
    required this.isActive,
    required this.onComplete,
    this.enableMarquee = false,
    this.iconPath,
  });

  @override
  State<_TypewriterChatBubble> createState() => _TypewriterChatBubbleState();
}

class _TypewriterChatBubbleState extends State<_TypewriterChatBubble>
    with SingleTickerProviderStateMixin {
  int _charCount = 0;
  Timer? _timer;

  // Marquee
  AnimationController? _marqueeCtrl;
  double _bubbleInnerWidth = 0;
  bool _marqueeRunning = false;

  // Gece Grimuarı: kemik beyazı Jost (ölçüm de aynı stille → marquee hesabı tutarlı).
  static final TextStyle _textStyle = _bubbleTextStyle;
  static const _hPad = 24.0; // horizontal padding inside bubble (12*2)

  @override
  void initState() {
    super.initState();
    if (widget.enableMarquee) {
      _marqueeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    }
    if (widget.isActive) {
      _startTyping();
    } else {
      _charCount = widget.text.length;
      if (widget.enableMarquee) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartMarquee());
      }
    }
  }

  @override
  void didUpdateWidget(_TypewriterChatBubble old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _charCount = 0;
      _marqueeRunning = false;
      _marqueeCtrl?.stop();
      _startTyping();
    }
    // Metin değişti (selamlama async yüklendi)
    if (widget.text != old.text) {
      _charCount = 0;
      _marqueeRunning = false;
      _marqueeCtrl?.stop();
      // Boş metinden dolu metne geçiş: isActive olmasa bile (typingIndex geçmiş olabilir) yeniden başlat
      if (widget.isActive || old.text.isEmpty) {
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_charCount >= widget.text.length) {
        t.cancel();
        // Boş metinde onComplete çağırma — JSON yüklenince metin gelecek
        if (widget.text.isNotEmpty) {
          widget.onComplete();
          if (widget.enableMarquee) {
            // Yazım bitince 3 saniye bekleyip marquee başlat
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _maybeStartMarquee();
            });
          }
        }
        return;
      }
      setState(() => _charCount++);
    });
  }

  // Marquee ayraç boşluğu — metin bittikten sonra kaç karakter boşluk
  static const _marqueeGap = '                              '; // 30 boşluk

  double _measureText(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  void _maybeStartMarquee() {
    if (!mounted || _marqueeCtrl == null || _bubbleInnerWidth <= 0) return;
    final textW = _measureText(widget.text);
    // 8px buffer: TextPainter ölçümü ile gerçek render arasındaki farkı telafi eder
    if (textW < _bubbleInnerWidth - 8) return; // kesin sığıyor, marquee gerekmez

    // Bir döngü = text + gap genişliği — bu kadar kaydırınca seamless sıfırlanır
    final gapW = _measureText(_marqueeGap);
    final cycleW = textW + gapW;

    // Hız: ~55 px/saniye
    final durationMs = max(3000, (cycleW / 55 * 1000).round());
    _marqueeCtrl!.duration = Duration(milliseconds: durationMs);
    _marqueeRunning = true;

    // repeat(reverse:false) → 0→1, anında 0→1... sürekli döngü
    _marqueeCtrl!.repeat();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _marqueeRunning = false;
    _marqueeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeCount = _charCount.clamp(0, widget.text.length);
    final displayText = widget.text.substring(0, safeCount);

    if (!widget.enableMarquee) {
      return _ChatBubble(text: displayText, gradient: widget.gradient, borderColor: widget.borderColor, iconPath: widget.iconPath);
    }

    // Marquee-aware balon
    return LayoutBuilder(builder: (ctx, constraints) {
      _bubbleInnerWidth = (constraints.maxWidth - _hPad).clamp(1.0, double.infinity);

      // Seamless loop için içerik: "metin<boşluk>metin"
      // cycleW kadar kaydırınca ilk metin ile ikinci metin aynı konuma gelir → seamless
      final loopContent = '${widget.text}$_marqueeGap${widget.text}';

      return Container(
        decoration: _grimoireBubble,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // Kayan yazı iki kenarda 14px yumuşak söner (sanat yön.: keskin kesik 'eniz.' yoktu).
        child: _EdgeFade(
          enabled: _marqueeRunning,
          child: ClipRect(
          child: _marqueeRunning && _marqueeCtrl != null
            ? AnimatedBuilder(
                animation: _marqueeCtrl!,
                builder: (_, __) {
                  final textW = _measureText(widget.text);
                  final gapW  = _measureText(_marqueeGap);
                  final cycleW = textW + gapW;
                  // value 0→1 → offset 0→cycleW (seamless loop)
                  final offset = _marqueeCtrl!.value * cycleW;
                  return Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Text(loopContent, style: _textStyle, maxLines: 1,
                        overflow: TextOverflow.visible, softWrap: false),
                  );
                },
              )
            : Builder(builder: (_) {
                // Typewriter aşaması: yazılan kısmı göster, sona kaydır
                // +4px buffer → son karakter kliplenmesini önler
                final typedW = _measureText(displayText);
                final offset = max(0.0, typedW - _bubbleInnerWidth + 4);
                return Transform.translate(
                  offset: Offset(-offset, 0),
                  child: Text(displayText, style: _textStyle, maxLines: 1,
                      overflow: TextOverflow.visible, softWrap: false),
                );
              }),
          ),
        ),
      );
    });
  }
}

// ── Gece Grimuarı balon dili (tüm balonlar tek cam; çağıranın gradient/borderColor'ı
//    artık yalnız API uyumu için — renkli teal/mor/pembe balonlar kalktı, 2026-11) ──
const _bubbleRadius = BorderRadius.only(
  topLeft: Radius.circular(6), topRight: Radius.circular(18),
  bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
);
final BoxDecoration _grimoireBubble = BoxDecoration(
  color: AppColors.glassTint,
  borderRadius: _bubbleRadius,
  border: Border.all(color: AppColors.rim, width: 0.8),
);
final TextStyle _bubbleTextStyle =
    AppTextStyles.uiLabel.copyWith(fontSize: 13.5, height: 1.4, letterSpacing: 0.1);

/// Yatay kenar sönümü (marquee): iki kenarda 14px.
class _EdgeFade extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _EdgeFade({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) {
        final f = r.width <= 0 ? 0.0 : (14 / r.width).clamp(0.0, 0.3);
        return LinearGradient(
          stops: [0, f, 1 - f, 1],
          colors: const [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
        ).createShader(r);
      },
      child: child,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final Color borderColor;
  final String? iconPath;

  const _ChatBubble({
    required this.text,
    required this.gradient,
    required this.borderColor,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _grimoireBubble,
      child: iconPath != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(iconPath!, width: 22, height: 22,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                const SizedBox(width: 8),
                Flexible(child: Text(text, style: _bubbleTextStyle)),
              ],
            )
          : Text(text, style: _bubbleTextStyle),
    );
  }
}

class _MagnusAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 1.0), // eski: lavanta
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/magnusicon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.inkCard,
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: AppColors.bone,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hazırlanan fallar progress satırı — tüm kilitli öğeler yatay scroll
// ─────────────────────────────────────────────────────────────────────────────

class _FortuneProgressRow extends StatefulWidget {
  final List<InboxItem> items;
  const _FortuneProgressRow({required this.items});

  @override
  State<_FortuneProgressRow> createState() => _FortuneProgressRowState();
}

class _FortuneProgressRowState extends State<_FortuneProgressRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 44.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < widget.items.length; i++) ...[
            _FortuneCircleBadge(item: widget.items[i], size: size),
            if (i < widget.items.length - 1)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tek fal daire rozeti
// ─────────────────────────────────────────────────────────────────────────────

class _FortuneCircleBadge extends StatelessWidget {
  final InboxItem item;
  final double size;
  const _FortuneCircleBadge({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final progress  = item.unlockProgress; // 0.0 → 1.0
    final isLocked  = item.isLocked;       // hazırlanıyor mu?
    final isReady   = !isLocked;           // tamamlandı mı?

    // İkon: hazırlanıyorsa grayscale (2 suffix), tamam ise renkli
    final iconPath  = _iconAsset(item.fortuneType, locked: isLocked);
    final innerSize = size - 6; // arc strokeWidth=3 → her yanda 1.5px, iç alan = size-3; -6 ile ikon tam sığar

    return GestureDetector(
      // Sadece hazır (tamamlanmış) fallar tıklanabilir → gelen kutusu sekmesi (alttan)
      onTap: isReady ? () => selectMainTab(context, MainTab.inbox) : null,
      child: SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _ArcProgressPainter(
              progress: progress,
              color: AppColors.success,
              gradientColors: isLocked ? _ArcProgressPainter._candle : null,
              trackColor: AppColors.bone.withValues(alpha: 0.08),
              strokeWidth: 3.0,
            ),
          ),
          // İkon — grayscale veya renkli
          ClipOval(
            child: SizedBox(
              width: innerSize, height: innerSize,
              child: iconPath != null
                  // Gece Grimuarı filmi: hazırlanıyorken kül, hazır olunca renk biraz sızar.
                  ? ColorFiltered(
                      colorFilter: ColorFilter.matrix(isReady
                          ? FilmedImage.matrix(FilmedImage.activeSaturation, FilmedImage.activeBrightness)
                          : FilmedImage.matrix(0.0, 0.70)),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => _fallbackIcon(),
                      ),
                    )
                  : _fallbackIcon(),
            ),
          ),
          // Badge — SADECE hazırlık tamamlanınca: yeşil "hazır" noktası (Gece Grimuarı
          // success; eski kırmızı "1" neon dili kalktı).
          if (isReady)
            Positioned(
              top: 1, right: 1,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),   // SizedBox
    );   // GestureDetector
  }

  Widget _fallbackIcon() => Container(
    color: AppColors.inkCard,
    child: const Icon(Icons.auto_awesome, color: AppColors.ash, size: 16),
  );

  /// Hazır → renkli ikon, hazırlanıyor → grayscale (2-suffix)
  static String? _iconAsset(FortuneType type, {required bool locked}) {
    const base = 'assets/images/inbox_icons/';
    switch (type) {
      case FortuneType.coffee:     return locked ? '${base}kahve2.png'     : '${base}kahve.png';
      case FortuneType.tarot:      return locked ? '${base}tarot2.png'     : '${base}tarot.png';
      case FortuneType.astrology:  return locked ? '${base}astroloji2.png' : '${base}astroloji.png';
      case FortuneType.motivation: return locked ? '${base}motivasyon2.png': '${base}motivasyon.png';
      case FortuneType.dream:      return locked ? '${base}ruya2.png'      : '${base}ruya.png';
      case FortuneType.general:    return locked ? '${base}cark2.png'      : '${base}cark.png';
      case FortuneType.birthChart:  return locked ? '${base}dogum2.png'      : '${base}dogum.png';
      case FortuneType.numeroloji:  return locked ? '${base}numeroloji2.png' : '${base}numeroloji.png';
      case FortuneType.durugoru:    return locked ? '${base}durugoru2.png'   : '${base}durugoru.png';
      case FortuneType.elfali:      return locked ? '${base}elfali2.png'      : '${base}elfali.png';
      case FortuneType.iching:      return locked ? '${base}iching2.png'      : '${base}iching.png';
      case FortuneType.japonfali:   return locked ? '${base}japonfali2.png'   : '${base}japonfali.png';
      case FortuneType.yuzfali:     return locked ? '${base}elfali2.png'      : '${base}elfali.png';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc progress CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Color>? gradientColors;
  final Color trackColor;
  final double strokeWidth;

  const _ArcProgressPainter({
    required this.progress,
    required this.color,
    this.gradientColors,
    required this.trackColor,
    required this.strokeWidth,
  });

  // Gece Grimuarı (2026-11): neon gökkuşağı yerine MUM ALTINI palindromu — 12 yönünde
  // soluk altınla başlar, 6'da en açık parşömen-altın, 12'de aynı soluk altınla kapanır
  // (ilk renk == son renk → dikişsiz 360°, eski 2026-06 kuralı korunur).
  static const _candle = [
    Color(0xFF6E5B3A), // soluk altın — 12 (başlangıç)
    Color(0xFF9C8250),
    Color(0xFFC2A46B), // mum altını
    Color(0xFFD9C08A),
    Color(0xFFE8D6A8), // parşömen altını — 6 (orta)
    Color(0xFFD9C08A),
    Color(0xFFC2A46B),
    Color(0xFF9C8250),
    Color(0xFF6E5B3A), // soluk altın — 12 (dikişsiz kapanış)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color       = trackColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      const startAngle = -1.5707963;
      final arcPaint = Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round;

      if (gradientColors == null) {
        arcPaint.color = color;
      } else {
        // Gradient arc ile aynı noktadan başlar: 12 o'clock = -π/2
        // SweepGradient 3 o'clock = 0; -π/2 → 12 o'clock
        const gradStart = startAngle; // -π/2 = 12 o'clock
        arcPaint.shader = SweepGradient(
          center: Alignment.center,
          startAngle: gradStart,
          endAngle: gradStart + 2 * 3.1415926,
          colors: gradientColors!,
        ).createShader(rect);
      }
      // shader zaten set edildiyse renk ayarına gerek yok
      canvas.drawArc(
        rect,
        startAngle,
        2 * 3.1415926 * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.progress != progress || old.color != color;
}

