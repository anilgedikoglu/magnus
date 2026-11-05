// lib/presentation/home/menu_layout.dart
//
// Ana menünün üç düzeni (Anıl, 2026-11-05). Açılışta her biri 1/3 ihtimalle seçilir ve o
// oturum boyunca DEĞİŞMEZ (gezinirken menü zıplamaz, sıralama her harekette yeniden
// hesaplanmaz → performans).
//   1) grid       : 3×9 (eski düzen).
//   2) bigBlocks  : büyük · 3×4 · büyük · 3×4 · büyük. Büyük ikon 3×3 hücre kadar
//                   (en-boy ≈ küçük kartla aynı: 0.758 / 0.750). Büyükler rastgele; bir önceki
//                   açılıştakiler mümkünse tekrar gelmez. 3 büyük + 24 küçük = 27 (hepsi görünür).
//   3) favorites  : "Favoriler" 3×2 (en çok açılan 6, çoktan aza) · boşluk · "Diğer Türler"
//                   3×7 (kalan 21, yine kullanım sıklığına göre).
// Kullanım sayımı: menü kartına her dokunuş (SharedPreferences 'menu_kullanim').

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MenuLayout { grid, bigBlocks, favorites }

/// Yalnız test/görsel doğrulama: düzeni sabitle.
@visibleForTesting
MenuLayout? debugMenuLayout;

MenuLayout? _sessionLayout;

/// Bu oturumun düzeni (açılışta 1/3 ihtimalle, sonra sabit).
MenuLayout get sessionMenuLayout =>
    debugMenuLayout ?? (_sessionLayout ??= MenuLayout.values[Random().nextInt(3)]);

/// Büyük ikon olabilecek görseller (büyük kartta bulanıklaşmayacak çözünürlükte olanlar).
/// Kaynak ≥ 768 px; 27 görsel yüksek çözünürlükle yeniden üretilince hepsi eklenir.
const Set<String> kBigCapableImages = {
  'assets/images/astroloji.png',
  'assets/images/menu/mistikfallar.png',
  'assets/images/askuyumu.png',
  'assets/images/dogum.png',
  'assets/images/tavsanfali/tavsanfali_menu.jpg',
  'assets/images/kismetim/kismetim_menu.jpg',
  'assets/images/arabam/arabam_menu.jpg',
  'assets/images/evim/evim_menu.jpg',
};

class MenuUsage {
  static const _key = 'menu_kullanim';

  static Map<String, int> read(SharedPreferences? prefs) {
    final raw = prefs?.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> increment(SharedPreferences? prefs, String id) async {
    if (prefs == null) return;
    final m = read(prefs);
    m[id] = (m[id] ?? 0) + 1;
    await prefs.setString(_key, jsonEncode(m));
  }
}

Map<String, int>? _sessionCounts;

/// Açılış anındaki kullanım sayıları (oturum boyu sabit).
Map<String, int> sessionUsage(SharedPreferences? prefs) =>
    _sessionCounts ??= MenuUsage.read(prefs);

/// İndeks sırası: çoktan aza; eşitlikte varsayılan sıra korunur.
List<int> orderByUsage(List<String> ids, Map<String, int> counts) {
  final idx = List<int>.generate(ids.length, (i) => i);
  idx.sort((a, b) {
    final c = (counts[ids[b]] ?? 0).compareTo(counts[ids[a]] ?? 0);
    return c != 0 ? c : a.compareTo(b);
  });
  return idx;
}

List<int>? _sessionBigs;
const _kLastBigsKey = 'menu_buyukler_son';

/// Düzen 2'nin 3 büyük ikonu (indeks, artan sırada). Havuz: [kBigCapableImages] ∩ [ids].
/// Bir önceki açılıştakiler, havuz yetiyorsa, tekrar seçilmez.
List<int> sessionBigPicks(List<String> ids, SharedPreferences? prefs, {Random? random}) {
  final cached = _sessionBigs;
  if (cached != null) return cached;
  final rnd = random ?? Random();
  final pool = [for (var i = 0; i < ids.length; i++) if (kBigCapableImages.contains(ids[i])) i];
  if (pool.length < 3) {
    pool
      ..clear()
      ..addAll(List<int>.generate(ids.length, (i) => i));
  }
  final last = (prefs?.getStringList(_kLastBigsKey) ?? const <String>[]).toSet();
  final fresh = pool.where((i) => !last.contains(ids[i])).toList();
  final source = fresh.length >= 3 ? fresh : pool;
  source.shuffle(rnd);
  final picks = source.take(3).toList()..sort();
  prefs?.setStringList(_kLastBigsKey, [for (final i in picks) ids[i]]);
  return _sessionBigs = picks;
}

/// Yalnız test: oturum önbelleklerini sıfırla.
@visibleForTesting
void debugResetMenuSession() {
  _sessionLayout = null;
  _sessionCounts = null;
  _sessionBigs = null;
}
