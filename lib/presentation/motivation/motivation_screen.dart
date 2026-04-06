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

class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({super.key});

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen>
    with SingleTickerProviderStateMixin {
  static const _uuid = Uuid();
  final _rng = Random();

  List<String> _motivasyonlar = [];
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
      duration: const Duration(milliseconds: 350),
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
    final all = List<String>.from(data['motivasyonlar'] as List);
    all.shuffle(_rng);
    setState(() {
      _motivasyonlar = all;
      _loading = false;
    });
    _animCtrl.forward();
  }

  Future<void> _next() async {
    await _animCtrl.reverse();
    setState(() {
      _index = (_index + 1) % _motivasyonlar.length;
    });
    _animCtrl.forward();
  }

  Future<void> _saveToInbox() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(userProfileProvider);
      final vars = profile.toVariableMap();
      final text = VariableReplacer.replace(_motivasyonlar[_index], vars);
      final item = InboxItem(
        id: _uuid.v4(),
        title: 'Günlük Motivasyon',
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
        title: const Text('Motivasyon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0).abs() > 80) _next();
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
    final raw = _motivasyonlar.isNotEmpty ? _motivasyonlar[_index] : '';
    final text = VariableReplacer.replace(raw, vars);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF140D46), Color(0xFF0D0A20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bubble3.first.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubble3.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💫', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardText.copyWith(
              fontSize: text.length > 300 ? 13 : (text.length > 150 ? 15 : 17),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${_index + 1} / ${_motivasyonlar.length}',
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
            Expanded(
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: AppColors.navBarActive, size: 18),
                      SizedBox(width: 8),
                      Text('Yeni Metin',
                          style: TextStyle(
                              color: AppColors.navBarActive, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _saveToInbox,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.bubble3,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet 💫',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
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
