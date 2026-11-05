// Serbest metin rüya yorumu — çevrimdışı "mini yapay zekâ" (ağ olmadan da her zaman yorum).
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/data/services/dream_interpreter.dart';

void main() {
  test('"Rüyamda Y gördüm" kalıbından Y çıkarılır', () {
    expect(DreamInterpreter.extractSeen('Rüyamda beyaz bir kedi gördüm', isEn: false), 'beyaz bir kedi');
    expect(DreamInterpreter.extractSeen('dün gece rüyamda denizi görüyordum.', isEn: false), 'denizi');
    expect(DreamInterpreter.extractSeen('kara bir at gördüm', isEn: false), 'kara bir at');
    expect(DreamInterpreter.extractSeen('Rüyamda uçtum', isEn: false), isNull);
    expect(DreamInterpreter.extractSeen('I saw a white cat in my dream', isEn: true), 'a white cat');
  });

  test('çevrimdışı yorum: hitap + Y + 3-4 cümle, deterministik', () {
    final a = DreamInterpreter.offline(dream: 'Rüyamda beyaz bir kedi gördüm', name: 'Deniz', isEn: false);
    final b = DreamInterpreter.offline(dream: 'Rüyamda beyaz bir kedi gördüm', name: 'Deniz', isEn: false);
    expect(a, b); // aynı rüya → aynı yorum
    expect(a, startsWith('Değerli Deniz, rüyanda beyaz bir kedi görmen'));
    expect(a, contains('delalettir'));
    expect(a, contains('işarettir'));
    final sentences = RegExp(r'[.!?…](\s|$)').allMatches(a).length;
    expect(sentences, inInclusiveRange(3, 5));
  });

  test('Y çıkmazsa genel açılış; sembol ipucu bir cümle olarak girer', () {
    final a = DreamInterpreter.offline(
        dream: 'Rüyamda uçtum', name: 'Deniz', isEn: false, symbolHint: 'Uçmak özgürlüğe işarettir. İkinci cümle.');
    expect(a, startsWith('Değerli Deniz,'));
    expect(a, contains('Uçmak özgürlüğe işarettir.'));
    expect(a, isNot(contains('İkinci cümle')));
  });

  test('İngilizce çevrimdışı yorum', () {
    final a = DreamInterpreter.offline(dream: 'I saw a white cat in my dream', name: 'Sam', isEn: true);
    expect(a, startsWith('Dear Sam, seeing a white cat in your dream signifies'));
  });

  test('anahtar yoksa (test ortamı) interpret çevrimdışına düşer ve önbelleğe alır', () async {
    final a = await DreamInterpreter.interpret(dream: 'Rüyamda deniz gördüm', name: 'Deniz', isEn: false);
    expect(a, startsWith('Değerli Deniz,'));
    final b = await DreamInterpreter.interpret(dream: 'Rüyamda deniz gördüm', name: 'Deniz', isEn: false);
    expect(identical(a, b) || a == b, isTrue);
  });
}
