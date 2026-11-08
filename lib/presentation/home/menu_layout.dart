// lib/presentation/home/menu_layout.dart
//
// Ana menü düzeni — TEK düzen (Anıl, 2026-11-08: "tek bir tane olacak", "her seferinde bu
// set up'la çıksın, randomu kaldırdık"). Eski üç düzen (1/3 ihtimalle grid / büyük bloklar /
// favoriler) KALDIRILDI.
//   "Favoriler"    : 3×2 — en çok açılan 6 tür, çoktan aza (kullanım yoksa varsayılan sıra).
//   "Diğer Türler" : 27 türün TAMAMI (favoriler de; aşağıdan çıkarılmaz), büyük ikonlu dizilim:
//                    büyük · 3×4 · büyük · 3×4 · büyük. Büyük ikon 3×3 hücre kadar (en-boy ≈
//                    küçük kartla aynı: 0.758 / 0.750). Büyükler açılışta seçilir; bir önceki
//                    açılıştakiler mümkünse tekrar gelmez. 3 büyük + 24 küçük = 27.
// Sıralama ve büyükler açılışta bir kez hesaplanır, oturum boyunca DEĞİŞMEZ (gezinirken menü
// zıplamaz). Kullanım sayımı: menü kartına her dokunuş (SharedPreferences 'menu_kullanim').

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [standard] = uygulamanın tek düzeni. [grid] (düz 3×9) yalnız görsel test düzenekleri için:
/// kart konumları sabit kalsın diye (build/visual_check). Üretimde seçilmez.
enum MenuLayout { standard, grid }

/// Yalnız test/görsel doğrulama: düzeni sabitle.
@visibleForTesting
MenuLayout? debugMenuLayout;

/// Menü düzeni: her zaman [MenuLayout.standard] (test dışında).
MenuLayout get sessionMenuLayout => debugMenuLayout ?? MenuLayout.standard;

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

/// Yüksek çözünürlüklü menü görselleri (Anıl, 2026-11-06: "hepsini yeniden ürettir, birebir"):
/// kaynağı 768 px'ten küçük 19 görsel ChatGPT'de 1024 px'e büyütüldü + keskinleştirildi
/// (yeniden çizim DEĞİL: kompozisyon/renk birebir; yapı 1.00, renk farkı <1). Her biri
/// orijinaliyle sayısal denetlendi (build/visual_check/menu_hd). JPEG 90, toplam ~4 MB.
/// Yalnız BÜYÜK kartta kullanılır (küçük kartta orijinal yeter; 27 kart × 1024² çözme
/// belleği boşa gitmesin). Burada adı olan görsel büyük ikon olabilir.
const Set<String> kMenuHdNames = {
  'acigercekler', 'aytakvimi', 'biyoritim', 'dertortagi', 'durugoru', 'elfali',
  'ichingikon', 'japonfali', 'kadercarkimenu', 'kehanet', 'motivasyon_yeni', 'numeroloji',
  'olumlama', 'ozelfal', 'ozlusozler', 'ruyaozel', 'tarot', 'tefeulyeni', 'yuzfali',
};

String _base(String path) {
  final f = path.split('/').last;
  final dot = f.lastIndexOf('.');
  return dot < 0 ? f : f.substring(0, dot);
}

/// BÜYÜK menü kartında gösterilecek görsel: HD sürümü varsa o, yoksa orijinal.
String menuImageFor(String path) {
  final b = _base(path);
  return kMenuHdNames.contains(b) ? 'assets/images/menu_hd/$b.jpg' : path;
}

/// Büyük ikon olabilir mi (büyük kartta bulanıklaşmaz mı)?
bool isBigCapable(String path) =>
    kMenuHdNames.contains(_base(path)) || kBigCapableImages.contains(path);

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

/// "Diğer Türler"in 3 büyük ikonu (indeks, artan sırada). Havuz: [kBigCapableImages] ∩ [ids].
/// Bir önceki açılıştakiler, havuz yetiyorsa, tekrar seçilmez.
List<int> sessionBigPicks(List<String> ids, SharedPreferences? prefs, {Random? random}) {
  final cached = _sessionBigs;
  if (cached != null) return cached;
  final rnd = random ?? Random();
  final pool = [for (var i = 0; i < ids.length; i++) if (isBigCapable(ids[i])) i];
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
  _sessionCounts = null;
  _sessionBigs = null;
}
