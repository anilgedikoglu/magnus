// Fal sıfırlama (Anıl, 2026-11-05):
//  • "Tüm Falları Sil" → alınan yeni fallar silinir, GÜNLÜK HAKLAR KALIR.
//  • Yönetici "Günlük Hakları Sıfırla" → tüm günlük haklar + Tavşan/Kısmetim/Arabam/Evim.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/araba_engine.dart';
import 'package:magnus_app/data/services/fortune_reset.dart';
import 'package:magnus_app/data/services/kismet_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seed = <String, Object>{
  'tavsanfali_bugun_tarih': '2026-11-05',
  'tavsanfali_bugun_id': 7,
  'tavsanfali_gosterilen': ['7', '9'],
  'evim_v1': '{}',
  'evim_il': 'İzmir',
  'evim_il_asked': true,
  'ruya_ai_onay': true,
  'kahve_bugun_tarih': '2026-11-05',
  'japonfali_bugun_tarih': '2026-11-05',
  'num_bugun_tarih': '2026-11-05',
  'baska_bir_ayar': 'kalsin',
};

final _p = UserProfile(
    name: 'Deniz', age: 30, gender: 'erkek', job: 'ozelsektor', maritalStatus: 'bekar', birthDate: '1996-01-01');

void main() {
  test('Tüm Falları Sil: yeni fal kayıtları silinir, günlük haklar KALIR; sonra yeni çizelge', () async {
    SharedPreferences.setMockInitialValues(Map.of(_seed));
    final prefs = await SharedPreferences.getInstance();
    await KismetEngine.load(prefs, _p, nowYear: 2026);
    final pool = ArabaEngine.parsePool(File('assets/data/arabam.json').readAsStringSync());
    final a1 = await ArabaEngine.load(prefs, _p, pool, nowYear: 2026, seed: 1);
    expect(prefs.getString(KismetEngine.prefsKey), isNotNull);

    await FortuneReset.deleteTakenFortunes(prefs);

    for (final k in FortuneReset.newFortuneKeys) {
      expect(prefs.containsKey(k), isFalse, reason: k);
    }
    // Günlük haklar dokunulmadı
    expect(prefs.getString('tavsanfali_bugun_tarih'), '2026-11-05');
    expect(prefs.getString('kahve_bugun_tarih'), '2026-11-05');
    expect(prefs.getString('num_bugun_tarih'), '2026-11-05');
    expect(prefs.getBool('ruya_ai_onay'), isTrue);
    expect(prefs.getString('baska_bir_ayar'), 'kalsin');

    final a2 = await ArabaEngine.load(prefs, _p, pool, nowYear: 2026, seed: 2);
    expect(a2.seed, isNot(a1.seed));
    expect(a2.revealed, isEmpty);
  });

  test('Günlük Hakları Sıfırla: tüm günlük haklar + Tavşan/Kısmetim/Arabam/Evim sıfırlanır', () async {
    SharedPreferences.setMockInitialValues(Map.of(_seed));
    final prefs = await SharedPreferences.getInstance();
    await KismetEngine.load(prefs, _p, nowYear: 2026);
    final pool = ArabaEngine.parsePool(File('assets/data/arabam.json').readAsStringSync());
    await ArabaEngine.load(prefs, _p, pool, nowYear: 2026, seed: 1);

    await FortuneReset.resetDailyRights(prefs);

    for (final k in [...FortuneReset.dailyKeys, ...FortuneReset.newFortuneKeys]) {
      expect(prefs.containsKey(k), isFalse, reason: k);
    }
    expect(prefs.getBool('ruya_ai_onay'), isTrue);
    expect(prefs.getString('baska_bir_ayar'), 'kalsin');
  });

  test('koddaki her günlük hak anahtarı Günlük Hakları Sıfırla kapsamında (ekran içi limitler dahil)', () {
    final src = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final keys = RegExp(r"'(\w+_bugun_tarih)'").allMatches(src).map((m) => m.group(1)!).toSet();
    expect(keys, isNotEmpty);
    for (final k in keys) {
      expect(FortuneReset.dailyKeys, contains(k), reason: k);
    }
  });
}
