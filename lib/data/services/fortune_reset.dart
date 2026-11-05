// "Tüm Falları Sil" (Ayarlar) → yeni fal türleri de hiç alınmamış gibi sıfırlanır
// (Anıl, 2026-11-05). Gelen kutusu ayrıca silinir; burası cihazdaki fal KAYITLARI.
//
// Yeni bir kalıcı fal türü eklenirse anahtarını buraya da ekle (test: fortune_reset_test).
import 'package:shared_preferences/shared_preferences.dart';

import 'araba_engine.dart';
import 'dream_interpreter.dart';
import 'ev_engine.dart';
import 'kismet_engine.dart';

class FortuneReset {
  FortuneReset._();

  /// Sıfırlanan anahtarlar. Rüya yapay zekâ İZNİ (`ruya_ai_onay`) bir fal değil,
  /// gizlilik tercihidir → korunur.
  static const keys = <String>[
    // Tavşan Falı: bugünün kağıdı + tekrar göstermeme listesi
    'tavsanfali_bugun_tarih',
    'tavsanfali_bugun_id',
    'tavsanfali_gosterilen',
    // Kısmetim Kim? / Arabam Ne? / Evim Neresi?: kalıcı kader çizelgeleri + açılan kutular
    KismetEngine.prefsKey,
    ArabaEngine.prefsKey,
    EvimEngine.prefsKey,
    EvimEngine.prefsIlKey,
    EvimEngine.prefsAskedKey,
    // Rüya serbest yorumu: günlük yapay zekâ hakkı
    'ruya_ai_tarih',
  ];

  static Future<void> resetNewFortunes(SharedPreferences prefs) async {
    for (final k in keys) {
      await prefs.remove(k);
    }
    DreamInterpreter.clearCache();
  }
}
