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

class OzluSozScreen extends ConsumerStatefulWidget {
  const OzluSozScreen({super.key});

  @override
  ConsumerState<OzluSozScreen> createState() => _OzluSozScreenState();
}

class _OzluSozScreenState extends ConsumerState<OzluSozScreen>
    with SingleTickerProviderStateMixin {
  static const _uuid = Uuid();

  List<String> _sozler = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _saving = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
    final all = List<String>.from(data['ozlu_sozler'] as List);
    all.shuffle(_rng);
    setState(() {
      _sozler = all;
      _loading = false;
    });
    _animCtrl.forward();
  }

  Future<void> _next({bool forward = true}) async {
    await _animCtrl.reverse();
    setState(() {
      _currentIndex = (_currentIndex + (forward ? 1 : -1)) % _sozler.length;
      if (_currentIndex < 0) _currentIndex = _sozler.length - 1;
    });
    _animCtrl.forward();
  }

  Future<void> _saveToInbox() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(userProfileProvider);
      final vars = profile.toVariableMap();
      final text = VariableReplacer.replace(_sozler[_currentIndex], vars);
      final item = InboxItem(
        id: _uuid.v4(),
        title: 'Özlü Söz',
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
        title: const Text('Özlü Sözler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -100) {
                  _next(forward: true);
                } else if (details.primaryVelocity! > 100) {
                  _next(forward: false);
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildCard(profile),
                        ),
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
    final rawText = _sozler.isNotEmpty ? _sozler[_currentIndex] : '';
    final text = VariableReplacer.replace(rawText, vars);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/ozlusoz_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.25,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D0A20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.bubble1.first.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubble1.first.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '❝',
            style: TextStyle(
              fontSize: 36,
              color: AppColors.bubble1.first.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardText.copyWith(
              fontSize: text.length > 200 ? 14 : 16,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '❞',
            style: TextStyle(
              fontSize: 36,
              color: AppColors.bubble1.first.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
          const SizedBox(height: 24),
          // Counter
          Text(
            '${_currentIndex + 1} / ${_sozler.length}',
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
            // Previous
            _NavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => _next(forward: false),
            ),
            const SizedBox(width: 12),
            // Save to inbox
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bubble1.first.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kaydet ✦',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Next
            _NavButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: () => _next(forward: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 50,
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
