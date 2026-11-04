// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\JaponFali\Metinler
// JSON:   assets/data/japonfali.json
// Arka plan: assets/images/falbg/omikujibg.png
//
// Akış:
//   1. Ekran açılır → "Japon Falı çalışılıyor..." + kum saati (5s)
//   2. Metin no-repeat ile seçilir, inbox'a eklenir (unlockAt = +2 dakika)
//   3. japonFaliSentProvider = true → ana menüye dön

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../data/providers.dart';
import '../../data/models/inbox_item.dart';

class JaponFaliScreen extends ConsumerStatefulWidget {
  const JaponFaliScreen({super.key});

  @override
  ConsumerState<JaponFaliScreen> createState() => _JaponFaliScreenState();
}

class _JaponFaliScreenState extends ConsumerState<JaponFaliScreen> {

  static const _prefKeyGosterilen = 'japonfali_gosterilen';

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // 5 saniye bekle
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    await _generateAndSave();
    if (!mounted) return;

    setState(() => _done = true);
    ref.read(japonFaliSentProvider.notifier).state = true;
    context.go('/home');
  }

  Future<void> _generateAndSave() async {
    final prefs   = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider);
    final vars    = profile.toVariableMap();

    final raw  = await rootBundle.loadString('assets/data/japonfali.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final tumListe = (data['japonfali'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Koşul filtresi
    final uygunlar = tumListe.where((e) {
      final kosullar = (e['kosullar'] as List?) ?? [];
      if (kosullar.isEmpty) return true;
      for (final k in kosullar) {
        final deg = (k as Map)['degisken'] as String;
        final bek = k['deger'] as String;
        final grc = vars[deg] ?? '';
        if (grc != bek) return false;
      }
      return true;
    }).toList();

    if (uygunlar.isEmpty) return;

    // No-repeat seçim
    List<String> gosterilen = prefs.getStringList(_prefKeyGosterilen) ?? [];
    var kalan = uygunlar.where((e) => !gosterilen.contains('${e['id']}')).toList();

    if (kalan.isEmpty) {
      final lastId = gosterilen.isNotEmpty ? gosterilen.last : null;
      gosterilen = lastId != null ? [lastId] : [];
      await prefs.setStringList(_prefKeyGosterilen, gosterilen);
      kalan = uygunlar.where((e) => '${e['id']}' != lastId).toList();
      if (kalan.isEmpty) kalan = List.from(uygunlar);
    }

    kalan.shuffle(Random());
    final secilen = kalan.first;
    gosterilen.add('${secilen['id']}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilen);

    final isEn = ref.read(localeProvider) == 'en';
    final secilenMetin = (isEn && (secilen['metin_en'] as String?)?.isNotEmpty == true)
        ? secilen['metin_en'] as String
        : secilen['metin'] as String;
    final metin = VariableReplacer.replace(secilenMetin, vars);

    // 2 dakika sonra açılır
    final now      = DateTime.now();
    final unlockAt = now.add(const Duration(minutes: 2)).toIso8601String();

    final item = InboxItem(
      id:             const Uuid().v4(),
      title:          'Japon Falın Hazır',
      text:           metin,
      date:           now.toIso8601String(),
      fortuneTypeKey: 'japonfali',
      iconAsset:      'assets/images/inbox_icons/japonfali.png',
      unlockAt:       unlockAt,
    );
    ref.read(inboxProvider.notifier).addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      extendBody: true,
      body: GrimoireBackdrop(
        asset: 'assets/images/falbg/omikujibg.png',
        child: SafeArea(
          child: Column(
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _done ? null : () => context.pop(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.bone.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.rim, width: 0.8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(ref.watch(l10nProvider).japonFaliTitle, style: AppTextStyles.screenTitle),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              const Spacer(),
              // Kum saati + yazı
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ElegantHourglass(size: 52, color: AppColors.gold),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GlassPanel(
                      variant: GlassVariant.bubble,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            ref.watch(l10nProvider).japonFaliWorking,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardLabel.copyWith(fontSize: 14.5),
                          ),
                          const SizedBox(height: 12),
                          Container(width: 28, height: 1, color: AppColors.blood),
                          const SizedBox(height: 16),
                          _DotsIndicator(color: AppColors.gold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Sıralı nokta animasyonu
class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator> {
  int _step = 0;
  late final _timer = Stream.periodic(const Duration(milliseconds: 500))
      .listen((_) { if (mounted) setState(() => _step = (_step + 1) % 4); });

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i < _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? widget.color
                : widget.color.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
