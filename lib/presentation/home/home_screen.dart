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
//   Sayfa 1: Motivasyon, Dert Ortağı, Olumlama, Özlü Sözler, Kader Kitabı,
//            Acı Gerçekler, Kehanet, Durugörü, Niyet
//   Sayfa 2: Kahve Falı, Tarot, AstroTakvim, Numeroloji, Durugörü,
//            Yüz Falı, Japon Falı, I-Ching, Aşk Uyumu
//   Sayfa 3: Astroloji (Günlük Astroloji), + 8 yer tutucu (yakında)
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  final ScrollController _chatScrollCtrl = ScrollController();
  int _currentPage = 0;
  static const _totalPages = 3;

  final List<_ExtraBubble> _extraBubbles = [];
  int _typingIndex = 0; // hangi balon şu an yazılıyor
  late String _selamlama; // sabit, initState'te bir kez hesaplanır

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
    // 'numeroloji' burada yok — limit ekran içinden yönetilir
  };

  static const _fortuneDisplayNames = {
    'motivasyon':  'Motivasyon',
    'olumlama':    'Olumlama',
    'ozlusoz':     'Özlü Sözler',
    'tarot':       'Tarot',
    'kahve':       'Kahve Falı',
    'astroloji':   'Astroloji',
    'kaderkitabi': 'Kader Kitabı',
    'dertortagi':   'Dert Ortağı',
    'acigercekler': 'Acı Gerçekler',
    'numeroloji':   'Numeroloji',
  };

  // Ekrandan 'hazirlanıyor' sinyali gelince gösterilecek mesajlar
  static const _hazirlaniyorMessages = {
    'numeroloji': 'Numeroloji raporun hazırlanıyor...',
  };

  // Günlük limit dolarken özel balon mesajları (varsayılan yerine)
  static const _fortuneLimitMessages = {
    'kaderkitabi': 'Kader kitabının bugünkü sayfasını okudun.',
    'dertortagi':   'Bugün yeterince dertleştik.',
    'acigercekler': 'Bugün gerçeklerle yüzleştin.',
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

  bool _selamlamaHesaplandi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleUnlockTimer();
      _refreshCredits();
      _checkTarotSent();
      _checkKahveSent();
      _precacheOzluSozBgs();
    });
  }

  void _precacheOzluSozBgs() {
    const bgs = [
      '08.jpeg','010.jpeg','011.jpeg','013.jpeg','015.jpeg',
      '016.jpeg','017.jpeg','018.jpeg','041.jpeg','042.jpeg',
    ];
    for (final f in bgs) {
      precacheImage(AssetImage('assets/images/ozlusoz_bgs/$f'), context);
    }
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
        text: 'Tarot falını yorumlamaya başladım${name.isNotEmpty ? ' $name' : ''}.',
        gradient: const [Color(0xFF7A3A00), Color(0xFF9C5200)],
        borderColor: const Color(0xFFE8820C),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: "Magnus'un ana menüsü karşında!",
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
        text: 'Kahve falını yorumluyorum${name.isNotEmpty ? ' $name' : ''}.',
        gradient: const [Color(0xFF7A3A00), Color(0xFF9C5200)],
        borderColor: const Color(0xFFE8820C),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: "Magnus'un ana menüsü karşında!",
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
    // Profil yüklendikten sonra selamlamayı bir kez hesapla
    if (!_selamlamaHesaplandi) {
      final name = ref.read(userProfileProvider).name;
      _selamlama = _hesaplaSelamlama(name);
      _selamlamaHesaplandi = true;
    }
    // tarotSentProvider / kahveSentProvider'ı dinle (sadece bir kez bağla)
    if (!_listenersAttached) {
      _listenersAttached = true;
      ref.listenManual(tarotSentProvider, (_, sent) {
        if (sent) _checkTarotSent();
      });
      ref.listenManual(kahveSentProvider, (_, sent) {
        if (sent) _checkKahveSent();
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

  bool get _isLastPage => _currentPage == _totalPages - 1;

  void _goNext() {
    _scheduleUnlockTimer(); // buton basışında kilit kontrolü
    final next = (_currentPage + 1) % _totalPages;
    _pageController.animateToPage(next,
        duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    setState(() => _currentPage = next);
  }

  void _goPrev() {
    _scheduleUnlockTimer();
    final prev = (_currentPage - 1 + _totalPages) % _totalPages;
    _pageController.animateToPage(prev,
        duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    setState(() => _currentPage = prev);
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
    // Ekran 'hazirlanıyor' sinyali döndürdüyse balon göster
    if (result == 'hazirlanıyor') {
      _showHazirlaniyorBubble(type);
    }
    await _refreshCredits();
  }

  void _showHazirlaniyorBubble(String type) {
    final msg = _hazirlaniyorMessages[type] ?? 'Raporun hazırlanıyor...';
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: msg,
        gradient: const [Color(0xFF2A1060), Color(0xFF3D1F88)],
        borderColor: const Color(0xFF7755CC),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: "Magnus'un ana menüsü karşında!",
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
    final name        = ref.read(userProfileProvider).name;
    final fortuneName = _fortuneDisplayNames[type] ?? type;
    final nameStr     = name.isNotEmpty ? ' $name' : '';
    final customMsg   = _fortuneLimitMessages[type];
    final limitText   = customMsg ?? 'Günlük $fortuneName hakkın doldu$nameStr.';
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: limitText,
        gradient: const [Color(0xFF5C2508), Color(0xFF7A3510)],
        borderColor: const Color(0xFFCC6622),
      ));
      _extraBubbles.add(_ExtraBubble(
        text: "Magnus'un ana menüsü karşında!",
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
  List<_MenuItem> _page1Items(BuildContext context) => [
        _MenuItem('Motivasyon', 'assets/images/motivasyon_yeni.png',
            -1, // badge yok — motivasyon her zaman açılabilir
            () async {
              // Günlük hak bitse de aynı metin gösterilir — navigasyonu engelleme
              if (!mounted) return;
              await context.push('/motivation');
              if (!mounted) return;
              await _refreshCredits();
            }),
        _MenuItem('Dert Ortağı', 'assets/images/menu/dertortagi.png',
            _remainingCredits['dertortagi'] ?? 1,
            () => _onFortuneItemTap('dertortagi', '/dertortagi')),
        _MenuItem('Olumlama', 'assets/images/olumlama.png',
            -1, // günlük limit yok → badge gösterilmez
            () => _onFortuneItemTap('olumlama', '/olumlama')),
        _MenuItem('Özlü Sözler', 'assets/images/ozlusozler.png',
            -1, // badge yok — limit ekran içinden yönetilir
            () => _onFortuneItemTap('ozlusoz', '/ozlusoz')),
        _MenuItem('Acı Gerçekler', 'assets/images/acigercekler.PNG',
            _remainingCredits['acigercekler'] ?? 1,
            () => _onFortuneItemTap('acigercekler', '/acigercekler')),
        _MenuItem('Kader Kitabı', 'assets/images/tefeulyeni.png',
            _remainingCredits['kaderkitabi'] ?? 1,
            () => _onFortuneItemTap('kaderkitabi', '/kaderkitabi')),
        _MenuItem('Kehanet', 'assets/images/menu/kehanet.png', 1,
            () => _onFortuneItemTap('kehanet', '/kehanet')),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 1,
            () {}),
        _MenuItem('Niyet', 'assets/images/menu/mistikfallar.png', 1,
            () => context.push('/niyet')),
      ];

  // ─── Sayfa 3 ──────────────────────────────────────────────────────────────
  // Henüz 9 ikon tanımsız → boş yer tutucu. Astroloji ilk ikondur.
  List<_MenuItem> _page3Items(BuildContext context) => [
        _MenuItem('Astroloji', 'assets/images/astroloji.png',
            1, () => context.push('/astroloji')),
        _MenuItem('Biyoritim', 'assets/images/falbg/biyoritim.png',
            1, () => context.push('/biyoritim')),
        _MenuItem('Doğum Haritası', 'assets/images/dogum.png',
            1, () => context.push('/dogumharitasi')),
        _MenuItem('Kader Çarkı', 'assets/images/kadercarkimenu.png',
            1, () {}),
        // 5 yer tutucu — ikon eklendikçe buralar dolacak
        ...List.generate(5, (_) =>
            _MenuItem('', 'assets/images/soon_placeholder.png', -1, () {})),
      ];

  // ─── Sayfa 2 ──────────────────────────────────────────────────────────────
  List<_MenuItem> _page2Items(BuildContext context) => [
        _MenuItem('Kahve Falı', 'assets/images/menu/kahvefali.png',
            _remainingCredits['kahve'] ?? 1,
            () => _onFortuneItemTap('kahve', '/coffee')),
        _MenuItem('Tarot', 'assets/images/menu/tarot.png',
            _remainingCredits['tarot'] ?? 1,
            () => _onFortuneItemTap('tarot', '/tarot')),
        _MenuItem('AstroTakvim', 'assets/images/aytakvimi.png',
            1,
            () => context.push('/astrotakvim')),
        _MenuItem('Numeroloji', 'assets/images/menu/numeroloji.png',
            -1, // badge yok — limit ekran içinden yönetilir
            () => _onFortuneItemTap('numeroloji', '/numeroloji')),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 1,
            () {}),
        _MenuItem('Yüz Falı', 'assets/images/menu/yuzfali.png', 1,
            () => context.push('/yuz_fali_kimin')),
        _MenuItem('Japon Falı', 'assets/images/japonfali.png', 1,
            () {}),
        _MenuItem('I-Ching', 'assets/images/ichingikon.png', 1,
            () {}),
        _MenuItem('Aşk Uyumu', 'assets/images/askuyumu.png', 1,
            () {}),
      ];

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider); // profil değişince rebuild tetikle

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Ana menü arka planı ───────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcomscreenbackground.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // ── Hafif karartma katmanı (görsel işlem yok — sadece layer) ─────
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.42)),
          ),
          // ── İçerik ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ─── Chat header (sabit) ──────────────────────────────────
                _buildChatHeader(),

                // ─── Animasyonlu 3×3 grid + sayfa göstergesi (overlay) ────
                Expanded(
                  child: Listener(
                    onPointerDown:  (e) => _swipeStartX = e.position.dx,
                    onPointerUp:    (e) {
                      final dx = e.position.dx - (_swipeStartX ?? e.position.dx);
                      _swipeStartX = null;
                      if (dx < -50) _goNext();
                      else if (dx > 50) _goPrev();
                    },
                    onPointerCancel: (_) => _swipeStartX = null,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _totalPages,
                          onPageChanged: (p) => setState(() => _currentPage = p),
                          itemBuilder: (context, pageIndex) {
                            final items = pageIndex == 0
                                ? _page1Items(context)
                                : pageIndex == 1
                                    ? _page2Items(context)
                                    : _page3Items(context);
                            return _buildGrid(items);
                          },
                        ),
                        // Gösterge — grid'in tam altına yapışık
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: _buildPageIndicator(),
                        ),
                      ],
                    ),
                  ),
                ),

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
        text: "Magnus'un ana menüsü karşında!",
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
                            onComplete: () => _onBubbleComplete(i),
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

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFAA88FF)
                  : const Color(0xFFAA88FF).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
        children: items.map((item) => _MenuCard(item: item)).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Hazırlanan fallar progress satırı ─────────────────────────────
          Consumer(builder: (_, cref, __) {
            final items = cref.watch(inboxProvider);
            // Hazırlanıyor (isLocked) VEYA hazır ama henüz okunmamış (!isLocked && !isRead)
            // → kullanıcı okuyunca (isRead=true) kaybolur
            final cooking = items
                .where((e) => e.unlockAt != null && (e.isLocked || !e.isRead))
                .toList()
              ..sort((a, b) => (a.unlockAt!).compareTo(b.unlockAt!));
            if (cooking.isEmpty) return const SizedBox(height: 4);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FortuneProgressRow(items: cooking),
            );
          }),
          // ── Butonlar ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _currentPage == 0
                    ? _BottomBtn(
                        imagePath: 'assets/images/bilgiekranilogo.png',
                        label: 'Bilgiler',
                        onTap: () async {
                          _scheduleUnlockTimer();
                          await context.push('/settings');
                          if (mounted) await _refreshCredits();
                        },
                      )
                    : _BottomBtn(
                        imagePath: 'assets/images/menuleft.png',
                        label: 'Önceki',
                        onTap: _goPrev,
                      ),
              ),
              const SizedBox(width: 8),
              // Ortadaki inbox butonu
              Consumer(builder: (_, cref, __) {
                final hasUnread = cref.watch(readyUnreadCountProvider) > 0;
                return GestureDetector(
                  onTap: () => context.push('/inbox-full'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 48, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFDD00EE), Color(0xFF9900CC)]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFF44FF).withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCC00EE).withValues(alpha: 0.55),
                          blurRadius: hasUnread ? 18 : 8,
                          spreadRadius: 0,
                        ),
                        if (hasUnread) ...[
                          BoxShadow(
                            color: const Color(0xFFFFAA22).withValues(alpha: 0.45),
                            blurRadius: 22,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFCC66).withValues(alpha: 0.18),
                            blurRadius: 38,
                            spreadRadius: 0,
                          ),
                        ],
                      ],
                    ),
                    child: Center(
                      child: Image.asset('assets/images/inbox_icon.png',
                          width: 26, height: 26),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: _isLastPage
                    ? _BottomBtn(
                        imagePath: 'assets/images/menuright.png',
                        label: 'Başa Dön',
                        iconTrailing: true,
                        onTap: _goNext,
                      )
                    : _BottomBtn(
                        imagePath: 'assets/images/menuright.png',
                        label: 'Sonraki',
                        iconTrailing: true,
                        onTap: _goNext,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ana Menü 1. Sohbet Balonu ──────────────────────────────────────────────
  // App açılışında bir kez hesaplanır (didChangeDependencies).
  // Her build'de yeniden çağrılmaz — typewriter RangeError'ı önler.
  String _hesaplaSelamlama(String name) {
    final n = name.isNotEmpty ? name : '';
    final List<String> selamlamalar = name.isNotEmpty
        ? [
            'Hoş geldin $n!',
            'Merhaba, seni görmek güzel $n!',
            'Ne iyi ettin de geldin $n!',
            'Hoş geldin, safalar getirdin $n!',
            'Seni burada görmek güzel $n.',
            '$n merhaba! Nasılsın? Dilerim iyisindir. 😊',
          ]
        : [
            'Hoş geldin!',
            'Merhaba, seni görmek güzel!',
            'Ne iyi ettin de geldin!',
            'Hoş geldin, safalar getirdin!',
            'Seni burada görmek güzel.',
            'Merhaba! Nasılsın? Dilerim iyisindir. 😊',
          ];
    final index = DateTime.now().millisecondsSinceEpoch % selamlamalar.length;
    return selamlamalar[index];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri modelleri
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraBubble {
  final String text;
  final List<Color> gradient;
  final Color borderColor;
  const _ExtraBubble({
    required this.text,
    required this.gradient,
    required this.borderColor,
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.item.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCC00BB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCC00BB).withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.item.imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF1A1040)),
                ),
                // Üst karartma
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Alt karartma
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Başlık
                Positioned(
                  top: 6, left: 6, right: 6,
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Kredi rozeti — credits >= 0 ise göster (-1 = badge yok)
                if (widget.item.credits >= 0)
                  Positioned(
                    bottom: 5, left: 5,
                    child: _CreditBadge(count: widget.item.credits),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı widget'lar
// ─────────────────────────────────────────────────────────────────────────────

class _CreditBadge extends StatelessWidget {
  final int count;
  const _CreditBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final used = count <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            used ? Icons.stars_rounded : Icons.stars_rounded,
            color: used ? Colors.white30 : const Color(0xFF00E5FF),
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              color: used ? Colors.white30 : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
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
  final bool isActive; // şu an yazılıyor (false = tamamlandı, tam göster)
  final VoidCallback onComplete;

  const _TypewriterChatBubble({
    super.key,
    required this.text,
    required this.gradient,
    required this.borderColor,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<_TypewriterChatBubble> createState() => _TypewriterChatBubbleState();
}

class _TypewriterChatBubbleState extends State<_TypewriterChatBubble> {
  int _charCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startTyping();
    } else {
      _charCount = widget.text.length; // tamamlanmış balon, tam göster
    }
  }

  @override
  void didUpdateWidget(_TypewriterChatBubble old) {
    super.didUpdateWidget(old);
    // Sıra bu balona geldi
    if (widget.isActive && !old.isActive) {
      _charCount = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_charCount >= widget.text.length) {
        t.cancel();
        widget.onComplete();
        return;
      }
      setState(() => _charCount++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeCount = _charCount.clamp(0, widget.text.length);
    return _ChatBubble(
      text: widget.text.substring(0, safeCount),
      gradient: widget.gradient,
      borderColor: widget.borderColor,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final Color borderColor;

  const _ChatBubble({
    required this.text,
    required this.gradient,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
      ),
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
        border: Border.all(color: const Color(0xFFAA88FF), width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/magnusicon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF4835A6),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
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

class _BottomBtn extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final bool iconTrailing;

  const _BottomBtn({
    required this.imagePath,
    required this.label,
    required this.onTap,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(imagePath, width: 22, height: 22,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22));
    final txt = Text(label,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)]));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCC00DD), Color(0xFF8800BB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCC00EE).withValues(alpha: 0.50),
              blurRadius: 10,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFFF44FF).withValues(alpha: 0.20),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: iconTrailing
              ? [
                  Align(alignment: const Alignment(-1/3, 0),  child: txt),
                  Align(alignment: const Alignment(0.52, 0),  child: img),
                ]
              : [
                  Align(alignment: const Alignment(-0.52, 0), child: img),
                  Align(alignment: const Alignment(1/3, 0),   child: txt),
                ],
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
    const accent  = Color(0xFFFF44FF);
    const size    = 44.0;

    // Ortalama yüzde — tüm hazırlanmakta olanlar
    final avgProgress = widget.items.isEmpty
        ? 0.0
        : widget.items.map((e) => e.unlockProgress).reduce((a, b) => a + b) /
            widget.items.length;
    final avgPct = (avgProgress * 100).round();

    return Row(
      children: [
        // ── Yatay scroll: her fal için bir daire ──────────────────────────
        Expanded(
          child: SingleChildScrollView(
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
          ),
        ),
        if (avgProgress < 1.0) ...[
          const SizedBox(width: 10),
          // ── Sağ: ortalama yüzde dairesi ───────────────────────────────────
          SizedBox(
            width: size, height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(size, size),
                  painter: _ArcProgressPainter(
                    progress: avgProgress,
                    color: accent,
                    trackColor: Colors.white.withValues(alpha: 0.15),
                    strokeWidth: 3.0,
                  ),
                ),
                Text(
                  '$avgPct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    const accent    = Color(0xFFFF44FF);

    // İkon: hazırlanıyorsa grayscale (2 suffix), tamam ise renkli
    final iconPath  = _iconAsset(item.fortuneType, locked: isLocked);
    final innerSize = size - 10;

    return GestureDetector(
      // Sadece hazır (tamamlanmış) fallar tıklanabilir → gelen kutusunu aç
      onTap: isReady ? () => context.push('/inbox-full') : null,
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
              color: isReady ? const Color(0xFF44FF88) : accent,
              trackColor: Colors.white.withValues(alpha: 0.15),
              strokeWidth: 3.0,
            ),
          ),
          // İkon — grayscale veya renkli
          ClipOval(
            child: SizedBox(
              width: innerSize, height: innerSize,
              child: iconPath != null
                  ? Image.asset(
                      iconPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
          // Badge — SADECE hazırlık tamamlanınca (kırmızı nokta)
          if (isReady)
            Positioned(
              top: 1, right: 1,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2222),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
            ),
        ],
      ),
    ),   // SizedBox
    );   // GestureDetector
  }

  Widget _fallbackIcon() => Container(
    color: const Color(0xFF220033),
    child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 16),
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
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc progress CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ArcProgressPainter extends CustomPainter {
  final double progress;   // 0.0 → 1.0
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _ArcProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Arkaplan halkası
    final trackPaint = Paint()
      ..color   = trackColor
      ..style   = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // İlerleme yayı — saatyönünde, tepeden başlar (-π/2)
    if (progress > 0) {
      final arcPaint = Paint()
        ..color   = color
        ..style   = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round;
      canvas.drawArc(
        rect,
        -1.5707963, // -π/2 (saat 12)
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

