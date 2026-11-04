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
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/widgets/occult_cards.dart';
import '../../core/widgets/filmed_image.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/swipe_back.dart';
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
  String? _falKonusu; // null = henüz seçilmedi (konu ekranı gösterilir)

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
      _fincanImage =
          mode == _InputMode.yerimeIc
              ? _fincanImages[Random().nextInt(_fincanImages.length)]
              : null;
    });
  }

  Future<void> _pickPhoto(int index) async {
    final source =
        _mode == _InputMode.fotoCek ? ImageSource.camera : ImageSource.gallery;
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

    fortuneService
        .generateCoffeeFortune(
          profile: profile,
          photoPath1: _photos[0],
          photoPath2: _photos[1],
          photoPath3: _photos[2],
          falKonusu: _falKonusu ?? 'genel',
          locale: ref.read(localeProvider),
        )
        .then((item) => inboxNotifier.addItem(item))
        .catchError((_) {});

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
    final s = ref.watch(l10nProvider);
    return SwipeBack(
      // Konu seçim ekranında soldan sağa swipe → ana menü
      onSwipeBack: () {
        if (_falKonusu == null) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: GrimoireBackdrop(child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, s),
              // ── Konu seçilmemişse konu ekranını göster ──────────────────
              if (_falKonusu == null) ...[
                Expanded(child: _buildKonuSecim(s)),
              ] else ...[
                Expanded(
                  child:
                      _mode == _InputMode.none
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSubtitle(s),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: _buildOptionRow(context, s),
                              ),
                            ],
                          )
                          : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Column(
                              children: [
                                _buildSubtitle(s),
                                const SizedBox(height: 24),
                                _buildOptionRow(context, s),
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
        )),
      ),
    );
  }

  // ── Konu seçim ekranı (2x2 grid) ────────────────────────────────────────
  // Yeni glif seti geldiğinde yalnız bu eşlemeyi değiştir.
  GlyphBuilder _konuGlyph(String konu) {
    final icon = switch (konu) {
      'ask' => Icons.favorite_border_rounded,
      'kariyer' => Icons.key_outlined,
      'saglik' => Icons.spa_outlined,
      _ => Icons.visibility_outlined,
    };
    return (c, s) => Icon(icon, color: c, size: s);
  }

  Widget _buildKonuSecim(AppStrings s) {
    final konular = [
      ('genel', s.general),
      ('ask', s.love),
      ('kariyer', s.career),
      ('saglik', s.health),
    ];
    return LayoutBuilder(
      builder:
          (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: max(0, box.maxHeight - 40),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OccultSectionLabel(s.fortuneSubject),
                  const SizedBox(height: 28),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                    physics: const NeverScrollableScrollPhysics(),
                    children:
                        konular
                            .map(
                              (k) => OccultChoiceTile(
                                label: k.$2,
                                glyph: _konuGlyph(k.$1),
                                onTap: () => setState(() => _falKonusu = k.$1),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.boneDim,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              s.coffeeTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSubtitle(AppStrings s) {
    return Center(child: OccultSectionLabel(s.howToSend));
  }

  Widget _buildOptionRow(BuildContext context, AppStrings s) {
    final screenW = MediaQuery.of(context).size.width;
    // Her buton ekranın ~%28'i genişliğinde, yüksekliği de aynı
    final btnSize = (screenW - 40 - 24) / 3; // 40=padding, 24=2 boşluk
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _OptionButton(
          imageAsset: 'assets/images/camera.png',
          label: s.takePhoto,
          size: btnSize,
          selected: _mode == _InputMode.fotoCek,
          onTap: () => _selectMode(_InputMode.fotoCek),
        ),
        _OptionButton(
          imageAsset: 'assets/images/file.png',
          label: s.fromFile,
          size: btnSize,
          selected: _mode == _InputMode.dosyadan,
          onTap: () => _selectMode(_InputMode.dosyadan),
        ),
        _OptionButton(
          imageAsset: 'assets/images/ozelfal.png',
          label: s.drinkForMe,
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
                child: GlassPanel(
                  selected: photo != null,
                  child:
                      photo != null
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
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: AppColors.bone,
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
                                color: AppColors.ash,
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
      child: SizedBox(
        width: 220,
        height: 220,
        child: GlassPanel(
          child: FilmedImage(_fincanImage!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildSendingIndicator() {
    final s = ref.read(l10nProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PulsingHourglass(),
        const SizedBox(height: 12),
        Text(
          s.sending,
          style: const TextStyle(
            color: AppColors.gold,
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
        color: AppColors.inkSurface,
        border: Border(top: BorderSide(color: AppColors.rim)),
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            _mode == _InputMode.none
                ? _buildGeriGitButton()
                : _buildFalGonderButton(),
      ),
    );
  }

  Widget _buildGeriGitButton() {
    final s = ref.read(l10nProvider);
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 2),
              Text(
                s.backButton,
                style: const TextStyle(
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
    final s = ref.read(l10nProvider);
    final isPhotoMode =
        _mode == _InputMode.fotoCek || _mode == _InputMode.dosyadan;
    final String label;
    if (_kontrolEdiliyor) {
      label = s.checkingPhotos;
    } else if (_canSend) {
      label = s.sendFortune;
    } else if (isPhotoMode) {
      label = s.photoCount(_filledCount);
    } else {
      label = s.sendFortune;
    }
    final bool active = _canSend && !_kontrolEdiliyor;

    return OccultButton(label: label, onTap: active ? _sendFortune : null);
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
    return const PulsingHourglass(size: 48, color: AppColors.gold);
  }
}

// ── Yöntem seçim butonu ───────────────────────────────────────────────────────
// Cam seçim karosu; yöntemler çizgi gliflerle gösterilir.
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
    return SizedBox(
      width: size,
      height: size,
      child: OccultChoiceTile(
        label: label,
        selected: selected,
        onTap: onTap,
        glyph:
            (c, s) => Icon(
              imageAsset.endsWith('camera.png')
                  ? Icons.camera_alt_outlined
                  : imageAsset.endsWith('file.png')
                  ? Icons.photo_library_outlined
                  : Icons.coffee_outlined,
              color: c,
              size: s,
            ),
      ),
    );
  }
}
