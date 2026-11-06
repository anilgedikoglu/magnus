import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/iching/iching_screen.dart';

void main() {
  test('yazı-tura satırlarından çizgiler (alttan üste, yazı sayısı tek = yang)', () {
    const metin = '1. sıra: Yazı, Tura, Tura\n2. sıra: Tura, Yazı, Yazı\n3. sıra: Yazı, Yazı, Yazı\n'
        '4. sıra: Tura, Tura, Tura\n5. sıra: Yazı, Tura, Yazı\n6. sıra: Tura, Yazı, Tura\n';
    expect(ichingCizgileri(metin), [true, false, true, false, false, true]);
    expect(ichingCizgileri('1. sıra: Yazı'), isNull, reason: '6 satır yoksa null');
  });

  test('veri dosyasındaki her I-Ching metni 6 çizgi verir', () {
    final data = jsonDecode(File('assets/data/iching.json').readAsStringSync()) as Map<String, dynamic>;
    for (final e in data['iching'] as List) {
      expect(ichingCizgileri((e as Map)['metin'] as String), isNotNull, reason: 'id ${e['id']}');
    }
  });
}
