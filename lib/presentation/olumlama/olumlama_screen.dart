import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';

class OlumlamaScreen extends ConsumerStatefulWidget {
  const OlumlamaScreen({super.key});

  @override
  ConsumerState<OlumlamaScreen> createState() => _OlumlamaScreenState();
}

class _OlumlamaScreenState extends ConsumerState<OlumlamaScreen>
    with SingleTickerProviderStateMixin {
  static const _uuid = Uuid();
  final _rng = Random();

  Map<String, List<String>> _allTexts = {};
  List<String> _current = [];
  int _index = 0;
  bool _loading = true;
  bool _saving = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final json = await rootBundle.loadString('assets/data/ozlusoz_motivasyon.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rawMap = data['olumlamalar'] as Map<String, dynamic>;
    final Map<String, List<String>> parsed = {};
    for (final e in rawMap.entries) {
      parsed[e.key] = List<String>.from(e.value as List);
    }
    setState(() {
      _allTexts = parsed;
      _loading = false;
    });
    _selectTextsForProfile();
    _animCtrl.forward();
  }

  void _selectTextsForProfile() {
    final profile = ref.read(userProfileProvider);
    List<String> texts = [];

    // Pick texts matching profile
    final gender = profile.gender;
    final marital = profile.maritalStatus;
    final job = profile.job;

    if (gender == 'kadin') {
      if (marital == 'evli') {
        texts.addAll(_allTexts['kadin'] ?? []);
      } else if (marital == 'iliskisi_var') {
        texts.addAll(_allTexts['kadin'] ?? []);
        texts.addAll(_allTexts['iliskisivar'] ?? []);
      } else {
        texts.addAll(_allTexts['kadin'] ?? []);
        texts.addAll(_allTexts['iliskisiyok'] ?? []);
      }
    } else if (gender == 'erkek') {
      texts.addAll(_allTexts['erkek'] ?? []);
    }

    if (marital == 'evli') texts.addAll(_allTexts['evli'] ?? []);
    if (job == 'ogrenci') texts.addAll(_allTexts['ogrenci'] ?? []);
    texts.addAll(_allTexts['genel'] ?? []);

    if (texts.isEmpty) texts = _allTexts['genel'] ?? [];
    texts.shuffle(_rng);
    setState(() {
      _current = texts;
      _index = 0;
    });
  }

  Future<void> _next({bool forward = true}) async {
    await _animCtrl.reverse();
    setState(() {
      _index = (_index + (forward ? 1 : -1)) % _current.length;
      if (_index < 0) _index = _current.length - 1;
    });
    _animCtrl.forward();
  }

  Future<void> _saveToInbox() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(userProfileProvider);
      final vars = profile.toVariableMap();
      final text = VariableReplacer.replace(_current[_index], vars);
      final item = InboxItem(
        id: _uuid.v4(),
        title: 'Günlük Olumlama',
        text: text,
        date: DateTime.now().toIso8601String(),
        fortuneTypeKey: 'motivation',
      );
      await ref.read(inboxProvider.notifier).addItem(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gelen kutusuna kaydedildi'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: const Text('Olumlamalar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -100) _next(forward: true);
                if ((d.primaryVelocity ?? 0) > 100) _next(forward: false);
              },
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildCard(profile),
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(profile) {
    final vars = profile.toVariableMap();
    final raw = _current.isNotEmpty ? _current[_index] : '';
    final text = VariableReplacer.replace(raw, vars);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/olumlama_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F5E), Color(0xFF0D0A20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bubbleFrame1.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubble1.first.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardText.copyWith(
              fontSize: text.length > 180 ? 14 : 16,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${_index + 1} / ${_current.length}',
            style: AppTextStyles.inboxMeta,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavBtn(icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => _next(forward: false)),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _saveToInbox,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.bubble1,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet ✦',
                            style: TextStyle(
                                color: Colors.white, fontSize: 15,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _NavBtn(icon: Icons.arrow_forward_ios_rounded,
                onTap: () => _next(forward: true)),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 50,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.navBarActive, size: 20),
      ),
    );
  }
}
