// lib/data/services/face_analyzer.dart
//
// Cihaz-içi (OFFLINE) yüz fotoğrafı analizi — Claude Vision API yerine (Anıl, 2026-11-06).
// Saf Dart + `image` paketi; ağ yok, hiç çökmez. Doğruluk kritik değil (eğlence: özellik yalnız
// hangi hazır metin parçasının seçileceğini belirler), ama offline hiç hata vermez.
//
// Eşikler/bölgeler: Codex incelemesi (build/visual_check/codex_review/codex_yuzanaliz_rapor.txt).
// Ortalanmış portre varsayımı (baş ~Y %8–80); boş örneklemde güvenli varsayılana döner.
//
// Güvenilir: göz rengi, saç rengi, sakal(var/yok), gözlük (kaba). Profilden: cinsiyet (kendi falında).
// Deterministik-rastgele (güvenilmez, çeşitlilik için): moral, şapka, küpe, saç boyu.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'claude_vision_service.dart' show YuzAnalizi;
import 'face_landmarks.dart';

class OnDeviceFaceAnalyzer {
  OnDeviceFaceAnalyzer._();

  /// [isSelf] true → kullanıcının kendi falı (cinsiyet profilden). [profileGender] 'erkek'/'kadin'.
  static Future<YuzAnalizi> analiz(
    String imagePath, {
    required bool isSelf,
    required String profileGender,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var src = img.decodeImage(bytes);
      if (src == null) return _varsayilan(isSelf, profileGender);
      src = img.bakeOrientation(src); // EXIF yönünü bölgelerden ÖNCE düzelt

      // Renk için ~512, kenar için ~256 genişlikte kopya.
      final big = src.width > 560 ? img.copyResize(src, width: 512) : src;

      // Deterministik tohum (fotoğraf imzası) — String.hashCode DEĞİL, sabit FNV-1a.
      final seed = _imzaHash(big);

      // ── ML Kit yüz tespiti → yüz kadrajına kırp (bölgeler isabetlenir) + gülümseme.
      //    Başarısızsa / yüz yoksa / test ortamında tam görüntüye düşer (sezgi yedeği).
      var analiz = big;
      double? smile;
      try {
        final temp = '${Directory.systemTemp.path}/mlkit_${DateTime.now().microsecondsSinceEpoch}.jpg';
        final tf = File(temp)..writeAsBytesSync(img.encodeJpg(src));
        final fb = await FaceLandmarks.detect(temp);
        try {
          tf.deleteSync();
        } catch (_) {}
        if (fb != null) {
          analiz = _cropFace(big, src.width, fb);
          smile = fb.smile;
        }
      } catch (_) {/* yedeğe düş */}

      final w = analiz.width, h = analiz.height;
      final small = img.copyResize(analiz, width: 256);

      // ── Saç rengi (üst saç bandı; HSV aday sınıflandırma, çoğunluk) ──
      final sacRengi = _sacRengi(analiz, w, h);

      // ── Göz rengi (iki göz penceresi; ten hariç adaylar) ──
      final gozRengi = _gozRengi(analiz, w, h);

      // ── Gözlük (256 px'de kenar yoğunluğu) ──
      final gozluk = _gozluk(small) ? 'Gozluklu' : 'Gozluksuz';

      // ── Sakal (çene-yanak kontrastı) ──
      final beardSignal = _beardSignal(analiz, w, h);

      // ── Cinsiyet ──
      final cinsiyet = isSelf
          ? (profileGender == 'erkek' ? 'erkek' : 'kadin')
          : (beardSignal ? 'erkek' : (_det(seed, 'cins', 100) < 55 ? 'kadin' : 'erkek'));

      final sakal = cinsiyet == 'erkek' ? (beardSignal ? 'SakalKisa' : 'SakalYok') : 'SakalYok';

      // ── Moral: ML Kit gülümseme olasılığı varsa ondan, yoksa deterministik ──
      final moral = smile != null
          ? (smile > 0.55 ? 'Moraliiyi' : (smile < 0.22 ? 'Moralikotu' : 'Moralinormal'))
          : _secWeighted(seed, 'moral', const [
              ('Moralinormal', 60), ('Moraliiyi', 30), ('Moralikotu', 10),
            ]);
      final sapka = _secWeighted(seed, 'sapka', const [
        ('Sapkasiz', 82), ('Sapkali', 10), ('Bereli', 5), ('Kapali', 3),
      ]);
      final kupe = cinsiyet == 'kadin'
          ? (_det(seed, 'kupe', 100) < 45 ? 'Kupeli' : 'Kupesiz')
          : (_det(seed, 'kupe', 100) < 12 ? 'Kupeli' : 'Kupesiz');
      // Saç boyu: başörtü/şapka kapalıysa tutarlı; değilse cinsiyete göre eğilimli.
      final String sacBoyu;
      if (sapka == 'Kapali') {
        sacBoyu = 'Kapali';
      } else if (cinsiyet == 'kadin') {
        sacBoyu = _det(seed, 'sacboy', 100) < 72 ? 'UzunSac' : 'KisaSac';
      } else {
        final r = _det(seed, 'sacboy', 100);
        sacBoyu = r < 70 ? 'KisaSac' : (r < 92 ? 'UzunSac' : 'Kel');
      }

      return YuzAnalizi(
        isHuman: true, // Codex: bu kullanımda daima insan say (yanlış ret olmasın)
        cinsiyet: cinsiyet,
        gozluk: gozluk,
        gozRengi: gozRengi,
        kupe: kupe,
        moral: moral,
        sacBoyu: sacBoyu,
        sacRengi: sapka == 'Kapali' ? 'Kapali' : sacRengi,
        sakal: sakal,
        sapka: sapka,
      );
    } catch (_) {
      return _varsayilan(isSelf, profileGender);
    }
  }

  /// ML Kit yüz kutusunu, üstte saç payı bırakarak (yüz kutusu alın/saçı dışlar) kırpar.
  /// Koordinatlar baked src'de → big'e ölçeklenir. Böylece sabit % bölgeler gerçek yüze oturur.
  static img.Image _cropFace(img.Image big, int srcWidth, FaceBox fb) {
    final scale = big.width / srcWidth;
    final l = fb.left * scale, t = fb.top * scale, bw = fb.width * scale, bh = fb.height * scale;
    var cl = (l - bw * 0.12).round();
    var ct = (t - bh * 0.60).round(); // saç payı
    var cr = (l + bw + bw * 0.12).round();
    var cb = (t + bh + bh * 0.08).round();
    cl = cl.clamp(0, big.width - 2);
    ct = ct.clamp(0, big.height - 2);
    cr = cr.clamp(cl + 2, big.width);
    cb = cb.clamp(ct + 2, big.height);
    return img.copyCrop(big, x: cl, y: ct, width: cr - cl, height: cb - ct);
  }

  static YuzAnalizi _varsayilan(bool isSelf, String profileGender) => YuzAnalizi(
        isHuman: true,
        cinsiyet: isSelf ? (profileGender == 'erkek' ? 'erkek' : 'kadin') : 'kadin',
      );

  // ─────────────────────────── Saç rengi ───────────────────────────
  static String _sacRengi(img.Image im, int w, int h) {
    var esmer = 0, beyaz = 0, sarisin = 0, kizil = 0, kumral = 0, n = 0;
    final x0 = (w * 0.25).round(), x1 = (w * 0.75).round();
    final y0 = (h * 0.08).round(), y1 = (h * 0.25).round();
    for (var y = y0; y < y1; y += 4) {
      for (var x = x0; x < x1; x += 4) {
        final p = im.getPixel(x, y);
        final (hh, s, v) = _hsv(p.r.toDouble(), p.g.toDouble(), p.b.toDouble());
        n++;
        if (v < 0.25) {
          esmer++;
        } else if (s < 0.18 && v > 0.65) {
          beyaz++;
        } else if (hh >= 35 && hh <= 65 && s >= 0.20 && s <= 0.75 && v > 0.60) {
          sarisin++;
        } else if (((hh <= 25) || (hh >= 345)) && s > 0.40 && v > 0.30) {
          kizil++;
        } else {
          kumral++;
        }
      }
    }
    if (n < 100) return 'Kumral';
    final adaylar = [('Esmer', esmer), ('Beyaz', beyaz), ('Sarisin', sarisin), ('Kizil', kizil), ('Kumral', kumral)];
    adaylar.sort((a, b) => b.$2.compareTo(a.$2));
    final kazanan = adaylar.first;
    if (kazanan.$2 / n < 0.45) return 'Kumral';
    return kazanan.$1;
  }

  // ─────────────────────────── Göz rengi ───────────────────────────
  static String _gozRengi(img.Image im, int w, int h) {
    String tek(double xa, double xb) {
      var mavi = 0, yesil = 0, kahve = 0, n = 0;
      final x0 = (w * xa).round(), x1 = (w * xb).round();
      final y0 = (h * 0.34).round(), y1 = (h * 0.46).round();
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final p = im.getPixel(x, y);
          final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
          if (_tenMi(r, g, b)) continue; // ten/burun hariç
          final (hh, s, v) = _hsv(r, g, b);
          if (s < 0.20 || v < 0.15 || v > 0.85) continue;
          n++;
          if (hh >= 180 && hh <= 250) {
            mavi++;
          } else if (hh >= 70 && hh <= 170) {
            yesil++;
          } else {
            kahve++;
          }
        }
      }
      if (n < 10) return 'kahve';
      final a = [('mavi', mavi), ('yesil', yesil), ('kahve', kahve)];
      a.sort((x, y) => y.$2.compareTo(x.$2));
      if (a.first.$2 / n < 0.60) return 'kahve';
      return a.first.$1;
    }

    final sol = tek(0.28, 0.44);
    final sag = tek(0.56, 0.72);
    if (sol == sag) return sol;
    // İki göz farklıysa kahve dışındakini tercih et (kahve varsayılan).
    if (sol != 'kahve') return sol;
    if (sag != 'kahve') return sag;
    return 'kahve';
  }

  // ─────────────────────────── Gözlük ───────────────────────────
  static bool _gozluk(img.Image sm) {
    final w = sm.width, h = sm.height;
    double density(double xa, double xb) {
      var edge = 0, n = 0;
      final x0 = (w * xa).round().clamp(1, w - 2);
      final x1 = (w * xb).round().clamp(1, w - 2);
      final y0 = (h * 0.34).round().clamp(1, h - 2);
      final y1 = (h * 0.46).round().clamp(1, h - 2);
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final e = (_lum(sm, x + 1, y) - _lum(sm, x - 1, y)).abs() +
              (_lum(sm, x, y + 1) - _lum(sm, x, y - 1)).abs();
          if (e / 2 > 20) edge++;
          n++;
        }
      }
      return n == 0 ? 0 : edge / n;
    }

    final sol = density(0.28, 0.44);
    final sag = density(0.56, 0.72);
    final yanak = density(0.30, 0.40); // yanak referansı (y bandı aynı değil ama kaba ölçü)
    final cheek = _cheekEdge(sm);
    final ref = math.max(cheek, 0.02);
    return sol > 0.18 && sag > 0.18 && (sol + sag) / 2 > ref * 1.5 && yanak < sol;
  }

  static double _cheekEdge(img.Image sm) {
    final w = sm.width, h = sm.height;
    var edge = 0, n = 0;
    final x0 = (w * 0.30).round().clamp(1, w - 2), x1 = (w * 0.40).round().clamp(1, w - 2);
    final y0 = (h * 0.50).round().clamp(1, h - 2), y1 = (h * 0.60).round().clamp(1, h - 2);
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        final e = (_lum(sm, x + 1, y) - _lum(sm, x - 1, y)).abs() +
            (_lum(sm, x, y + 1) - _lum(sm, x, y - 1)).abs();
        if (e / 2 > 20) edge++;
        n++;
      }
    }
    return n == 0 ? 0 : edge / n;
  }

  // ─────────────────────────── Sakal ───────────────────────────
  static bool _beardSignal(img.Image im, int w, int h) {
    // Yanak medyan parlaklığı Yc, çene medyanı Yj. Yc−Yj büyük + çenenin %35'i koyu → sakal.
    final yanak = _lumList(im, (w * 0.25).round(), (w * 0.40).round(), (h * 0.48).round(), (h * 0.61).round());
    final cene = _lumList(im, (w * 0.36).round(), (w * 0.64).round(), (h * 0.68).round(), (h * 0.79).round());
    if (yanak.length < 20 || cene.length < 20) return false;
    final yc = _medyan(yanak), yj = _medyan(cene);
    final koyuEsik = yc - 20;
    final koyuPay = cene.where((l) => l < koyuEsik).length / cene.length;
    return (yc - yj) > math.max(18.0, 0.18 * yc) && koyuPay > 0.35;
  }

  // ─────────────────────────── Yardımcılar ───────────────────────────
  static bool _tenMi(double r, double g, double b) {
    final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
    final y = 0.299 * r + 0.587 * g + 0.114 * b;
    return cb >= 70 && cb <= 135 && cr >= 125 && cr <= 180 && y >= 20 && y <= 245;
  }

  static (double, double, double) _hsv(double r, double g, double b) {
    final rr = r / 255, gg = g / 255, bb = b / 255;
    final maxv = math.max(rr, math.max(gg, bb));
    final minv = math.min(rr, math.min(gg, bb));
    final d = maxv - minv;
    double hh = 0;
    if (d != 0) {
      if (maxv == rr) {
        hh = 60 * (((gg - bb) / d) % 6);
      } else if (maxv == gg) {
        hh = 60 * ((bb - rr) / d + 2);
      } else {
        hh = 60 * ((rr - gg) / d + 4);
      }
    }
    if (hh < 0) hh += 360;
    final s = maxv == 0 ? 0.0 : d / maxv;
    return (hh, s, maxv);
  }

  static double _lum(img.Image im, int x, int y) {
    final p = im.getPixel(x, y);
    return 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
  }

  static List<double> _lumList(img.Image im, int x0, int x1, int y0, int y1) {
    final out = <double>[];
    for (var y = y0; y < y1; y += 2) {
      for (var x = x0; x < x1; x += 2) {
        if (x < 0 || y < 0 || x >= im.width || y >= im.height) continue;
        out.add(_lum(im, x, y));
      }
    }
    return out;
  }

  static double _medyan(List<double> v) {
    final s = [...v]..sort();
    return s[s.length ~/ 2];
  }

  // Fotoğraf imzası: küçük ızgaradan FNV-1a (deterministik, sabit).
  static int _imzaHash(img.Image im) {
    var h = 0x811c9dc5;
    for (var gy = 0; gy < 8; gy++) {
      for (var gx = 0; gx < 8; gx++) {
        final x = (im.width * (gx + 0.5) / 8).round().clamp(0, im.width - 1);
        final y = (im.height * (gy + 0.5) / 8).round().clamp(0, im.height - 1);
        final p = im.getPixel(x, y);
        final q = ((p.r.toInt() >> 5) << 6) | ((p.g.toInt() >> 5) << 3) | (p.b.toInt() >> 5);
        h = (h ^ q) & 0xffffffff;
        h = (h * 0x01000193) & 0xffffffff;
      }
    }
    return h;
  }

  // Özellik başına ayrı tohumdan 0..mod-1 deterministik değer.
  static int _det(int seed, String salt, int mod) {
    var h = seed ^ 0x9e3779b9;
    for (final c in salt.codeUnits) {
      h = (h ^ c) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.abs() % mod;
  }

  static String _secWeighted(int seed, String salt, List<(String, int)> items) {
    final sum = items.fold<int>(0, (a, b) => a + b.$2);
    var r = _det(seed, salt, sum);
    for (final (v, w) in items) {
      if (r < w) return v;
      r -= w;
    }
    return items.last.$1;
  }
}
