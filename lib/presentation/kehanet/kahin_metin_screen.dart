// C:/src/magnus_app/lib/presentation/kehanet/kahin_metin_screen.dart
// Kahin metin ve video ekranı

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/occult_button.dart';
import '../../core/utils/rich_text_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class KahinMetinScreen extends ConsumerStatefulWidget {
  final String kahinId;
  const KahinMetinScreen({super.key, required this.kahinId});

  @override
  ConsumerState<KahinMetinScreen> createState() => _KahinMetinScreenState();
}

class _KahinMetinScreenState extends ConsumerState<KahinMetinScreen> {
  VideoPlayerController? _videoCtrl;
  String _metin = '';
  String _displayed = '';
  bool _loading = true;
  Timer? _typeTimer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadMetin();
    await _initVideo();
    if (mounted) {
      setState(() => _loading = false);
      _startTypewriter();
    }
  }

  Future<void> _loadMetin() async {
    final str = await rootBundle.loadString('assets/data/kahinler.json');
    final data = jsonDecode(str);
    final List list = data['kahinler'][widget.kahinId] ?? [];
    if (list.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'kahinler_${widget.kahinId}_gosterilen';
    var shown = prefs.getStringList(key) ?? [];

    var eligible = list
        .where((e) => !shown.contains(e['id'].toString()))
        .toList();
    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = List.from(list);
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    final isEn = ref.read(localeProvider) == 'en';
    _metin = (isEn && (selected['metin_en'] as String?)?.isNotEmpty == true)
        ? selected['metin_en']
        : (selected['metin'] ?? '');
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());

    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);
  }

  Future<void> _initVideo() async {
    final videoPath =
        'assets/videos/kahinler/${widget.kahinId}v.mp4';
    try {
      _videoCtrl = VideoPlayerController.asset(videoPath);
      await _videoCtrl!.initialize();
      _videoCtrl!.setLooping(true);
      _videoCtrl!.play();
    } catch (e) {
      _videoCtrl = null;
    }
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (_charIndex >= _metin.length) {
        t.cancel();
        return;
      }
      setState(() {
        _displayed = _metin.substring(0, ++_charIndex);
      });
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: GrimoireBackdrop(child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        )),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: GrimoireBackdrop(child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoCtrl!.value.aspectRatio,
                child: VideoPlayer(_videoCtrl!),
              )
            else
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.inkRaised, AppColors.ink],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold,
                    size: 60,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: GlassPanel(variant: GlassVariant.reading, padding: const EdgeInsets.all(18), child: RichTextParser.build(_displayed, style: AppTextStyles.reading)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: OccultButton(label: ref.read(l10nProvider).ok, onTap: () => context.pop()),
            ),
          ],
        ),
      )),
    );
  }
}
