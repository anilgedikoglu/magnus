// Fal sıfırlama — tek kaynak (2026-11-05, Anıl):
//  • Ayarlar > "Tüm Falları Sil" → ALINAN FALLAR silinir: gelen kutusu (ekranda) + yeni fal
//    türlerinin kayıtları (Tavşan, Kısmetim, Arabam, Evim) → [deleteTakenFortunes].
//    GÜNLÜK HAKLAR SIFIRLANMAZ.
//  • Yönetici paneli "Günlük Hakları Sıfırla" → tüm günlük haklar + Tavşan/Kısmetim/Arabam/Evim
//    → [resetDailyRights].
//
// ⚠️ YENİ GÜNLÜK FAL ya da KALICI FAL KAYDI EKLENİNCE ANAHTARINI BURAYA EKLE
// (test: fortune_reset_test). Ana menü rozeti `home_screen.dart` `_creditPrefKeys` ile aynı anahtarlar.
import 'package:shared_preferences/shared_preferences.dart';

import 'araba_engine.dart';
import 'dream_interpreter.dart';
import 'ev_engine.dart';
import 'kismet_engine.dart';

class FortuneReset {
  FortuneReset._();

  /// Günlük hak anahtarları ("bugün aldın" tarihi). Silinince hak geri gelir.
  static const dailyKeys = <String>[
    'motivasyon_bugun_tarih',
    'olumlama_bugun_tarih',
    'ozlusoz_bugun_tarih',
    'tarot_bugun_tarih',
    'kahve_bugun_tarih',
    'astroloji_bugun_tarih',
    'kaderkitabi_bugun_tarih',
    'dertortagi_bugun_tarih',
    'acigercekler_bugun_tarih',
    'durugoru_bugun_tarih',
    'iching_bugun_tarih',
    'japonfali_bugun_tarih',
    'kadercarki_bugun_tarih',
    'askuyumu_bugun_tarih',
    'tavsanfali_bugun_tarih',
    'elfali_bugun_tarih',
    'yuzfali_bugun_tarih',
    'ruya_ai_tarih', // eski sürümlerden kalan rüya yapay zekâ hakkı
    // Numeroloji: limit ekran içinden, bu önbelleklerle yönetilir
    'num_bugun_tarih', 'num_bugun_metin', 'num_bugun_unlock',
    'num_genel_done', 'num_genel_metin', 'num_genel_unlock',
    'num_yil_done',
  ];

  /// Yeni fal türlerinin kalıcı kayıtları (çizelgeler, açılan kutular, Tavşan kağıt geçmişi).
  static const newFortuneKeys = <String>[
    'tavsanfali_bugun_id',
    'tavsanfali_gosterilen',
    KismetEngine.prefsKey,
    ArabaEngine.prefsKey,
    EvimEngine.prefsKey,
    EvimEngine.prefsIlKey,
    EvimEngine.prefsAskedKey,
  ];

  /// "Tüm Falları Sil": alınan yeni fallar hiç alınmamış gibi; günlük haklara DOKUNMAZ.
  /// Rüya yapay zekâ izni (`ruya_ai_onay`) bir fal değil → korunur.
  static Future<void> deleteTakenFortunes(SharedPreferences prefs) async {
    for (final k in newFortuneKeys) {
      await prefs.remove(k);
    }
    DreamInterpreter.clearCache();
  }

  /// Yönetici "Günlük Hakları Sıfırla": tüm günlük haklar + Tavşan/Kısmetim/Arabam/Evim.
  static Future<void> resetDailyRights(SharedPreferences prefs) async {
    for (final k in dailyKeys) {
      await prefs.remove(k);
    }
    // Numeroloji yıllık önbelleği yıl adıyla tutulur
    final yr = DateTime.now().year.toString();
    await prefs.remove('num_yil_metin_$yr');
    await prefs.remove('num_yil_unlock_$yr');
    await deleteTakenFortunes(prefs);
  }
}
