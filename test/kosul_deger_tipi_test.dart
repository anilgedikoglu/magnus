// Koşul değerleri (kosullar[].deger) METİN olmalı.
// Kahve (fortune_service), Durugörü, I-Ching, Japon, Kader Çarkı vb. eskiden `deger as String` okuyordu;
// metin üretim turunda `"yasmax": 25` gibi sayı yazılınca filtre TypeError fırlatıp fal sessizce düşüyordu.
// Kod artık tip bağımsız okuyor; bu test verinin de orijinal biçimde ("25") kalmasını korur.
// Yana (yana.json) hariç: orijinal Unity verisinde sayı var ve ekranı `deger.toString()` ile güvenli okuyor.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets/data: her koşulda degisken + deger dolu metin, yaş sınırı sayı-metni (yana hariç)', () {
    final hatalar = <String>[];
    final dosyalar = Directory('assets/data')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && !f.path.endsWith('yana.json'));
    var sayac = 0;
    void gez(Object? o, String dosya) {
      if (o is List) {
        for (final x in o) {
          gez(x, dosya);
        }
      } else if (o is Map) {
        final k = o['kosullar'];
        if (k is List) {
          for (final c in k) {
            if (c is! Map) {
              hatalar.add('$dosya id=${o['id']} koşul nesne değil: $c');
              continue;
            }
            sayac++;
            // Kod eksik alanı '' sayar → bozuk koşul yanlışlıkla geçmesin diye veri burada doğrulanır (Codex incelemesi)
            final dg = c['degisken'], dv = c['deger'];
            if (dg is! String || dg.trim().isEmpty) hatalar.add('$dosya id=${o['id']} degisken boş/eksik: $c');
            if (dv is! String) {
              hatalar.add('$dosya id=${o['id']} $dg=$dv (metin değil)');
            } else if (dv.trim().isEmpty) {
              hatalar.add('$dosya id=${o['id']} $dg değeri boş');
            } else if ((dg == 'yasmax' || dg == 'yasmin') && int.tryParse(dv) == null) {
              hatalar.add('$dosya id=${o['id']} $dg sayı değil: "$dv"');
            }
          }
        }
        for (final v in o.values) {
          if (v is List || v is Map) gez(v, dosya);
        }
      }
    }

    for (final f in dosyalar) {
      final Object? j;
      try {
        j = jsonDecode(f.readAsStringSync());
      } on FormatException {
        continue;
      }
      gez(j, f.uri.pathSegments.last);
    }
    expect(sayac, greaterThan(100), reason: 'koşul taranmadı mı?');
    expect(hatalar, isEmpty, reason: hatalar.join('\n'));
  });
}
