// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\JaponFali\Metinler
// JSON:   assets/data/japonfali.json
//
// Akış (2026-11-07, Anıl):
//   Araya giren omikuji-kutusu görsel ekranı/animasyonu KALDIRILDI. Japon Falı istenince
//   diğer hızlı fallar (I-Ching) gibi DOĞRUDAN gelen kutusuna "hazırlanıyor" (kilitli,
//   unlockAt = +2 dakika) olarak düşer ve ana menüye dönülür. Ara ekran yoktur; ekran yalnız
//   bir kare, görselsiz (sade zemin) görünür. "Hazırlanıyor" balonunu ana menü gösterir.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';
import '../../data/models/inbox_item.dart';

class JaponFaliScreen extends ConsumerStatefulWidget {
  const JaponFaliScreen({super.key});

  @override
  ConsumerState<JaponFaliScreen> createState() => _JaponFaliScreenState();
}

class _JaponFaliScreenState extends ConsumerState<JaponFaliScreen> {

  static const _prefKeyGosterilen = 'japonfali_gosterilen';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _generateAndSave();
    if (!mounted) return;

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
        final deg = '${(k as Map)['degisken'] ?? ''}';
        final bek = '${k['deger'] ?? ''}';
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
    // Ara ekran yok: fal gelen kutusuna düşene kadar yalnız sade bir kare görünür.
    return const Scaffold(backgroundColor: Colors.black);
  }
}
