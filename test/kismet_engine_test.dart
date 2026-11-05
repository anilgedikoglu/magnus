// "Kısmetim Kim?" motoru: Anıl'ın kuralları (örüntü, kadına az isim, evliyse eş) + kalıcılık.
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/models/user_profile.dart';
import 'package:magnus_app/data/services/kismet_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _p({String gender = 'erkek', String marital = 'iliskisi_yok', String birth = '2004-03-02'}) =>
    UserProfile(name: 'Deniz', age: 22, gender: gender, job: 'ogrenci', maritalStatus: marital, birthDate: birth);

void main() {
  const base = 2026;

  test('çizelge 51 yılı boşluksuz kaplar, segmentler ≥3 yıl (boşluk hariç)', () {
    for (var seed = 0; seed < 300; seed++) {
      final t = KismetEngine.generate(_p(), baseYear: base, seed: seed);
      expect(t.segments.first.start, base);
      expect(t.segments.last.end, base + 50);
      for (var i = 1; i < t.segments.length; i++) {
        expect(t.segments[i].start, t.segments[i - 1].end + 1);
      }
      for (final s in t.segments.where((s) => s.kind == KismetKind.person)) {
        expect(s.end - s.start + 1, greaterThanOrEqualTo(2)); // boşluk sonrası kalan en az 2
      }
    }
  });

  test('kadın kullanıcıya ömür boyu en fazla 2 kişi; genç erkeğe en fazla 10', () {
    for (var seed = 0; seed < 400; seed++) {
      final kadin = KismetEngine.generate(_p(gender: 'kadın'), baseYear: base, seed: seed);
      expect(kadin.people.length, lessThanOrEqualTo(2));
      expect(kadin.people.values.every((p) => !p.female), isTrue); // karşı cins: erkek ismi
      final erkek = KismetEngine.generate(_p(), baseYear: base, seed: seed);
      expect(erkek.people.length, inInclusiveRange(1, 10));
      expect(erkek.people.values.every((p) => p.female), isTrue);
    }
  });

  test('evli: ilk 5 yıl her zaman "Eşin"; çizelgelerin çoğunda ömür boyu eş', () {
    var lifelong = 0;
    for (var seed = 0; seed < 400; seed++) {
      final t = KismetEngine.generate(_p(marital: 'evli', birth: '1985-05-05'), baseYear: base, seed: seed);
      for (var y = base; y < base + 5; y++) {
        expect(t.resultFor(y).kind, KismetKind.spouse);
      }
      if (t.resultFor(base + 50).kind == KismetKind.spouse) lifelong++;
    }
    expect(lifelong / 400, inInclusiveRange(0.45, 0.65)); // ~%55
  });

  test('aynı yıl her zaman aynı sonuç; kayıt + açılan kutular kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t1 = await KismetEngine.load(prefs, _p(), nowYear: base);
    final r1 = t1.resultFor(base + 7);
    if (r1.person != null) await KismetEngine.reveal(prefs, t1, r1.person!.id, 'name');
    final t2 = await KismetEngine.load(prefs, _p(), nowYear: base + 1); // bir yıl sonra açıldı
    final r2 = t2.resultFor(base + 7);
    expect(r2.kind, r1.kind);
    expect(r2.person?.displayName, r1.person?.displayName);
    if (r1.person != null) expect(t2.isRevealed(r1.person!.id, 'name'), isTrue);
    expect(t2.lastYear, base + 1 + 50); // takvim ilerleyince sona yıl eklendi
  });

  test('medeni hal değişince yeni çizelge üretilir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await KismetEngine.load(prefs, _p(), nowYear: base);
    final evli = await KismetEngine.load(prefs, _p(marital: 'evli'), nowYear: base);
    expect(evli.resultFor(base).kind, KismetKind.spouse);
  });

  test('isim karşı cinsten, soyad tek harf; meslek yaşa göre (öğrenci/emekli)', () {
    final t = KismetEngine.generate(_p(), baseYear: base, seed: 42);
    final p = t.people.values.first;
    expect(p.displayName, matches(RegExp(r'^\S+ [A-ZÇĞİÖŞÜ]\.$')));
    expect(KismetEngine.jobForYear(p, p.birthYear + 18), 'ogrenci');
    expect(KismetEngine.jobForYear(p, p.birthYear + 70), 'emekli');
  });
}
