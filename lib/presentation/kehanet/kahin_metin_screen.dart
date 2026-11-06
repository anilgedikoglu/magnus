// C:/src/magnus_app/lib/presentation/kehanet/kahin_metin_screen.dart
// Kahin metin ve video ekranı

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/utils/no_repeat_picker.dart';
import '../../core/widgets/floating_bar_spacer.dart';
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
    final shown = prefs.getStringList(key) ?? [];

    final pick =
        pickNoRepeat(pool: list, shown: shown, idOf: (e) => e['id'].toString());
    if (pick == null) return;
    final selected = pick.selected;
    await prefs.setStringList(key, pick.shown);

    final isEn = ref.read(localeProvider) == 'en';
    _metin = (isEn && (selected['metin_en'] as String?)?.isNotEmpty == true)
        ? selected['metin_en']
        : (selected['metin'] ?? '');
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
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
        backgroundColor: Color(0xFF0A0718),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF55FF)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
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
                    colors: [Color(0xFF1A0A30), Color(0xFF0A0718)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFF55FF),
                    size: 60,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _displayed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            // Tamam butonu kaldırıldı (Anıl, 2026-11-06; kenardan kaydırarak geri dönülür).
            const SizedBox(height: 12),
            const FloatingBarSpacer(),
          ],
        ),
      ),
    );
  }
}
