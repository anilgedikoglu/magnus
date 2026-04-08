import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/models/inbox_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// Kaynak: C:\Users\AG\Desktop\cleaned_tarot\OzluSozler\
// 643 söz, günlük limit: 1. Tüm sözler gösterilince liste sıfırlanır.

class _OzluSozEntry {
  final int id;
  final String metin;
  final String yazar;
  const _OzluSozEntry({required this.id, required this.metin, required this.yazar});
}

class OzluSozScreen extends ConsumerStatefulWidget {
  const OzluSozScreen({super.key});

  @override
  ConsumerState<OzluSozScreen> createState() => _OzluSozScreenState();
}

class _OzluSozScreenState extends ConsumerState<OzluSozScreen>
    with SingleTickerProviderStateMixin {
  static const _uuid = Uuid();
  static const _prefKeyGosterilen = 'ozlusoz_gosterilen_idler';
  static const _prefKeyBugunTarih = 'ozlusoz_bugun_tarih';

  final _rng = Random();

  _OzluSozEntry? _bugunEntry;
  bool _loading = true;
  bool _saving = false;
  bool _hakDoldu = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    final prefs = await SharedPreferences.getInstance();
    final bugunStr = DateTime.now().toIso8601String().substring(0, 10);

    // Bugün zaten gösterildi mi?
    final kayitliTarih = prefs.getString(_prefKeyBugunTarih);
    if (kayitliTarih == bugunStr) {
      if (!mounted) return;
      setState(() {
        _hakDoldu = true;
        _loading = false;
      });
      return;
    }

    // JSON yükle
    final jsonStr = await rootBundle.loadString('assets/data/ozlusozler.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tumListe = (data['ozlusozler'] as List<dynamic>)
        .map((e) => _OzluSozEntry(
              id: (e as Map<String, dynamic>)['id'] as int,
              metin: e['metin'] as String,
              yazar: (e['yazar'] as String?) ?? '',
            ))
        .toList();

    // Gösterilen ID'leri yükle
    List<String> gosterilenIdler = prefs.getStringList(_prefKeyGosterilen) ?? [];

    // Gösterilmeyenleri filtrele
    var kalan = tumListe.where((s) => !gosterilenIdler.contains('${s.id}')).toList();

    // Hepsi gösterildiyse sıfırla
    if (kalan.isEmpty) {
      gosterilenIdler = [];
      await prefs.setStringList(_prefKeyGosterilen, []);
      kalan = List.from(tumListe);
    }

    // Karıştır ve ilkini seç
    kalan.shuffle(_rng);
    final secilen = kalan.first;

    // Kaydet
    gosterilenIdler.add('${secilen.id}');
    await prefs.setStringList(_prefKeyGosterilen, gosterilenIdler);
    await prefs.setString(_prefKeyBugunTarih, bugunStr);

    if (!mounted) return;
    setState(() {
      _bugunEntry = secilen;
      _loading = false;
    });
    _animCtrl.forward();
  }

  Future<void> _saveToInbox() async {
    if (_bugunEntry == null) return;
    setState(() => _saving = true);
    try {
      final resolvedMetin = VariableReplacer.replace(
        _bugunEntry!.metin,
        ref.read(userProfileProvider).toVariableMap(),
      );
      final text = _bugunEntry!.yazar.isNotEmpty
          ? '"$resolvedMetin"\n— ${_bugunEntry!.yazar}'
          : '"$resolvedMetin"';
      final item = InboxItem(
        id: _uuid.v4(),
        title: 'Özlü Söz',
        text: text,
        date: DateTime.now().toIso8601String(),
        fortuneTypeKey: 'ozlusoz',
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
          : _hakDoldu
              ? _buildHakDoldu()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildContent(),
                  ),
                ),
    );
  }

  Widget _buildHakDoldu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1040), Color(0xFF0D0A20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF7B5CE8).withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📖', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Günlük özlü söz hakkın doldu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                'Yarın yeni bir söz seni bekliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final entry = _bugunEntry;
    if (entry == null) return const SizedBox.shrink();

    final resolvedMetin = VariableReplacer.replace(
      entry.metin,
      ref.read(userProfileProvider).toVariableMap(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/ozlusoz_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.18,
                onError: _imageError,
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
              mainAxisSize: MainAxisSize.min,
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
                  resolvedMetin,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardText.copyWith(
                    fontSize: resolvedMetin.length > 200 ? 14 : 16,
                  ),
                ),
                Text(
                  '❞',
                  style: TextStyle(
                    fontSize: 36,
                    color: AppColors.bubble1.first.withValues(alpha: 0.7),
                    height: 1,
                  ),
                ),
                if (entry.yazar.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: AppColors.bubble1.first.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '— ${entry.yazar}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.inboxMeta.copyWith(
                      fontSize: 12,
                      color: AppColors.bubble1.first.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Kaydet butonu
          GestureDetector(
            onTap: _saving ? null : _saveToInbox,
            child: Container(
              height: 50,
              width: double.infinity,
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
        ],
      ),
    );
  }
}

void _imageError(Object e, StackTrace? s) {}
