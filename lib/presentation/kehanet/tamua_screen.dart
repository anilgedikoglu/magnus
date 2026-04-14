// C:/src/magnus_app/lib/presentation/kehanet/tamua_screen.dart
// Tamua sohbet ekranı

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

class TamuaScreen extends ConsumerStatefulWidget {
  const TamuaScreen({super.key});

  @override
  ConsumerState<TamuaScreen> createState() => _TamuaScreenState();
}

enum _TamuaAdim { yukleniyor, icerik }

class _TamuaScreenState extends ConsumerState<TamuaScreen>
    with SingleTickerProviderStateMixin {
  _TamuaAdim _adim = _TamuaAdim.yukleniyor;
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
    _startHourglass();
    _loadData();
  }

  void _startHourglass() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _flipped = !_flipped);
      _hourglassCtrl.forward(from: 0);
      _startHourglass();
    });
  }

  Future<void> _loadData() async {
    final str = await rootBundle.loadString('assets/data/tamua.json');
    final data = jsonDecode(str);
    final List all = data['tamua'] ?? [];

    final prefs = await SharedPreferences.getInstance();
    const key = 'tamua_gosterilen';
    var shown = prefs.getStringList(key) ?? [];

    var eligible =
        all.where((e) => !shown.contains(e['id'].toString())).toList();
    if (eligible.isEmpty) {
      await prefs.remove(key);
      shown = [];
      eligible = List.from(all);
    }

    eligible.shuffle(Random());
    final selected = eligible.first;
    _metin = selected['metin'] ?? '';
    final profile = ref.read(userProfileProvider);
    _metin = VariableReplacer.replace(_metin, profile.toVariableMap());
    shown.add(selected['id'].toString());
    await prefs.setStringList(key, shown);

    if (mounted) {
      setState(() => _adim = _TamuaAdim.icerik);
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'TAMUA',
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
            if (_adim == _TamuaAdim.yukleniyor) ...[
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
                  'Tamua sohbet hazırlıyor...',
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
}
