// "Tüm Falları Sil": yeni fal türleri hiç alınmamış gibi; rüya yapay zekâ izni korunur.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/araba_engine.dart';
import 'package:magnus_app/data/services/fortune_reset.dart';
import 'package:magnus_app/data/services/kismet_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tüm yeni fal kayıtları silinir, izin kalır; sonra yeni çizelge üretilir', () async {
    SharedPreferences.setMockInitialValues({
      'tavsanfali_bugun_tarih': '2026-11-05',
      'tavsanfali_bugun_id': 7,
      'tavsanfali_gosterilen': ['7', '9'],
      'evim_v1': '{}',
      'evim_il': 'İzmir',
      'evim_il_asked': true,
      'ruya_ai_tarih': '2026-11-05',
      'ruya_ai_onay': true,
      'baska_bir_ayar': 'kalsin',
    });
    final prefs = await SharedPreferences.getInstance();
    final p = UserProfile(
        name: 'Deniz', age: 30, gender: 'erkek', job: 'ozelsektor', maritalStatus: 'bekar', birthDate: '1996-01-01');
    final k1 = await KismetEngine.load(prefs, p, nowYear: 2026);
    final pool = ArabaEngine.parsePool(File('assets/data/arabam.json').readAsStringSync());
    final a1 = await ArabaEngine.load(prefs, p, pool, nowYear: 2026, seed: 1);
    expect(prefs.getString(KismetEngine.prefsKey), isNotNull);
    expect(prefs.getString(ArabaEngine.prefsKey), isNotNull);

    await FortuneReset.resetNewFortunes(prefs);

    for (final k in FortuneReset.keys) {
      expect(prefs.containsKey(k), isFalse, reason: k);
    }
    expect(prefs.getBool('ruya_ai_onay'), isTrue); // gizlilik tercihi korunur
    expect(prefs.getString('baska_bir_ayar'), 'kalsin');

    // Yeniden açılınca yeni (farklı tohumlu) çizelgeler üretilir, açılmış kutu yok.
    final a2 = await ArabaEngine.load(prefs, p, pool, nowYear: 2026, seed: 2);
    expect(a2.seed, isNot(a1.seed));
    expect(a2.revealed, isEmpty);
    final k2 = await KismetEngine.load(prefs, p, nowYear: 2026);
    expect(identical(k1, k2), isFalse);
  });
}
