import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/providers.dart';

// ─── Kart veritabanı ──────────────────────────────────────────────────────────

class _TarotCard {
  final String file;
  final String name;
  const _TarotCard(this.file, this.name);
  String get assetPath => 'assets/images/tarot/$file';
}

const _allCards = [
  _TarotCard('Azize.jpg', 'Azize'),
  _TarotCard('Budala-Deli.jpg', 'Budala (Deli)'),
  _TarotCard('Buyucu.jpg', 'Büyücü'),
  _TarotCard('adalet.jpg', 'Adalet'),
  _TarotCard('araba.jpg', 'Araba'),
  _TarotCard('asaaltilisi.jpg', 'Asa Altılısı'),
  _TarotCard('asaasi.jpg', 'Asa Ası'),
  _TarotCard('asabeslisi.jpg', 'Asa Beşlisi'),
  _TarotCard('asadokuzlusu.jpg', 'Asa Dokuzlusu'),
  _TarotCard('asadortlusu.jpg', 'Asa Dörtlüsü'),
  _TarotCard('asaikilisi.jpg', 'Asa İkilisi'),
  _TarotCard('asakrali.jpg', 'Asa Kralı'),
  _TarotCard('asakralicesi.jpg', 'Asa Kraliçesi'),
  _TarotCard('asaonlusu.jpg', 'Asa Onlusu'),
  _TarotCard('asaprensi.jpg', 'Asa Prensi'),
  _TarotCard('asasekizlisi.jpg', 'Asa Sekizlisi'),
  _TarotCard('asasovalyesi.jpg', 'Asa Şövalyesi'),
  _TarotCard('asauclusu.jpg', 'Asa Üçlüsü'),
  _TarotCard('asayedilisi.jpg', 'Asa Yedilisi'),
  _TarotCard('asiklar.jpg', 'Aşıklar'),
  _TarotCard('asilanadam.jpg', 'Asılan Adam'),
  _TarotCard('ay.jpg', 'Ay'),
  _TarotCard('aziz.jpg', 'Aziz'),
  _TarotCard('denge.jpg', 'Denge'),
  _TarotCard('dunya.jpg', 'Dünya'),
  _TarotCard('guc.jpg', 'Güç'),
  _TarotCard('gunes.jpg', 'Güneş'),
  _TarotCard('imparator.jpg', 'İmparator'),
  _TarotCard('imparatorice.jpg', 'İmparatoriçe'),
  _TarotCard('kadercarki.jpg', 'Kader Çarkı'),
  _TarotCard('kilicaltilisi.jpg', 'Kılıç Altılısı'),
  _TarotCard('kilicasi.jpg', 'Kılıç Ası'),
  _TarotCard('kilicbeslisi.jpg', 'Kılıç Beşlisi'),
  _TarotCard('kilicdokuzlusu.jpg', 'Kılıç Dokuzlusu'),
  _TarotCard('kilicdortlusu.jpg', 'Kılıç Dörtlüsü'),
  _TarotCard('kilicikilisi.jpg', 'Kılıç İkilisi'),
  _TarotCard('kilickrali.jpg', 'Kılıç Kralı'),
  _TarotCard('kilickralicesi.jpg', 'Kılıç Kraliçesi'),
  _TarotCard('kiliconlusu.jpg', 'Kılıç Onlusu'),
  _TarotCard('kilicprensi.jpg', 'Kılıç Prensi'),
  _TarotCard('kilicsekizlisi.jpg', 'Kılıç Sekizlisi'),
  _TarotCard('kilicsovalyesi.jpg', 'Kılıç Şövalyesi'),
  _TarotCard('kilicuclusu.jpg', 'Kılıç Üçlüsü'),
  _TarotCard('kilicyedilisi.jpg', 'Kılıç Yedilisi'),
  _TarotCard('kupaaltilisi.jpg', 'Kupa Altılısı'),
  _TarotCard('kupaasi.jpg', 'Kupa Ası'),
  _TarotCard('kupabeslisi.jpg', 'Kupa Beşlisi'),
  _TarotCard('kupadokuzlusu.jpg', 'Kupa Dokuzlusu'),
  _TarotCard('kupadortlusu.jpg', 'Kupa Dörtlüsü'),
  _TarotCard('kupaikilisi.jpg', 'Kupa İkilisi'),
  _TarotCard('kupakrali.jpg', 'Kupa Kralı'),
  _TarotCard('kupakralicesi.jpg', 'Kupa Kraliçesi'),
  _TarotCard('kupaonlusu.jpg', 'Kupa Onlusu'),
  _TarotCard('kupaprensi.jpg', 'Kupa Prensi'),
  _TarotCard('kupasekizlisi.jpg', 'Kupa Sekizlisi'),
  _TarotCard('kupasovalyesi.jpg', 'Kupa Şövalyesi'),
  _TarotCard('kupauclusu.jpg', 'Kupa Üçlüsü'),
  _TarotCard('kupayedilisi.jpg', 'Kupa Yedilisi'),
  _TarotCard('mahkeme.jpg', 'Mahkeme'),
  _TarotCard('munzevi.jpg', 'Münzevi'),
  _TarotCard('olum.jpg', 'Ölüm'),
  _TarotCard('seytan.jpg', 'Şeytan'),
  _TarotCard('tilsimaltilisi.jpg', 'Tılsım Altılısı'),
  _TarotCard('tilsimasi.jpg', 'Tılsım Ası'),
  _TarotCard('tilsimbeslisi.jpg', 'Tılsım Beşlisi'),
  _TarotCard('tilsimdokuzlusu.jpg', 'Tılsım Dokuzlusu'),
  _TarotCard('tilsimdortlusu.jpg', 'Tılsım Dörtlüsü'),
  _TarotCard('tilsimikilisi.jpg', 'Tılsım İkilisi'),
  _TarotCard('tilsimkrali.jpg', 'Tılsım Kralı'),
  _TarotCard('tilsimkralicesi.jpg', 'Tılsım Kraliçesi'),
  _TarotCard('tilsimonlusu.jpg', 'Tılsım Onlusu'),
  _TarotCard('tilsimprensi.jpg', 'Tılsım Prensi'),
  _TarotCard('tilsimsekizlisi.jpg', 'Tılsım Sekizlisi'),
  _TarotCard('tilsimsovalyesi.jpg', 'Tılsım Şövalyesi'),
  _TarotCard('tilsimuclusu.jpg', 'Tılsım Üçlüsü'),
  _TarotCard('tilsimyedilisi.jpg', 'Tılsım Yedilisi'),
  _TarotCard('yikilankule.jpg', 'Yıkılan Kule'),
  _TarotCard('yildiz.jpg', 'Yıldız'),
];

// ─── Düzen sabitleri ──────────────────────────────────────────────────────────

const double _cardW = 68.0;
const double _cardH = 118.0;
const double _overlap = 32.0;       // her kartın görünen yatay genişliği
const double _deckAreaH = _cardH + 12;

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class TarotScreen extends ConsumerStatefulWidget {
  const TarotScreen({super.key});

  @override
  ConsumerState<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends ConsumerState<TarotScreen> {
  late final List<_TarotCard> _shuffled;

  // Seçimler: kartIndex → seçim sırası (1,2,3)
  final Map<int, int> _selected = {};
  String? _lastSelectedName;
  bool _isGenerating = false;

  // Sürükleme durumu
  int? _draggingIndex;
  bool _nearSlot = false;
  OverlayEntry? _overlayEntry;
  Offset _overlayPos = Offset.zero;

  // Slot alanının konumunu almak için
  final _slotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _shuffled = List<_TarotCard>.from(_allCards)..shuffle(Random());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  int get _selectedCount => _selected.length;
  bool get _isDone => _selectedCount == 3;

  // ─── Slot algılama ────────────────────────────────────────────────────────

  bool _isCardNearSlot() {
    final box = _slotKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final slotBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final cardCenterY = _overlayPos.dy + _cardH / 2;
    return cardCenterY < slotBottom + 24;
  }

  // ─── Sürükleme olayları ───────────────────────────────────────────────────

  void _onDragStart(int index, Offset globalPos) {
    if (_selected.containsKey(index) || _isDone) return;

    _overlayPos = globalPos - Offset(_cardW / 2, _cardH / 2);
    _nearSlot = false;

    setState(() => _draggingIndex = index);

    _overlayEntry = OverlayEntry(
      builder: (_) => _DragOverlay(
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
      // Kart slota yaklaşınca otomatik snap
      _performSnap(_draggingIndex!);
      return;
    }

    if (near != _nearSlot) {
      _nearSlot = near;
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _onDragEnd(DragEndDetails _) {
    // Snap olmadan bırakıldı → iptal
    _cancelDrag();
  }

  void _performSnap(int index) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _draggingIndex = null;
      _nearSlot = false;
      _selected[index] = _selectedCount + 1;
      _lastSelectedName = _shuffled[index].name;
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
        title: const Text('Tarot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildInstruction(),
          _buildCardNameLabel(),
          _buildSelectedSlots(),
          const Spacer(),
          _buildDeck(),
          const Spacer(),
          _buildGoButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    final isDone = _isDone;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDone
              ? [AppColors.bubble1.first, AppColors.bubble1.last]
              : [AppColors.backgroundCard, AppColors.backgroundCard],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? AppColors.bubbleFrame1.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Text(
        isDone
            ? 'Harika! Kartların seçildi ✦'
            : 'Kartı yukarı sürükleyerek seç  (${_selectedCount}/3)',
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
      child: _lastSelectedName != null
          ? Padding(
              key: ValueKey(_lastSelectedName),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '✦  $_lastSelectedName  ✦',
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

  Widget _buildSelectedSlots() {
    return Container(
      key: _slotKey,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (slot) {
          final entry = _selected.entries
              .where((e) => e.value == slot + 1)
              .firstOrNull;
          final card = entry != null ? _shuffled[entry.key] : null;

          return _SlotCard(
            key: ValueKey(card?.file ?? 'slot_$slot'),
            card: card,
            slotNumber: slot + 1,
          );
        }),
      ),
    );
  }

  Widget _buildDeck() {
    final n = _shuffled.length;
    final totalW = _overlap * (n - 1) + _cardW;

    final children = <Widget>[];
    for (int i = 0; i < n; i++) {
      if (_selected.containsKey(i)) continue; // seçilmiş kartlar gizli

      final isDragging = i == _draggingIndex;
      children.add(
        Positioned(
          left: i * _overlap,
          top: 0,
          width: _cardW,
          height: _cardH,
          child: Opacity(
            opacity: isDragging ? 0.25 : 1.0,
            child: GestureDetector(
              onVerticalDragStart: (d) => _onDragStart(i, d.globalPosition),
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: _CardBack(),
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
          child: Stack(
            clipBehavior: Clip.none,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildGoButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isDone ? 1.0 : 0.3,
        child: GestureDetector(
          onTap: _isDone && !_isGenerating ? _generateReading : null,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: _isDone
                  ? const LinearGradient(
                      colors: AppColors.bubble1,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _isDone ? null : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _isDone
                  ? [
                      BoxShadow(
                        color: AppColors.bubble1.first.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: _isGenerating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isDone ? 'Falımı Göster ✨' : '3 Kart Seç',
                      style: AppTextStyles.answerText.copyWith(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateReading() async {
    setState(() => _isGenerating = true);
    try {
      final profile = ref.read(userProfileProvider);
      final service = ref.read(fortuneServiceProvider);
      await service.init();
      final item = await service.generateTarotFortune(profile: profile);
      await ref.read(inboxProvider.notifier).addItem(item);
      if (!mounted) return;
      context.go('/tarot_result/${item.id}');
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

// ─── Sürüklenen kart overlay'i ────────────────────────────────────────────────

class _DragOverlay extends StatelessWidget {
  final Offset position;
  final bool nearSlot;
  final double cardW;
  final double cardH;

  const _DragOverlay({
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
                      Container(color: const Color(0xFF1E1550)),
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

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3A2A70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/images/tarot_card_back.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1E1550)),
        ),
      ),
    );
  }
}

// ─── Slot kartı (flip animasyonlu) ────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final _TarotCard? card;
  final int slotNumber;

  const _SlotCard({super.key, this.card, required this.slotNumber});

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  static const double _w = 58.0;
  static const double _h = 90.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    if (widget.card != null) {
      // Küçük gecikmeyle flip başlasın (snap animasyonundan sonra)
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_SlotCard old) {
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

    return AnimatedBuilder(
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
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.4),
          width: 1.5,
        ),
        color: AppColors.backgroundCard,
      ),
      child: Center(
        child: Text(
          '${widget.slotNumber}',
          style: TextStyle(
            color: AppColors.divider.withValues(alpha: 0.6),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'assets/images/tarot_card_back.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1E1550)),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bubbleFrame1, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubbleFrame1.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          widget.card!.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1E1550)),
        ),
      ),
    );
  }
}
