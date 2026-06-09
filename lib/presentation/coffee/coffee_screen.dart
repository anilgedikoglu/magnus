// ── AI NOTU: coffee_screen.dart ───────────────────────────────────────────────
// Kahve Falı ekranı. Kullanıcı fotoğraf gönderme yöntemini seçer:
//   • Foto Çek  → kamera açılır, 3 kare yan yana doldurulur
//   • Dosyadan  → galeri açılır, 3 kare yan yana doldurulur
//   • Yerime İç → Fincan1/3/5 arasından rastgele bir fincan görseli
//
// Fal gönderme koşulu:
//   Foto Çek / Dosyadan → 3 fotoğrafın TAMAMI dolu olunca buton aktif
//   Yerime İç           → seçildiği anda buton aktif
//
// "Falımı Gönder" butonuna basılınca:
//   1. kahveSentProvider = true  (HomeScreen balon + kredi işaretler)
//   2. context.go('/home')
//   3. Fal arka planda üretilip inbox'a eklenir
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/providers.dart';

class CoffeeScreen extends ConsumerStatefulWidget {
  const CoffeeScreen({super.key});

  @override
  ConsumerState<CoffeeScreen> createState() => _CoffeeScreenState();
}

enum _InputMode { none, fotoCek, dosyadan, yerimeIc }

class _CoffeeScreenState extends ConsumerState<CoffeeScreen> {
  final _picker = ImagePicker();
  _InputMode _mode = _InputMode.none;
  final List<String?> _photos = [null, null, null];
  String? _fincanImage;
  bool _kontrolEdiliyor = false;
  bool _sending = false;

  // ── Fal konusu ──────────────────────────────────────────────────────────
  String? _falKonusu;   // null = henüz seçilmedi (konu ekranı gösterilir)

  static const _fincanImages = [
    'assets/images/kahve/Fincan1.png',
    'assets/images/kahve/Fincan3.png',
    'assets/images/kahve/Fincan5.png',
  ];

  // Foto Çek / Dosyadan: 3'ü de dolu olunca aktif
  bool get _canSend {
    if (_mode == _InputMode.yerimeIc) return true;
    if (_mode == _InputMode.fotoCek || _mode == _InputMode.dosyadan) {
      return _photos.every((p) => p != null);
    }
    return false;
  }

  int get _filledCount => _photos.where((p) => p != null).length;

  void _selectMode(_InputMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _photos.fillRange(0, 3, null);
      _fincanImage = mode == _InputMode.yerimeIc
          ? _fincanImages[Random().nextInt(_fincanImages.length)]
          : null;
    });
  }

  Future<void> _pickPhoto(int index) async {
    final source = _mode == _InputMode.fotoCek
        ? ImageSource.camera
        : ImageSource.gallery;
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    setState(() => _photos[index] = image.path);
  }

  Future<void> _sendFortune() async {
    if (!_canSend || _kontrolEdiliyor) return;

    // Fal üretimini hemen arka planda başlat
    final fortuneService = ref.read(fortuneServiceProvider);
    final profile = ref.read(userProfileProvider);
    final inboxNotifier = ref.read(inboxProvider.notifier);

    fortuneService.generateCoffeeFortune(
      profile: profile,
      photoPath1: _photos[0],
      photoPath2: _photos[1],
      photoPath3: _photos[2],
      falKonusu: _falKonusu ?? 'genel',
    ).then((item) => inboxNotifier.addItem(item)).catchError((_) {});

    // 4 saniye fincanın altında kum saati göster
    if (!mounted) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;
    ref.read(kahveSentProvider.notifier).state = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            // ── Konu seçilmemişse konu ekranını göster ──────────────────
            if (_falKonusu == null) ...[
              Expanded(child: _buildKonuSecim()),
            ] else ...[
            Expanded(
              child: _mode == _InputMode.none
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSubtitle(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildOptionRow(context),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          _buildSubtitle(),
                          const SizedBox(height: 24),
                          _buildOptionRow(context),
                          if (_mode == _InputMode.fotoCek ||
                              _mode == _InputMode.dosyadan) ...[
                            const SizedBox(height: 28),
                            _buildPhotoSlots(),
                            if (_sending) ...[
                              const SizedBox(height: 28),
                              _buildSendingIndicator(),
                            ],
                          ] else if (_mode == _InputMode.yerimeIc &&
                              _fincanImage != null) ...[
                            const SizedBox(height: 28),
                            _buildFincanImage(),
                            if (_sending) ...[
                              const SizedBox(height: 28),
                              _buildSendingIndicator(),
                            ],
                          ],
                        ],
                      ),
                    ),
            ),
            if (_falKonusu != null) _buildSendButton(),
            ], // end else
          ],
        ),
      ),
    );
  }

  // ── Konu seçim ekranı (2x2 grid) ────────────────────────────────────────
  Widget _buildKonuSecim() {
    const konular = [
      ('genel',   '🔮', 'Genel'),
      ('ask',     '❤️', 'Aşk'),
      ('kariyer', '💼', 'Kariyer'),
      ('saglik',  '🌿', 'Sağlık'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Fal konusu ne olsun?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            physics: const NeverScrollableScrollPhysics(),
            children: konular.map((k) {
              final (key, emoji, label) = k;
              return GestureDetector(
                onTap: () => setState(() => _falKonusu = key),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A0A2E), Color(0xFF2D1255)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF9B3FCC),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'KAHVE FALI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Fincan görsellerini nasıl iletmek istersin?',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white54, fontSize: 14),
    );
  }

  Widget _buildOptionRow(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Her buton ekranın ~%28'i genişliğinde, yüksekliği de aynı
    final btnSize = (screenW - 40 - 24) / 3; // 40=padding, 24=2 boşluk
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _OptionButton(
          imageAsset: 'assets/images/camera.png',
          label: 'Foto Çek',
          size: btnSize,
          selected: _mode == _InputMode.fotoCek,
          onTap: () => _selectMode(_InputMode.fotoCek),
        ),
        _OptionButton(
          imageAsset: 'assets/images/file.png',
          label: 'Dosyadan',
          size: btnSize,
          selected: _mode == _InputMode.dosyadan,
          onTap: () => _selectMode(_InputMode.dosyadan),
        ),
        _OptionButton(
          imageAsset: 'assets/images/ozelfal.png',
          label: 'Yerime İç',
          size: btnSize,
          selected: _mode == _InputMode.yerimeIc,
          onTap: () => _selectMode(_InputMode.yerimeIc),
        ),
      ],
    );
  }

  // ── 3 fotoğraf yuvası — yan yana kareler, sadece numara ──────────────────────
  Widget _buildPhotoSlots() {
    return Row(
      children: List.generate(3, (i) {
        final photo = _photos[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () => _pickPhoto(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: photo != null
                        ? Colors.transparent
                        : const Color(0xFF13122A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: photo != null
                          ? AppColors.glowGreen.withValues(alpha: 0.8)
                          : Colors.white24,
                      width: photo != null ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photo != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(photo), fit: BoxFit.cover),
                            // Numara rozeti
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.glowGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFincanImage() {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(_fincanImage!, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingHourglass(),
        SizedBox(height: 12),
        Text(
          'Falın gönderiliyor...',
          style: TextStyle(
            color: Color(0xFFB8E0FF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _mode == _InputMode.none
            ? _buildGeriGitButton()
            : _buildFalGonderButton(),
      ),
    );
  }

  Widget _buildGeriGitButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text(
                'Geri Git',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFalGonderButton() {
    final isPhotoMode = _mode == _InputMode.fotoCek ||
        _mode == _InputMode.dosyadan;
    final String label;
    if (_kontrolEdiliyor) {
      label = 'Kontrol ediliyor...';
    } else if (_canSend) {
      label = 'Falımı Gönder ✨';
    } else if (isPhotoMode) {
      label = '$_filledCount/3 Fotoğraf';
    } else {
      label = 'Falımı Gönder ✨';
    }
    final bool active = _canSend && !_kontrolEdiliyor;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: active ? _sendFortune : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF6B3FA0), Color(0xFF9C6FD6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.white12,
            borderRadius: BorderRadius.circular(27),
            boxShadow: _canSend
                ? [
                    BoxShadow(
                      color: const Color(0xFF7B4FBF).withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gönderiliyor overlay — 4 saniyelik kum saati ─────────────────────────────
class _SendingOverlay extends StatefulWidget {
  const _SendingOverlay();

  @override
  State<_SendingOverlay> createState() => _SendingOverlayState();
}

class _SendingOverlayState extends State<_SendingOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingHourglass(),
          SizedBox(height: 16),
          Text(
            'Falın gönderiliyor...',
            style: TextStyle(
              color: Color(0xFFB8E0FF),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kum saati animasyonu (tarot ekranındakiyle aynı) ──────────────────────────
class _PulsingHourglass extends StatefulWidget {
  const _PulsingHourglass();

  @override
  State<_PulsingHourglass> createState() => _PulsingHourglassState();
}

class _PulsingHourglassState extends State<_PulsingHourglass> {
  @override
  Widget build(BuildContext context) {
    return const PulsingHourglass(size: 48, color: Color(0xFFB8E0FF));
  }
}

// ── Yöntem seçim butonu ───────────────────────────────────────────────────────
// Görsel çerçeveyi kenarlarına kadar doldurur; etiket altta gradient overlay içinde.
class _OptionButton extends StatelessWidget {
  final String imageAsset;
  final String label;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.imageAsset,
    required this.label,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF9C6FD6) : Colors.white24,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B4FBF).withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Görsel — çerçeveyi tam doldurur
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF13122A),
                child: Icon(Icons.image_not_supported,
                    color: Colors.white38, size: 40),
              ),
            ),
            // Seçili olunca hafif mor tint
            if (selected)
              Container(
                color: const Color(0xFF6B3FA0).withValues(alpha: 0.25),
              ),
            // Etiket: alta yapışık, gradient arka plan
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.82),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
