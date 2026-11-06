// Cihaz-içi (offline) yüz analizi motoru — sentetik görsellerle (Anıl + Codex, 2026-11-06).
// Gerçek doğruluk değil, sınıflandırma mantığı + determinizm + çökmezlik test edilir.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:magnus_app/data/services/face_analyzer.dart';

// Ten rengi (YCbCr maskesinden geçer): açık ten.
const _skin = (220, 170, 150);

img.Image _yuz({(int, int, int)? sac, (int, int, int)? goz}) {
  final im = img.Image(width: 512, height: 640);
  img.fill(im, color: img.ColorRgb8(_skin.$1, _skin.$2, _skin.$3));
  final w = im.width, h = im.height;
  void boya(int x0, int x1, int y0, int y1, (int, int, int) c) {
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        im.setPixelRgb(x, y, c.$1, c.$2, c.$3);
      }
    }
  }
  if (sac != null) {
    boya((w * 0.25).round(), (w * 0.75).round(), (h * 0.08).round(), (h * 0.25).round(), sac);
  }
  if (goz != null) {
    boya((w * 0.28).round(), (w * 0.44).round(), (h * 0.34).round(), (h * 0.46).round(), goz);
    boya((w * 0.56).round(), (w * 0.72).round(), (h * 0.34).round(), (h * 0.46).round(), goz);
  }
  return im;
}

Future<String> _yaz(img.Image im) async {
  final dir = Directory.systemTemp.createTempSync('yuztest');
  final f = File('${dir.path}/t.png');
  f.writeAsBytesSync(img.encodePng(im));
  return f.path;
}

// Renk sapması (ışık) simülasyonu: tüm görüntüyü R×rMul, B×bMul ile çarp.
img.Image _cast(img.Image im, double rMul, double bMul) {
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      im.setPixelRgb(x, y, (p.r * rMul).clamp(0, 255).round(), p.g.toInt(),
          (p.b * bMul).clamp(0, 255).round());
    }
  }
  return im;
}

void main() {
  test('saç rengi: sarışın / esmer / beyaz doğru sınıflanır', () async {
    final sari = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz(sac: (200, 170, 80))),
        isSelf: true, profileGender: 'kadin');
    expect(sari.sacRengi, 'Sarisin');

    final esmer = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz(sac: (30, 25, 20))),
        isSelf: true, profileGender: 'kadin');
    expect(esmer.sacRengi, 'Esmer');

    final beyaz = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz(sac: (230, 228, 225))),
        isSelf: true, profileGender: 'kadin');
    expect(beyaz.sacRengi, 'Beyaz');
  });

  test('hafif ışık sapmasında saç rengi KAYMAZ (HSV eşikleri toleranslı)', () async {
    // Sarışın saç, hafif sıcak (R↑ B↓) ışık → yine Sarisin.
    final sicak = await OnDeviceFaceAnalyzer.analiz(
        await _yaz(_cast(_yuz(sac: (200, 170, 80)), 1.1, 0.9)),
        isSelf: true, profileGender: 'kadin');
    expect(sicak.sacRengi, 'Sarisin');
    // Esmer saç, hafif soğuk (R↓ B↑) ışık → yine Esmer.
    final soguk = await OnDeviceFaceAnalyzer.analiz(
        await _yaz(_cast(_yuz(sac: (35, 30, 28)), 0.9, 1.12)),
        isSelf: true, profileGender: 'kadin');
    expect(soguk.sacRengi, 'Esmer');
  });

  test('göz rengi: mavi gözler mavi sınıflanır', () async {
    final a = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz(goz: (60, 80, 180))),
        isSelf: true, profileGender: 'kadin');
    expect(a.gozRengi, 'mavi');
  });

  test('cinsiyet kendi falında profilden gelir', () async {
    final e = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz()),
        isSelf: true, profileGender: 'erkek');
    expect(e.cinsiyet, 'erkek');
    final k = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz()),
        isSelf: true, profileGender: 'kadin');
    expect(k.cinsiyet, 'kadin');
    expect(k.sakal, 'SakalYok'); // kadın → sakal yok
  });

  test('deterministik: aynı görsel aynı sonucu verir', () async {
    final p = await _yaz(_yuz(sac: (120, 90, 60)));
    final a = await OnDeviceFaceAnalyzer.analiz(p, isSelf: false, profileGender: 'kadin');
    final b = await OnDeviceFaceAnalyzer.analiz(p, isSelf: false, profileGender: 'kadin');
    expect(a.moral, b.moral);
    expect(a.sapka, b.sapka);
    expect(a.sacBoyu, b.sacBoyu);
    expect(a.cinsiyet, b.cinsiyet);
  });

  test('çökmez: bozuk/boş dosya güvenli varsayılan döndürür (isHuman true)', () async {
    final dir = Directory.systemTemp.createTempSync('yuztest');
    final f = File('${dir.path}/bozuk.jpg')..writeAsBytesSync([0, 1, 2, 3, 4]);
    final a = await OnDeviceFaceAnalyzer.analiz(f.path, isSelf: true, profileGender: 'erkek');
    expect(a.isHuman, isTrue);
    expect(a.cinsiyet, 'erkek');
  });

  test('hiçbir özellik geçersiz değer döndürmez', () async {
    final a = await OnDeviceFaceAnalyzer.analiz(await _yaz(_yuz(sac: (200, 170, 80), goz: (60, 80, 180))),
        isSelf: false, profileGender: 'kadin');
    expect(const {'erkek', 'kadin'}, contains(a.cinsiyet));
    expect(const {'Gozluklu', 'Gozluksuz'}, contains(a.gozluk));
    expect(const {'kahve', 'mavi', 'yesil'}, contains(a.gozRengi));
    expect(const {'Kupeli', 'Kupesiz'}, contains(a.kupe));
    expect(const {'Moraliiyi', 'Moralikotu', 'Moralinormal'}, contains(a.moral));
    expect(const {'Kel', 'KisaSac', 'UzunSac', 'Kapali'}, contains(a.sacBoyu));
    expect(const {'Beyaz', 'Esmer', 'Kapali', 'Kumral', 'Mavi', 'Pembe', 'Sarisin', 'Kizil'},
        contains(a.sacRengi));
    expect(const {'SakalKisa', 'SakalUzun', 'SakalYok'}, contains(a.sakal));
    expect(const {'Bereli', 'Kapali', 'Sapkali', 'Sapkasiz'}, contains(a.sapka));
  });
}
