// C:/src/magnus_app/lib/presentation/kehanet/yana_screen.dart
// Yana kehanet ekranı - Bana Dair / Yaşama Dair seçimi

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

class YanaScreen extends ConsumerStatefulWidget {
  const YanaScreen({super.key});

  @override
  ConsumerState<YanaScreen> createState() => _YanaScreenState();
}

enum _YanaAdim { secim, yukleniyor, icerik }

class _YanaScreenState extends ConsumerState<YanaScreen>
    with SingleTickerProviderStateMixin {
  _YanaAdim _adim = _YanaAdim.secim;
  String _metin = '';
  String _displayed = '';
  Timer? _typeTimer;
  int _charIndex = 0;
  late AnimationController _hourglassCtrl;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _hourglassCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  void _startHourglass() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _flipped = !_flipped);
      _hourglassCtrl.forward(from: 0);
      _startHourglass();
    });
  }

  Future<void> _onSecim(String tur) async {
    setState(() {
      _adim = _YanaAdim.yukleniyor;
    });
    _startHourglass();

    final str = await rootBundle.loadString('assets/data/yana.json');
    final data = jsonDecode(str);
    final List all = data['yana'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    final key = 'yana_${tur}_gosterilen';
    var shown = prefs.getStringList(key) ?? [];

    var eligible = all
        .where((e) =>
            e['tur'] == tur &&
            (e['kosullar'] as List? ?? []).isEmpty &&
            !shown.contains(e['id'].toString()))
        .toList();

    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = all
          .where((e) =>
              e['tur'] == tur &&
              (e['kosullar'] as List? ?? []).isEmpty)
          .toList();
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    _metin = selected['metin'] ?? '';
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (mounted) {
      setState(() => _adim = _YanaAdim.icerik);
      _startTypewriter();
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
    _hourglassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (_adim == _YanaAdim.icerik ||
                          _adim == _YanaAdim.yukleniyor) {
                        _typeTimer?.cancel();
                        setState(() {
                          _adim = _YanaAdim.secim;
                          _displayed = '';
                          _charIndex = 0;
                        });
                      } else {
                        context.pop();
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'YANA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_adim == _YanaAdim.secim) ...[
              const Spacer(),
              const Text('✨', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Ne hakkında kehanet istersin?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _secimBtn(context, 'Bana Dair', 'bana'),
                    const SizedBox(height: 16),
                    _secimBtn(context, 'Yaşama Dair', 'yasama'),
                  ],
                ),
              ),
              const Spacer(),
            ] else if (_adim == _YanaAdim.yukleniyor) ...[
              const Spacer(),
              AnimatedRotation(
                turns: _flipped ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 700),
                child: const Text('⏳', style: TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Yana bakıyor...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const Spacer(),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _displayed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Kapat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _secimBtn(BuildContext context, String label, String tur) {
    return GestureDetector(
      onTap: () => _onSecim(tur),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF9B00D3), Color(0xFFFF55FF)],
          ),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
