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
// ── MENÜ YAPISI (tek ana menü, 3×9) — Anıl, 2026-11-05 ───────────────────
// Sayfa YOK: 27 kart tek ızgarada, 3 sütun × 9 satır, yukarıdan aşağı kaydırılır
// (_buildGrid). Sıra = eski sayfa 1 + 2 + 3 (_page1Items/_page2Items/_page3Items);
// her 3 satırlık grup eski sayfa rengini korur (pembe / mavi / yeşil).
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
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../core/widgets/tab_swipe.dart';
import '../../core/widgets/word_safe_text.dart';
import '../../data/providers.dart';
import '../shell/main_tabs.dart';
import 'home_header_layout.dart';
import 'menu_layout.dart';

/// Ana menünün (menu layer 1, ikonlar) düz arka plan rengi (Anıl'ın örneği: rgb 12,15,20).
const Color kHomeBackground = Color(0xFF0C0F14);

/// Menu layer 2'nin (üstteki 3 sıra sohbet balonu) zemini (Anıl'ın örneği: rgb 21,21,21).
const Color kHomeHeaderBackground = Color(0xFF151515);

/// Menu layer 2 (Anıl, 2026-11-06): yüksekliği O AN görünen balon satırı kadar (en çok
/// [kChatMaxRows]); satır eklenince ızgara (layer 1) yumuşakça aşağı iner, boşluk kalmaz.
/// Nizami ölçüler: satır arası, alt iç boşluk ve layer 2 ile ızgara arası 8; üstte durum çubuğunun
/// güvenli alanı zaten nefes payı verdiği için yalnız 4 (Anıl: "en üstte boşluk görüyorum").
const double kChatPadTop = 4;
const double kChatPadBottom = 8;
const double kChatRowGap = 8;
const double kHomeLayerGap = 8;

/// Yukarı kaydırmada layer 2 bu kadar yerinde durur, menü ALTINA girer; sonra menüyle
/// birlikte yukarı çıkıp kaybolur (Anıl, 2026-11-06). Geri gelişte simetrik.
const double kHomeHeaderHold = 120;

/// Layer 2 en çok bu kadar satır gösterir; fazlası kendi içinde yukarı kayar.
const int kChatMaxRows = 3;

/// Satır yüksekliği ölçülene kadarki tahmin (avatar 38, tek satır balon ~40).
const double _kChatRowEstimate = 40;

/// Layer 2'nin güvenli alan altındaki yüksekliği: [rows] satır balon + iç boşluklar.
double chatHeaderHeightFor(int rows, double rowH) =>
    kChatPadTop + rows * rowH + (rows - 1) * kChatRowGap + kChatPadBottom;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Tek ana menü (Anıl, 2026-11-05): 3 sütun × 9 satır, yukarıdan aşağı kaydırmalı.
  final ScrollController _gridScrollCtrl = ScrollController();
  final ScrollController _chatScrollCtrl = ScrollController();

  // Layer 2'nin canlı yüksekliği (güvenli alan altı) = son en çok 3 görünen satırın
  // ÖLÇÜLEN boyu (balon metni dar ekranda / büyük yazıda iki satıra taşabilir — Codex).
  final Map<int, double> _rowH = {};
  double _hdrTarget = chatHeaderHeightFor(1, _kChatRowEstimate);
  late final AnimationController _hdrCtrl =
      AnimationController.unbounded(vsync: this, value: _hdrTarget);

  // Bant artık scroll'a BAĞLI DEĞİL (Anıl, 2026-11-06): yalnız Magnus bir şey söyleyince ÜST'ten
  // pop-up gibi iner, 5 sn sonra yukarı kalkıp gizlenir. Menü ızgarası TAM EKRAN en üstten başlar.
  // 0 = gizli (yukarıda), 1 = inmiş/görünür.
  late final AnimationController _bandShow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  Timer? _bandTimer;
  int _lastExtraCount = 0; // _extraBubbles büyüyünce bandı patlat (fal durumu / günlük limit)
  bool _downInBand = false;
  bool _downDismiss = false;
  int? _gatePointer; // bayrakları koyan parmak

  double get _layerHeight => MediaQuery.paddingOf(context).top + max(0.0, _hdrCtrl.value);

  /// Bandın ekrandaki alt kenarı (görünürlük payıyla) — dokunuş bunun altındaysa bant bölgesidir.
  double get _bandBottom => _layerHeight * _bandShow.value;

  /// Yeni Magnus mesajı gelince bandı aşağı indir (pop); [hold] kadar durup yukarı kaldır.
  /// Her chat gelişi 10 sn kalır (Anıl, 2026-11-07: "her chat gelişte 10 saniye kalıp öyle gitsin").
  void _popBand({Duration hold = const Duration(seconds: 10)}) {
    if (!mounted) return;
    _bandTimer?.cancel();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _bandShow.value = 1;
    } else {
      _bandShow.forward();
    }
    // Balonlar yazıldıkça içerik en alta kaysın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _chatScrollCtrl.hasClients) {
        _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
      }
    });
    _bandTimer = Timer(hold, _hideBand);
  }

  void _hideBand() {
    if (!mounted) return;
    _bandTimer?.cancel();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _bandShow.value = 0;
    } else {
      _bandShow.reverse();
    }
  }

  /// Izgaraya dokunuş: bant görünürken üstüne dokunuş altındaki kartı açmasın + bandı erken kapatsın.
  void _onGridPointerDown(PointerDownEvent e) {
    _gatePointer = e.pointer;
    _downInBand = _bandShow.value > 0.01 && e.localPosition.dy < _bandBottom;
    _downDismiss = false;
    if (_downInBand) _hideBand();
  }

  /// Parmak kalkınca bayraklar sıfırlanır. Kartın onTap'i aynı olay işlemesinde (arena
  /// süpürmesinde) çalışır; sıfırlama mikro görevde, yani ondan SONRA olur. Böylece ekran
  /// okuyucunun (işaretçisiz) kart etkinleştirmesi önceki dokunuşun engeline takılmaz.
  void _onGridPointerEnd(PointerEvent e) {
    final p = e.pointer;
    scheduleMicrotask(() {
      if (_gatePointer != p) return; // arada yeni dokunuş başladıysa onun bayrakları kalır
      _gatePointer = null;
      _downInBand = false;
      _downDismiss = false;
    });
  }

  void _onRowHeight(int i, double h) {
    if (!mounted || _rowH[i] == h) return;
    setState(() => _rowH[i] = h);
  }

  /// O an görünen balon sayısı (sabit 2 + ekstralar; yazılan balon dahil).
  int get _visibleBubbles => (_typingIndex + 1).clamp(1, 2 + _extraBubbles.length);

  /// Layer 2'nin hedef yüksekliği: son en çok [kChatMaxRows] satırın ölçülen boyları +
  /// aralıklar + iç boşluklar. Ölçülmemiş satır için ilk satırın boyu (yoksa tahmin).
  double _chatTargetHeight(int n) {
    final start = max(0, n - kChatMaxRows);
    final fallback = _rowH[0] ?? _kChatRowEstimate;
    var h = kChatPadTop + kChatPadBottom + (n - start - 1) * kChatRowGap;
    for (var i = start; i < n; i++) {
      h += _rowH[i] ?? fallback;
    }
    return h;
  }

  /// Layer 2'yi hedef yüksekliğe aşmasız yayla götür (ızgara birlikte iner/çıkar).
  void _retargetHeader(double target) {
    if (!mounted) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce || (_hdrCtrl.value - target).abs() < 0.5) {
      _hdrCtrl.value = target;
      return;
    }
    _hdrCtrl.animateWith(
        SpringSimulation(kHomeHeaderSpring, _hdrCtrl.value, target, _hdrCtrl.velocity));
  }

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
    'tavsanfali':   'tavsanfali_bugun_tarih',
    'kadercarki':   'kadercarki_bugun_tarih',
    'askuyumu':     'askuyumu_bugun_tarih',
    // 'numeroloji' burada yok — limit ekran içinden yönetilir
  };

  String get _today => DateTime.now().toIso8601String().substring(0, 10);


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
      // Band GİZLİ başlar; selamlama JSON'u arka planda yüklenir. Band görünmediği için
      // typewriter henüz çalışmaz (layer 2 band açılana kadar mount edilmez) → açılışta yazı akmaz.
      _loadSelamlama();
      // Açılıştan TAM 3 sn sonra band TAZE iner (Anıl, 2026-11-07: "önce açılsın, chat
      // açılıştan 3 saniye sonra gelsin"); açılış selamlaması 10 sn kalır ya da yukarı swipe'a kadar.
      _bandTimer?.cancel();
      _bandTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) _popBand(hold: const Duration(seconds: 10));
      });
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
    _bandTimer?.cancel();
    _gridScrollCtrl.dispose();
    _chatScrollCtrl.dispose();
    _hdrCtrl.dispose();
    _bandShow.dispose();
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
    } else if (result == 'zaten_okundu') {
      // Kader Kitabı o gün okunmuşsa "okudun" mesajı kitapta DEĞİL, ana menü sohbetinde
      // söylenir (Anıl, 2026-11-06). Ekran kendini kapatıp bu sonucu döndürür.
      _showDailyLimitBubble(type);
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
    // Dönüşte rozeti yenile (Tavşan Falı gibi ekranda tamamlanan fallar için).
    context.push(route).then((_) {
      if (mounted) _refreshCredits();
    });
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

  // ─── Satır 4-6 (eski sayfa 2) ───────────────────────────────────────────────
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
            () => _pushWithAd('/ruya_yorumu')),
        // Rüya Yorumu ile Doğum Haritası arası: Tavşan Falı (günde 1, 2026-11-05)
        _MenuItem(s.rabbitFortune, 'assets/images/tavsanfali/tavsanfali_menu.jpg',
            _remainingCredits['tavsanfali'] ?? 1,
            () => _onDailyFalTap('tavsanfali', '/tavsanfali')), // günde 1: bugün çektiyse balon (Anıl)
        _MenuItem(s.birthChart, 'assets/images/dogum.png',
            1, () => _pushWithAd('/dogumharitasi')),
        // Rüya Yorumu'nun altı: Kısmetim Kim? (2026-11-05)
        _MenuItem(s.whoIsMyDestiny, 'assets/images/kismetim/kismetim_menu.jpg', 1,
            () => _pushWithAd('/kismetim')),
        // Kısmetim'in sağı: Arabam Ne? (2026-11-05)
        _MenuItem(s.whatIsMyCar, 'assets/images/arabam/arabam_menu.jpg', 1,
            () => _pushWithAd('/arabam')),
        // Arabam'ın sağı (son yer): Evim Neresi? (2026-11-05)
        _MenuItem(s.whereIsMyHome, 'assets/images/evim/evim_menu.jpg', 1,
            () => _pushWithAd('/evim')),
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
    // Ana menüdeyken bardaki eve tekrar dokunuş → listenin başına kaydır (iOS alışkanlığı).
    // Yalnız ana menü görünürken (başka sekmeye tekrar dokunuş listeyi başa sarmasın).
    ref.listen<int>(mainTabReselectProvider, (_, __) {
      if (ref.read(mainTabProvider) == MainTab.home) _scrollGridToTop();
    });

    // ── Ana menü arka planı: DÜMDÜZ koyu renk (Anıl, 2026-11-05 "ikonların olduğu yerden
    // background'u kaldırıp bg'yi dümdüz bu renk yap" — örnek görselden ölçüldü #0C0F14).
    // Eski welcomscreenbackground.jpg + %42 karartma kaldırıldı.
    // ── İki katman (Anıl, 2026-11-05) ──────────────────────────────────────
    //   Menu layer 1 = ikon ızgarası: TAM EKRAN, içerik layer 2'nin alt kenarından başlar.
    //   Menu layer 2 = üstteki 3 sıra sohbet balonu: ayrı ÜST katman, ekranın en üstünden
    //     3. sıranın hemen altına kadar, zemin #151515.
    //   Yukarı kaydırınca layer 2 ızgarayla AYNI hızda yukarı kayar ve ekrandan çıkar;
    //   aşağı çekince ızgara başa yaklaşınca (kalan yol < layer 2 yüksekliği) ekranın
    //   üstünden aynı hızla iner, ilk yerinde DURUR (üstte esneme olsa da aşağı inmez).
    //   Ofset = ızgara kaydırması, [0, layer 2 yüksekliği] aralığına kırpılmış.
    final topInset = MediaQuery.paddingOf(context).top;
    // Hedef boy değişince (yeni satır, satır kırılması) bant yayla ona gider.
    final shown = _visibleBubbles;
    final chatHeight = _chatTargetHeight(shown);
    if (chatHeight != _hdrTarget) {
      _hdrTarget = chatHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) => _retargetHeader(chatHeight));
    }
    // Yeni Magnus mesajı (fal durumu / günlük limit → _extraBubbles büyür) gelince bandı patlat.
    // Süre, yeni eklenen balon(lar)ın toplam uzunluğuna göre (uzun mesaj bitmeden kapanmasın — Codex P2).
    if (_extraBubbles.length != _lastExtraCount) {
      _lastExtraCount = _extraBubbles.length;
      // Her yeni Magnus mesajında band 10 sn kalır (Anıl, 2026-11-07).
      WidgetsBinding.instance.addPostFrameCallback((_) => _popBand());
    }
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
            child: Listener(
              onPointerDown: _onGridPointerDown,
              onPointerUp: _onGridPointerEnd,
              onPointerCancel: _onGridPointerEnd,
              child: TabSwipe(
                onSwipeLeft: () =>
                    selectMainTab(context, MainTab.inbox, entry: TabEntry.right),
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (n) {
                    // Yukarı swipe (menüyü kaydır) → açık selamlama bandını kapat
                    // (Anıl: açılış yazısı 10 sn kalsın ya da yukarı swipe'a kadar).
                    if (n.direction == ScrollDirection.reverse &&
                        _bandShow.value > 0.01) {
                      _hideBand();
                    }
                    return false;
                  },
                  child: _buildGrid(context, topExtra: topInset + kHomeLayerGap),
                ),
              ),
            ),
          ),
          // ── Menu layer 2: sohbet balonları (ızgarayla birlikte kayar) ────────
          // Yükseklik canlı: görünen satır kadar (_hdrCtrl). Balonlar hedef boyda dizilir,
          // fazlası kırpılır → yeni satır, bant genişledikçe üstten açılır. Zemin hep canlı
          // boyu doldurur (küçülürken de). Izgaranın kaydırma ofseti BOYAMA anında okunur.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bandShow,
              builder: (context, child) {
                final s = _bandShow.value.clamp(0.0, 1.0);
                // Gizliyken HİÇ yer/hit yok → ızgara en üstten tam tıklanabilir (tam ekran menü).
                if (s <= 0.001) return const SizedBox.shrink();
                final bandH = topInset + max(0.0, _hdrCtrl.value);
                return Transform.translate(
                  offset: Offset(0, -(1 - s) * bandH),
                  child: Opacity(opacity: s, child: child),
                );
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideBand, // banda dokun → erken kapat
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _hdrCtrl,
                    builder: (context, child) => SizedBox(
                      key: const ValueKey('homeMenuLayer2'),
                      height: topInset + max(0.0, _hdrCtrl.value),
                      child: child,
                    ),
                    child: ColoredBox(
                      color: kHomeHeaderBackground,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: topInset + chatHeight,
                          maxHeight: topInset + chatHeight,
                          child: Padding(
                            padding: EdgeInsets.only(top: topInset),
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (_) => true,
                              child: _buildChatHeader(chatHeight, shown),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [height]: son en çok 3 satır kadar; daha eski balonlar yukarı kayıp gizlenir.
  Widget _buildChatHeader(double height, int shown) {
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
    final visibleCount = shown.clamp(0, bubbles.length);

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        controller: _chatScrollCtrl,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, kChatPadTop, 12, kChatPadBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < bubbles.length; i++)
              if (i < visibleCount) ...[
                if (i > 0) const SizedBox(height: kChatRowGap),
                // Görünen balon sayısına göre eskilere doğru opasite düşür
                Opacity(
                  opacity: visibleCount >= 3
                      ? (i == visibleCount - 1 ? 1.0 : (i == visibleCount - 2 ? 0.60 : 0.30))
                      : visibleCount == 2
                          ? (i == 0 ? 0.60 : 1.0)
                          : 1.0,
                  child: HeightReporter(
                    // Her satır ölçülür: balon metni iki satıra taşabilir, ikonlu balon farklı.
                    onHeight: (h) => _onRowHeight(i, h),
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
                            enableMarquee: false, // kayan uzun yazı kaldırıldı (Anıl, 2026-11-06); uzunlar havuzdan elenir + sarılır
                            onComplete: () => _onBubbleComplete(i),
                            iconPath: bubbles[i].iconPath,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ],
          ],
        ),
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

  /// Menü (Anıl, 2026-11-05): üç düzen, açılışta 1/3 ihtimalle (menu_layout.dart).
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
    // Her dokunuş kullanım sayımına yazılır (Düzen 3 sıralaması bir SONRAKİ açılışta).
    final items = [
      for (final it in base)
        _MenuItem(it.title, it.imagePath, it.credits, () {
          // Sohbet bandının üstüne dokunuş, altındaki kartı açmasın.
          if (_downInBand || _downDismiss) return;
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
      case MenuLayout.grid:
        slivers = [cells(List<int>.generate(items.length, (i) => i))];
      case MenuLayout.bigBlocks:
        final bigs = sessionBigPicks(ids, prefs);
        final rest = [for (var i = 0; i < items.length; i++) if (!bigs.contains(i)) i];
        slivers = [
          big(bigs[0]),
          space(gap),
          cells(rest.sublist(0, 12)),
          space(gap),
          big(bigs[1]),
          space(gap),
          cells(rest.sublist(12, 24)),
          space(gap),
          big(bigs[2]),
        ];
      case MenuLayout.favorites:
        final order = orderByUsage(ids, sessionUsage(prefs));
        slivers = [
          header(s.menuFavorites),
          cells(order.sublist(0, 6)),
          space(22),
          header(s.menuOtherTypes),
          cells(order.sublist(6)),
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

      // Çok uzun (eskiden kayan) karşılama metinlerini ELE → bant kısa kalsın (Anıl, 2026-11-06).
      // ~110+ karakter ≈ 3+ satır. Havuz tümüyle uzunsa güvenli yedek: filtresiz havuz.
      bool kisa(Map<String, dynamic> e) {
        final t = ((isEn ? e['metin_en'] as String? : null) ?? e['metin'] as String? ?? '').trim();
        return t.length <= 110;
      }
      final havuzKisa = havuz.where(kisa).toList();
      if (havuzKisa.isNotEmpty) havuz = havuzKisa;

      // %10 Biliyor muydun? (yalnızca 1. ziyarette; yalnız kısa olanlar — uzunlar artık gösterilmez)
      List<Map<String, dynamic>> secimHavuzu = havuz;
      String noRepeatKey = 'karsilama_gosterilen_$ziyaretKey';
      if (visitCount == 1 && Random().nextDouble() < 0.10) {
        final bmKisa = biliyormuydun.where(kisa).toList();
        if (bmKisa.isNotEmpty) {
          secimHavuzu = bmKisa;
          noRepeatKey = 'karsilama_gosterilen_biliyormuydun';
        }
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
        decoration: _oldBubble(widget.gradient, widget.borderColor),
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
  topLeft: Radius.circular(4), topRight: Radius.circular(14),
  bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
);
/// 2026-11-05 eski renkler: balon, çağıranın gradyanı + çerçeve rengi (%50) ile çizilir.
BoxDecoration _oldBubble(List<Color> gradient, Color border) => BoxDecoration(
      gradient: LinearGradient(
        colors: gradient.length >= 2 ? gradient : [gradient.first, gradient.first],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: _bubbleRadius,
      border: Border.all(color: border.withValues(alpha: 0.5)),
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
      decoration: _oldBubble(gradient, borderColor),
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
        border: Border.all(color: const Color(0xFFAA88FF), width: 1.0),
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
