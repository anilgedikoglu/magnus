// ── AI NOTU: single_tarot_screen.dart ────────────────────────────────────────
// Tek kartlı tarot ekranı. 3 tür: 'ask' (Aşk), 'dilek' (Dilek), 'sans' (Şans).
// TarotTypeScreen'den type parametresiyle açılır: SingleTarotScreen(type: 'ask')
//
// Akış:
//   1. 78 kart karıştırılır, yatay kaydırılabilir deste olarak gösterilir.
//   2. Kullanıcı kartı yukarı sürükler → yuvaya girer → flip animasyonu.
//   3. Kart yerine oturur oturmaz tepki metni belirir (tarot_single_tepki.json).
//   4. 5 saniye kum saati animasyonu → otomatik _generateReading() çağrılır.
//   5. AI yorumu oluşturulur → inbox'a kaydedilir → context.go('/home').
//   6. HomeScreen'de tarotSentProvider=true → Balon 3 eklenir, tarot_bugun_tarih set edilir.
//
// "Yoruma Gönder" butonu bu ekranda YOK — kart seçilince otomatik gider.
// Geri butonu: kart seçilmeden önce çalışır, seçildikten sonra devre dışı.
//
// Tepki metni: assets/data/tarot_single_tepki.json
//   Format: {"AdaIet": "metin", "Asiklar": "metin", ...}  (jsonName key)
//   VariableReplacer.replace() ile işlenir.
//
// Kart görselleri:
//   ask   → assets/images/tarot3/{name_lower}a.jpg
//   dilek → assets/images/tarot4/{name_lower}b.jpg
//   sans  → assets/images/tarot2/{PascalCase}.png  (_sans2file map'i)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/providers.dart';

// ─── Kart verisi ──────────────────────────────────────────────────────────────
//
// JSON kart adları (tarot_single_texts.json'daki 'kart' alanıyla eşleşmeli)
// ask  → assets/images/tarot3/<jsonNameLower>a.jpg
// dilek → assets/images/tarot4/<jsonNameLower>b.jpg
// sans  → assets/images/tarot2/<_sans2file[jsonName]>

class _SingleCard {
  final String jsonName;   // JSON'da kart adı olarak kullanılır
  final String displayName; // Ekranda gösterilen ad
  const _SingleCard(this.jsonName, this.displayName);
}

const _singleCards = [
  _SingleCard('Adalet', 'Adalet'),
  _SingleCard('Asiklar', 'Aşıklar'),
  _SingleCard('AsilanAdam', 'Asılan Adam'),
  _SingleCard('Ay', 'Ay'),
  _SingleCard('Aziz', 'Aziz'),
  _SingleCard('Azize', 'Azize'),
  _SingleCard('Buyucu', 'Büyücü'),
  _SingleCard('Deli', 'Deli (Budala)'),
  _SingleCard('Degnekaltilisi', 'Degnek Altılısı'),
  _SingleCard('Degnekasi', 'Degnek Ası'),
  _SingleCard('Degnekbeslisi', 'Degnek Beşlisi'),
  _SingleCard('Degnekdokuzlusu', 'Degnek Dokuzlusu'),
  _SingleCard('Degnekdortlusu', 'Degnek Dörtlüsü'),
  _SingleCard('Degnekikilisi', 'Degnek İkilisi'),
  _SingleCard('Degnekkrali', 'Degnek Kralı'),
  _SingleCard('Degnekkralicesi', 'Degnek Kraliçesi'),
  _SingleCard('Degnekonlusu', 'Degnek Onlusu'),
  _SingleCard('Degnekprensi', 'Degnek Prensi'),
  _SingleCard('Degneksekizlisi', 'Degnek Sekizlisi'),
  _SingleCard('Degneksovalyesi', 'Degnek Şövalyesi'),
  _SingleCard('Degnekuclusu', 'Degnek Üçlüsü'),
  _SingleCard('Degnekyedilisi', 'Degnek Yedilisi'),
  _SingleCard('Denge', 'Denge'),
  _SingleCard('Dunya', 'Dünya'),
  _SingleCard('Ermis', 'Ermis (Münzevi)'),
  _SingleCard('Guc', 'Güç'),
  _SingleCard('Gunes', 'Güneş'),
  _SingleCard('Imparator', 'İmparator'),
  _SingleCard('Imparatorice', 'İmparatoriçe'),
  _SingleCard('KaderCarki', 'Kader Çarkı'),
  _SingleCard('KilicAsi', 'Kılıç Ası'),
  _SingleCard('Kilicaltilisi', 'Kılıç Altılısı'),
  _SingleCard('Kilicbeslisi', 'Kılıç Beşlisi'),
  _SingleCard('Kilicdokuzlusu', 'Kılıç Dokuzlusu'),
  _SingleCard('Kilicdortlusu', 'Kılıç Dörtlüsü'),
  _SingleCard('Kilicikilisi', 'Kılıç İkilisi'),
  _SingleCard('Kilickrali', 'Kılıç Kralı'),
  _SingleCard('Kilickralicesi', 'Kılıç Kraliçesi'),
  _SingleCard('Kiliconlusu', 'Kılıç Onlusu'),
  _SingleCard('Kilicprensi', 'Kılıç Prensi'),
  _SingleCard('Kilicsekizlisi', 'Kılıç Sekizlisi'),
  _SingleCard('Kilicsovalyesi', 'Kılıç Şövalyesi'),
  _SingleCard('Kilicuclusu', 'Kılıç Üçlüsü'),
  _SingleCard('Kilicyedilisi', 'Kılıç Yedilisi'),
  _SingleCard('KupaAsi', 'Kupa Ası'),
  _SingleCard('Kupaaltilisi', 'Kupa Altılısı'),
  _SingleCard('Kupabeslisi', 'Kupa Beşlisi'),
  _SingleCard('Kupadokuzlusu', 'Kupa Dokuzlusu'),
  _SingleCard('Kupadortlusu', 'Kupa Dörtlüsü'),
  _SingleCard('Kupaikilisi', 'Kupa İkilisi'),
  _SingleCard('Kupakrali', 'Kupa Kralı'),
  _SingleCard('Kupakralicesi', 'Kupa Kraliçesi'),
  _SingleCard('Kupaonlusu', 'Kupa Onlusu'),
  _SingleCard('Kupaprensi', 'Kupa Prensi'),
  _SingleCard('Kupasekizlisi', 'Kupa Sekizlisi'),
  _SingleCard('Kupasovalyesi', 'Kupa Şövalyesi'),
  _SingleCard('Kupauclusu', 'Kupa Üçlüsü'),
  _SingleCard('Kupayedilisi', 'Kupa Yedilisi'),
  _SingleCard('Mahkeme', 'Mahkeme'),
  _SingleCard('Olum', 'Ölüm'),
  _SingleCard('SavasArabasi', 'Savaş Arabası'),
  _SingleCard('Seytan', 'Şeytan'),
  _SingleCard('Tilsimaltilisi', 'Tılsım Altılısı'),
  _SingleCard('Tilsimasi', 'Tılsım Ası'),
  _SingleCard('Tilsimbeslisi', 'Tılsım Beşlisi'),
  _SingleCard('Tilsimdokuzlusu', 'Tılsım Dokuzlusu'),
  _SingleCard('Tilsimdortlusu', 'Tılsım Dörtlüsü'),
  _SingleCard('Tilsimikilisi', 'Tılsım İkilisi'),
  _SingleCard('Tilsimkrali', 'Tılsım Kralı'),
  _SingleCard('Tilsimkralicesi', 'Tılsım Kraliçesi'),
  _SingleCard('Tilsimonlusu', 'Tılsım Onlusu'),
  _SingleCard('Tilsimprensi', 'Tılsım Prensi'),
  _SingleCard('Tilsimsekizlisi', 'Tılsım Sekizlisi'),
  _SingleCard('Tilsimsovalyesi', 'Tılsım Şövalyesi'),
  _SingleCard('Tilsimuclusu', 'Tılsım Üçlüsü'),
  _SingleCard('Tilsimyedilisi', 'Tılsım Yedilisi'),
  _SingleCard('YikilanKule', 'Yıkılan Kule'),
  _SingleCard('Yildiz', 'Yıldız'),
];

// Şans kartları (tarot2) → PascalCase PNG dosya adı
const _sans2file = <String, String>{
  'Adalet': 'Adalet.png',
  'Asiklar': 'Asiklar.png',
  'AsilanAdam': 'AsilanAdam.png',
  'Ay': 'Ay.png',
  'Aziz': 'Aziz.png',
  'Azize': 'Azize.png',
  'Buyucu': 'Buyucu.png',
  'Deli': 'Budala.png',
  'Degnekaltilisi': 'DegnekAltilisi.png',
  'Degnekasi': 'DegnekAsi.png',
  'Degnekbeslisi': 'DegnekBeslisi.png',
  'Degnekdokuzlusu': 'DegnekDokuzlusu.png',
  'Degnekdortlusu': 'DegnekDortlusu.png',
  'Degnekikilisi': 'Degnekikilisi.png',
  'Degnekkrali': 'DegnekKrali.png',
  'Degnekkralicesi': 'DegnekKralicesi.png',
  'Degnekonlusu': 'DegnekOnlusu.png',
  'Degnekprensi': 'DegnekPrensi.png',
  'Degneksekizlisi': 'DegnekSekizlisi.png',
  'Degneksovalyesi': 'DegnekSovalyesi.png',
  'Degnekuclusu': 'DegnekUclusu.png',
  'Degnekyedilisi': 'DegnekYedilisi.png',
  'Denge': 'Denge.png',
  'Dunya': 'Dunya.png',
  'Ermis': 'Ermis.png',
  'Guc': 'Guc.png',
  'Gunes': 'Gunes.png',
  'Imparator': 'Imparator.png',
  'Imparatorice': 'Imparatorice.png',
  'KaderCarki': 'KaderCarki.png',
  'KilicAsi': 'KilicAsi.png',
  'Kilicaltilisi': 'KilicAltilisi.png',
  'Kilicbeslisi': 'Kilicbeslisi.png',
  'Kilicdokuzlusu': 'KilicDokuzlusu.png',
  'Kilicdortlusu': 'Kilicdortlusu.png',
  'Kilicikilisi': 'Kilicikilisi.png',
  'Kilickrali': 'KilicKrali.png',
  'Kilickralicesi': 'KilicKralicesi.png',
  'Kiliconlusu': 'KilicOnlusu.png',
  'Kilicprensi': 'KilicPrensi.png',
  'Kilicsekizlisi': 'KilicSekizlisi.png',
  'Kilicsovalyesi': 'KilicSovalyesi.png',
  'Kilicuclusu': 'Kilicuclusu.png',
  'Kilicyedilisi': 'KilicYedilisi.png',
  'KupaAsi': 'KupaAsi.png',
  'Kupaaltilisi': 'KupaAltilisi.png',
  'Kupabeslisi': 'KupaBeslisi.png',
  'Kupadokuzlusu': 'KupaDokuzlusu.png',
  'Kupadortlusu': 'KupaDortlusu.png',
  'Kupaikilisi': 'Kupaikilisi.png',
  'Kupakrali': 'KupaKrali.png',
  'Kupakralicesi': 'KupaKralicesi.png',
  'Kupaonlusu': 'KupaOnlusu.png',
  'Kupaprensi': 'KupaPrensi.png',
  'Kupasekizlisi': 'KupaSekizlisi.png',
  'Kupasovalyesi': 'KupaSovalyesi.png',
  'Kupauclusu': 'KupaUclusu.png',
  'Kupayedilisi': 'KupaYedilisi.png',
  'Mahkeme': 'Mahkeme.png',
  'Olum': 'Olum.png',
  'SavasArabasi': 'SavasArabasi.png',
  'Seytan': 'Seytan.png',
  'Tilsimaltilisi': 'Tilsimaltilisi.png',
  'Tilsimasi': 'TilsimAsi.png',
  'Tilsimbeslisi': 'TilsimBeslisi.png',
  'Tilsimdokuzlusu': 'Tilsimdokuzlusu.png',
  'Tilsimdortlusu': 'Tilsimdortlusu.png',
  'Tilsimikilisi': 'Tilsimikilisi.png',
  'Tilsimkrali': 'TilsimKrali.png',
  'Tilsimkralicesi': 'TilsimKralicesi.png',
  'Tilsimonlusu': 'Tilsimonlusu.png',
  'Tilsimprensi': 'TilsimPrensi.png',
  'Tilsimsekizlisi': 'TilsimSekizlisi.png',
  'Tilsimsovalyesi': 'TilsimSovalyesi.png',
  'Tilsimuclusu': 'Tilsimuclusu.png',
  'Tilsimyedilisi': 'Tilsimyedilisi.png',
  'YikilanKule': 'YikilanKule.png',
  'Yildiz': 'Yildiz.png',
};

// Kart adına göre asset yolu döndürür
String _assetPath(String type, String jsonName) {
  final base = jsonName == 'Deli' ? 'budala' : jsonName.toLowerCase();
  switch (type) {
    case 'ask':
      return 'assets/images/tarot3/${base}a.jpg';
    case 'dilek':
      return 'assets/images/tarot4/${base}b.jpg';
    case 'sans':
      return 'assets/images/tarot2/${_sans2file[jsonName] ?? '$jsonName.png'}';
    default:
      return 'assets/images/tarot3/${base}a.jpg';
  }
}

// ─── Düzen sabitleri (tarot_screen.dart ile aynı) ────────────────────────────

const double _cardW = 68.0;
const double _cardH = _cardW * 400 / 272; // ≈ 100.0 — arka görsel oranı
const double _overlap = 32.0;
const double _deckAreaH = _cardH + 12;

// Slot boyutu — kart yüzü 276×480 (oran 0.575)
const double _slotW = 116.0;
const double _slotH = _slotW * 480 / 276; // ≈ 201.7

// ─── Ekran ────────────────────────────────────────────────────────────────────

class SingleTarotScreen extends ConsumerStatefulWidget {
  final String type; // 'ask' | 'dilek' | 'sans'

  const SingleTarotScreen({super.key, required this.type});

  @override
  ConsumerState<SingleTarotScreen> createState() => _SingleTarotScreenState();
}

class _SingleTarotScreenState extends ConsumerState<SingleTarotScreen> {
  late final List<_SingleCard> _shuffled;

  int? _selectedIndex;   // seçilen kartın index'i
  String? _selectedName; // gösterilen kart adı (displayName)
  String? _tepkiText;    // kart yerleşince gösterilen kısa tepki
  bool _isGenerating = false;

  // Tepki metinleri: {jsonName: 'text', ...}
  Map<String, dynamic>? _tepkiData;

  Timer? _autoSendTimer;

  int? _draggingIndex;
  bool _nearSlot = false;
  OverlayEntry? _overlayEntry;
  Offset _overlayPos = Offset.zero;

  final _slotKey = GlobalKey();

  String get _title => switch (widget.type) {
    'ask' => 'Aşk Kartı',
    'dilek' => 'Dilek Kartı',
    'sans' => 'Şans Kartı',
    _ => 'Tarot',
  };

  String get _instruction => switch (widget.type) {
    'ask' => 'Aşk kartını seç  (0/1)',
    'dilek' => 'Dilek kartını seç  (0/1)',
    'sans' => 'Şans kartını seç  (0/1)',
    _ => 'Kartı yukarı sürükle  (0/1)',
  };

  @override
  void initState() {
    super.initState();
    _shuffled = List<_SingleCard>.from(_singleCards)..shuffle(Random());
    _loadTepki();
  }

  Future<void> _loadTepki() async {
    final json = await rootBundle.loadString('assets/data/tarot_single_tepki.json');
    if (mounted) setState(() => _tepkiData = jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  bool get _isDone => _selectedIndex != null;

  // ─── Slot algılama ────────────────────────────────────────────────────────

  bool _isCardNearSlot() {
    final box = _slotKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final slotBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final cardCenterY = _overlayPos.dy + _cardH / 2;
    return cardCenterY < slotBottom + 24;
  }

  // ─── Sürükleme ────────────────────────────────────────────────────────────

  void _onDragStart(int index, Offset globalPos) {
    if (_selectedIndex != null || index == _selectedIndex) return;

    _overlayPos = globalPos - Offset(_cardW / 2, _cardH / 2);
    _nearSlot = false;

    setState(() => _draggingIndex = index);

    _overlayEntry = OverlayEntry(
      builder: (_) => _DragOverlaySingle(
        position: _overlayPos,
        nearSlot: _nearSlot,
        cardW: _cardW,
        cardH: _cardH,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingIndex == null) return;
    _overlayPos = details.globalPosition - Offset(_cardW / 2, _cardH / 2);

    final near = _isCardNearSlot();
    if (near && !_isDone) {
      _performSnap(_draggingIndex!);
      return;
    }

    if (near != _nearSlot) _nearSlot = near;
    _overlayEntry?.markNeedsBuild();
  }

  void _onDragEnd(DragEndDetails _) => _cancelDrag();

  void _performSnap(int index) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    final card = _shuffled[index];
    final rawTepki = _tepkiData?[card.jsonName] as String?;
    final tepki = rawTepki != null
        ? VariableReplacer.replace(rawTepki, ref.read(userProfileProvider).toVariableMap())
        : null;
    setState(() {
      _draggingIndex = null;
      _nearSlot = false;
      _selectedIndex = index;
      _selectedName = card.displayName;
      _tepkiText = tepki;
    });
    _autoSendTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isGenerating) _generateReading();
    });
  }

  void _cancelDrag() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _draggingIndex = null;
      _nearSlot = false;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: Text(_title),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _selectedIndex == null ? null : Colors.white24,
          ),
          onPressed: _selectedIndex == null ? () => context.pop() : null,
        ),
      ),
      body: PopScope(
        canPop: _selectedIndex == null,
        child: Column(
          children: [
            _buildInstruction(),
            _buildCardNameLabel(),
            _buildSlot(),
            _buildTepkiLabel(),
            const Spacer(),
            _buildDeck(),
            const Spacer(),
            _buildGoButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTepkiLabel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _tepkiText != null
          ? Padding(
              key: ValueKey(_tepkiText),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                _tepkiText!,
                textAlign: TextAlign.center,
                style: AppTextStyles.inboxTitle.copyWith(
                  fontSize: 13,
                  color: const Color(0xFFB8E0FF),
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            )
          : const SizedBox(key: ValueKey('tepki_empty'), height: 0),
    );
  }

  Widget _buildInstruction() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDone
              ? [AppColors.bubble1.first, AppColors.bubble1.last]
              : [AppColors.backgroundCard, AppColors.backgroundCard],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDone
              ? AppColors.bubbleFrame1.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Text(
        _isDone ? 'Harika! Kartın seçildi ✦' : _instruction,
        textAlign: TextAlign.center,
        style: AppTextStyles.inboxTitle.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildCardNameLabel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _selectedName != null
          ? Padding(
              key: ValueKey(_selectedName),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '✦  $_selectedName  ✦',
                style: const TextStyle(
                  color: Color(0xFFFF88DD),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            )
          : const SizedBox(key: ValueKey('empty'), height: 26),
    );
  }

  Widget _buildSlot() {
    return Container(
      key: _slotKey,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _SlotCardSingle(
        card: _selectedIndex != null ? _shuffled[_selectedIndex!] : null,
        type: widget.type,
      ),
    );
  }

  Widget _buildDeck() {
    final n = _shuffled.length;
    final totalW = _overlap * (n - 1) + _cardW;

    final children = <Widget>[];
    for (int i = 0; i < n; i++) {
      if (_selectedIndex == i) continue;

      final isDragging = i == _draggingIndex;
      children.add(
        Positioned(
          left: i * _overlap,
          top: 0,
          width: _cardW,
          height: _cardH,
          child: IgnorePointer(
            ignoring: isDragging,
            child: Visibility(
              visible: !isDragging,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: GestureDetector(
                onVerticalDragStart: (d) => _onDragStart(i, d.globalPosition),
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: RepaintBoundary(child: _CardBackSingle()),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _deckAreaH,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: _draggingIndex != null
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: totalW,
          height: _deckAreaH,
          child: Stack(clipBehavior: Clip.none, children: children),
        ),
      ),
    );
  }

  Widget _buildGoButton() {
    if (!_isDone) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _isGenerating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB8E0FF)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingHourglass(),
                const SizedBox(height: 6),
                Text(
                  ref.read(l10nProvider).fortuneSending,
                  style: TextStyle(
                    color: const Color(0xFFB8E0FF).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _generateReading() async {
    setState(() => _isGenerating = true);
    try {
      final profile = ref.read(userProfileProvider);
      final service = ref.read(fortuneServiceProvider);
      await service.init();

      final card = _shuffled[_selectedIndex!];
      final item = await service.generateSingleTarotFortune(
        profile: profile,
        type: widget.type,
        cardJsonName: card.jsonName,
        cardDisplayName: card.displayName,
      );
      await ref.read(inboxProvider.notifier).addItem(item);
      if (!mounted) return;
      ref.read(tarotSentProvider.notifier).state = true;
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

// ─── Kum saati animasyonu ─────────────────────────────────────────────────────

class _PulsingHourglass extends StatefulWidget {
  const _PulsingHourglass();

  @override
  State<_PulsingHourglass> createState() => _PulsingHourglassState();
}

class _PulsingHourglassState extends State<_PulsingHourglass> {
  @override
  Widget build(BuildContext context) {
    return const PulsingHourglass(size: 34, color: Color(0xFFB8E0FF));
  }
}

// ─── Sürüklenen kart overlay'i ────────────────────────────────────────────────

class _DragOverlaySingle extends StatelessWidget {
  final Offset position;
  final bool nearSlot;
  final double cardW;
  final double cardH;

  const _DragOverlaySingle({
    required this.position,
    required this.nearSlot,
    required this.cardW,
    required this.cardH,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: cardW,
      height: cardH,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: nearSlot ? 1.12 : 1.04,
          duration: const Duration(milliseconds: 180),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: nearSlot
                      ? AppColors.bubbleFrame1
                      : Colors.white.withValues(alpha: 0.5),
                  width: nearSlot ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: nearSlot
                        ? AppColors.bubbleFrame1.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.5),
                    blurRadius: nearSlot ? 20 : 10,
                    spreadRadius: nearSlot ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/images/tarot_card_back.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1E1550)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Deste arka yüzü ──────────────────────────────────────────────────────────

class _CardBackSingle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'assets/images/tarot_card_back.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF1E1550)),
        ),
      ),
    );
  }
}

// ─── Slot kartı (flip animasyonlu, tek kart) ──────────────────────────────────

class _SlotCardSingle extends StatefulWidget {
  final _SingleCard? card;
  final String type;

  const _SlotCardSingle({this.card, required this.type});

  @override
  State<_SlotCardSingle> createState() => _SlotCardSingleState();
}

class _SlotCardSingleState extends State<_SlotCardSingle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    if (widget.card != null) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_SlotCardSingle old) {
    super.didUpdateWidget(old);
    if (widget.card != null && old.card == null) {
      _ctrl.reset();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.card == null) return _buildEmpty();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final v = _anim.value;
          final showFront = v > 0.5;
          final angle = showFront ? (v - 1.0) * pi : v * pi;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: showFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _slotW,
      height: _slotH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.4),
          width: 1.5,
        ),
        color: AppColors.backgroundCard,
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            color: AppColors.divider.withValues(alpha: 0.6),
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _slotW,
      height: _slotH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          'assets/images/tarot_card_back.jpg',
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF1E1550)),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final assetPath = _assetPath(widget.type, widget.card!.jsonName);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _slotW,
      height: _slotH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.bubbleFrame1,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubbleFrame1.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1E1550)),
        ),
      ),
    );
  }
}
