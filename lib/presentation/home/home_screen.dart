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
// İki sayfa, her biri 9 ikonluk 3×3 ızgara:
//   Sayfa 1: Motivasyon, Dert Ortağı, Olumlama, Özlü Sözler, Kader Kitabı,
//            Acı Gerçekler, Kehanet, Durugörü, Niyet
//   Sayfa 2: Kahve Falı, Tarot, Astroloji, Numeroloji, Durugörü,
//            Yüz Falı, Japon Falı, I-Ching, Aşk Uyumu
//
// Sayfa geçişi: alt bardaki Önceki/Sonraki butonları VEYA yatay swipe
//   (Listener ile — GestureDetector değil, jest arenası sorunu olmaz).
//   Eşik: 50px yatay hareket. Geçiş animasyonu: 380ms easeInOut.
//
// Sayfa göstergesi: iki ince dikdörtgen (36×3px), aktif sayfa parlak mor.
//   Grid'in içine Stack overlay olarak yerleştirilmiştir (alt kenar).
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
import '../../core/constants/app_colors.dart';
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
  static const _totalPages = 2;

  final List<_ExtraBubble> _extraBubbles = [];
  int _typingIndex = 0; // hangi balon şu an yazılıyor
  late String _selamlama; // sabit, initState'te bir kez hesaplanır

  // Günlük kalan kredi: 1 = hak var, 0 = kullanıldı
  Map<String, int> _remainingCredits = {};

  // Kilit açılma zamanlayıcısı — en erken unlockAt'e göre kurulur
  Timer? _unlockTimer;

  // Pref anahtarları — her fal türü için tamamlanma tarihi
  static const _creditPrefKeys = {
    'motivasyon': 'motivasyon_bugun_tarih',
    'olumlama':   'olumlama_bugun_tarih',
    'ozlusoz':    'ozlusoz_bugun_tarih',
    'tarot':      'tarot_bugun_tarih',
    'kahve':      'kahve_bugun_tarih',
    'astroloji':  'astroloji_bugun_tarih',
  };

  static const _fortuneDisplayNames = {
    'motivasyon': 'Motivasyon',
    'olumlama':   'Olumlama',
    'ozlusoz':    'Özlü Sözler',
    'tarot':      'Tarot',
    'kahve':      'Kahve Falı',
    'astroloji':  'Astroloji',
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
    await context.push(route);
    if (!mounted) return;
    // Ekrandan dönünce kredileri yenile
    // Eğer fal tamamlanmamışsa (geri basıldıysa) date key set edilmemiştir → kredi 1 kalır
    await _refreshCredits();
  }

  void _showDailyLimitBubble(String type) {
    final name = ref.read(userProfileProvider).name;
    final fortuneName = _fortuneDisplayNames[type] ?? type;
    final nameStr = name.isNotEmpty ? ' $name' : '';
    setState(() {
      _extraBubbles.add(_ExtraBubble(
        text: 'Günlük $fortuneName hakkın doldu$nameStr.',
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
            _remainingCredits['motivasyon'] ?? 1,
            () => _onFortuneItemTap('motivasyon', '/motivation')),
        _MenuItem('Dert Ortağı', 'assets/images/menu/dertortagi.png', 1,
            () {}),
        _MenuItem('Olumlama', 'assets/images/olumlama.png',
            _remainingCredits['olumlama'] ?? 1,
            () => _onFortuneItemTap('olumlama', '/olumlama')),
        _MenuItem('Özlü Sözler', 'assets/images/ozlusozler.png',
            _remainingCredits['ozlusoz'] ?? 1,
            () => _onFortuneItemTap('ozlusoz', '/ozlusoz')),
        _MenuItem('Kader Kitabı', 'assets/images/kadercarkimenu.png', 1,
            () {}),
        _MenuItem('Acı Gerçekler', 'assets/images/acigercekler.PNG', 1,
            () {}),
        _MenuItem('Kehanet', 'assets/images/menu/kehanet.png', 1,
            () {}),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 1,
            () {}),
        _MenuItem('Niyet', 'assets/images/menu/mistikfallar.png', 1,
            () {}),
      ];

  // ─── Sayfa 2 ──────────────────────────────────────────────────────────────
  List<_MenuItem> _page2Items(BuildContext context) => [
        _MenuItem('Kahve Falı', 'assets/images/menu/kahvefali.png',
            _remainingCredits['kahve'] ?? 1,
            () => _onFortuneItemTap('kahve', '/coffee')),
        _MenuItem('Tarot', 'assets/images/menu/tarot.png',
            _remainingCredits['tarot'] ?? 1,
            () => _onFortuneItemTap('tarot', '/tarot')),
        _MenuItem('Astroloji', 'assets/images/astroloji.png',
            _remainingCredits['astroloji'] ?? 1,
            () => _onFortuneItemTap('astroloji', '/astrology')),
        _MenuItem('Numeroloji', 'assets/images/menu/numeroloji.png', 1,
            () {}),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 1,
            () {}),
        _MenuItem('Yüz Falı', 'assets/images/menu/yuzfali.png', 1,
            () {}),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Chat header (sabit) ────────────────────────────────────────
            _buildChatHeader(),

            // ─── Animasyonlu 3×3 grid + sayfa göstergesi (overlay) ───────────
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
                          : _page2Items(context);
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


            // ─── Alt bar ───────────────────────────────────────────────────
            _buildBottomBar(context),
          ],
        ),
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
                Row(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF0A0718),
      child: Row(
        children: [
          // Sol buton
          Expanded(
            child: _currentPage == 0
                ? _BottomBtn(
                    imagePath: 'assets/images/bilgiekranilogo.png',
                    label: 'Bilgiler',
                    onTap: () async { _scheduleUnlockTimer(); await context.push('/settings'); if (mounted) await _refreshCredits(); },
                  )
                : _BottomBtn(
                    imagePath: 'assets/images/menuleft.png',
                    label: 'Önceki',
                    onTap: _goPrev,
                  ),
          ),
          const SizedBox(width: 8),
          // Ortadaki inbox butonu — kilitli olmayan okunmamış varsa sarı hale
          Consumer(builder: (_, cref, __) {
            final hasUnread = cref.watch(readyUnreadCountProvider) > 0;
            return GestureDetector(
              onTap: () => context.push('/inbox-full'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 44, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFAA00CC), Color(0xFF7700AA)]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: hasUnread
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFDD00).withValues(alpha: 0.9),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFAA00).withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Image.asset('assets/images/inbox_icon.png',
                      width: 29, height: 29),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          // Sağ buton: son sayfada "Başa Dön", diğerlerinde "Sonraki"
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
    final img = Image.asset(imagePath, width: 23, height: 23);
    final txt = Text(label,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAA00CC), Color(0xFF7700AA)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        // Butonu 3 eşit parçaya böl:
        // Leading: ikon merkezi = 1/3 noktası, yazı merkezi = 2/3 noktası
        // Trailing: yazı merkezi = 1/3 noktası, ikon merkezi = 2/3 noktası
        // Alignment(x,0): x=-1 sol kenar, x=0 merkez, x=1 sağ kenar
        // 1/3 = Alignment(-1/3, 0) | 2/3 = Alignment(1/3, 0)
        child: Stack(
          children: iconTrailing
              ? [
                  Align(alignment: const Alignment(-1/3, 0),   child: txt),
                  Align(alignment: const Alignment(0.52, 0),   child: img),
                ]
              : [
                  Align(alignment: const Alignment(-0.52, 0),  child: img),
                  Align(alignment: const Alignment(1/3, 0),    child: txt),
                ],
        ),
      ),
    );
  }
}

