// test/photo_subject_detector_test.dart
//
// Foto ön kontrol dedektörü — sezgi (ten oranı) yolunu doğrular. ML Kit (yüz tespiti + görüntü
// etiketleme) test ortamında ÇALIŞMAZ (platform kanalı yok) → dedektör ten sezgisine düşer.
// Bu yüzden testler yalnız sezgi katmanını ölçer; ML Kit yolu ancak cihaz build'inde doğrulanır.
//
// Hoşgörü ilkesi: dedektör yalnız EMİN olunca false döner; belirsizlik/hata → true.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:magnus_app/data/services/photo_subject_detector.dart';

/// Düz renkli PNG dosyası üretir, yolunu döndürür.
Future<String> _duzRenk(int r, int g, int b, String ad) async {
  final im = img.Image(width: 80, height: 80);
  img.fill(im, color: img.ColorRgb8(r, g, b));
  final f = File('${Directory.systemTemp.path}/psd_$ad.png');
  await f.writeAsBytes(img.encodePng(im));
  return f.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tenYol;   // sıcak ten rengi (avuç/yüz)
  late String maviYol;  // mavi (gökyüzü/obje)
  late String griYol;   // nötr gri (fincan/masa/duvar — ten DEĞİL)

  setUpAll(() async {
    tenYol  = await _duzRenk(200, 150, 120, 'ten');
    maviYol = await _duzRenk(30, 60, 200, 'mavi');
    griYol  = await _duzRenk(128, 128, 128, 'gri');
  });

  group('el (hand)', () {
    test('ten-baskın görsel → el kabul', () async {
      expect(await PhotoSubjectDetector.uygunMu(tenYol, FotoKonu.el), isTrue);
    });
    test('mavi görsel (ten yok) → el reddet', () async {
      expect(await PhotoSubjectDetector.uygunMu(maviYol, FotoKonu.el), isFalse);
    });
    test('gri görsel (ten DEĞİL) → el reddet', () async {
      expect(await PhotoSubjectDetector.uygunMu(griYol, FotoKonu.el), isFalse);
    });
  });

  group('fincan (coffee cup)', () {
    test('ten-baskın görsel (el/yüz) → fincan reddet', () async {
      expect(await PhotoSubjectDetector.uygunMu(tenYol, FotoKonu.fincan), isFalse);
    });
    test('gri görsel (gri fincan) → fincan kabul (gri ten sayılmaz)', () async {
      expect(await PhotoSubjectDetector.uygunMu(griYol, FotoKonu.fincan), isTrue);
    });
    test('mavi görsel → fincan kabul (hoşgörü — pozitif doğrulama ML Kit işi)', () async {
      expect(await PhotoSubjectDetector.uygunMu(maviYol, FotoKonu.fincan), isTrue);
    });
  });

  group('yuz (face)', () {
    // ML Kit yüz tespiti test ortamında kullanılamaz → dedektör engellemez (hoşgörü).
    test('ten görsel → kullanılamaz ML Kit, engelleme yok → kabul', () async {
      expect(await PhotoSubjectDetector.uygunMu(tenYol, FotoKonu.yuz), isTrue);
    });
    test('mavi görsel → kabul (ML Kit yok, kesin ret dayanağı yok)', () async {
      expect(await PhotoSubjectDetector.uygunMu(maviYol, FotoKonu.yuz), isTrue);
    });
  });

  group('güvenlik (asla çökme)', () {
    test('çözülemeyen/bozuk dosya → hiçbir konuda çökmez, engellemez', () async {
      final f = File('${Directory.systemTemp.path}/psd_bozuk.png');
      await f.writeAsBytes([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(await PhotoSubjectDetector.uygunMu(f.path, FotoKonu.el), isTrue);
      expect(await PhotoSubjectDetector.uygunMu(f.path, FotoKonu.fincan), isTrue);
      expect(await PhotoSubjectDetector.uygunMu(f.path, FotoKonu.yuz), isTrue);
    });
    test('var olmayan dosya → engellemez', () async {
      const yok = '/nonexistent/path/xyz.png';
      expect(await PhotoSubjectDetector.uygunMu(yok, FotoKonu.el), isTrue);
      expect(await PhotoSubjectDetector.uygunMu(yok, FotoKonu.fincan), isTrue);
    });
  });
}
