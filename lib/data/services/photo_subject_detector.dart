// lib/data/services/photo_subject_detector.dart
//
// Foto ön kontrolü (OFFLINE): kahve/el/yüz fallarına gönderilen fotoğraf gerçekten
// fincan / el / yüz mü? Değilse ekran "Ben bu fotoğraftan bir X göremiyorum..." uyarısı verir
// ve fal başlamaz (günlük hak da tüketilmez).
//
// Ensemble (3 sinyal birleştirilir):
//   1) ML Kit yüz tespiti (FaceLandmarks.durumu) — yüz için ASIL, el/fincan için "yüz mü?" ayracı.
//   2) ML Kit görüntü etiketleme (ImageLabels.etiketler) — "Hand/Nail", "Coffee/Cup", "Selfie/Hair"...
//   3) YCbCr ten piksel oranı (image paketi) — el (ten-baskın) ↔ fincan (ten değil) ayrımı.
//
// İLKE: HOŞGÖRÜLÜ. Yalnızca EMİN olunca false döner. ML Kit test ortamında/platform hatasında
// çalışmaz → sezgiye (ten oranı) düşer; hiçbir koşulda çökmez, belirsizlikte kullanıcıyı engellemez.
import 'dart:io';

import 'package:image/image.dart' as img;

import 'face_landmarks.dart';
import 'image_labels.dart';

enum FotoKonu { yuz, el, fincan }

class PhotoSubjectDetector {
  PhotoSubjectDetector._();

  // ML Kit varsayılan modeli etiketleri (küçük harf). 'skin'/'flesh' KASITLI yok: el de ten verir,
  // yüzü elden ayırt etmez → yüz lehine güçlü etiketlerde kullanılmaz.
  static const _elWords = {'hand', 'nail', 'finger', 'thumb', 'wrist'};
  static const _fincanWords = {
    'coffee', 'cup', 'cappuccino', 'espresso', 'latte', 'mug', 'teacup', 'saucer', 'drink'
  };
  static const _yuzWordsStrong = {
    'selfie', 'hair', 'beard', 'moustache', 'mouth', 'ear', 'eyelash', 'lipstick', 'smile',
    'laugh', 'forehead'
  };

  /// [path] fotoğrafı [konu] için uygun mu? Yalnız EMİN olunca false; hata/belirsizlik → true.
  static Future<bool> uygunMu(String path, FotoKonu konu) async {
    try {
      final labels = await ImageLabels.etiketler(path); // Set<String>? (null = kullanılamaz)
      bool has(Set<String> s) => labels != null && labels.intersection(s).isNotEmpty;

      final face = await FaceLandmarks.durumu(path); // bulundu / yok / kullanilamaz
      final skin = await _tenOrani(path); // 0..1, çözülemezse < 0

      switch (konu) {
        case FotoKonu.yuz:
          if (face == FaceDurum.bulundu) return true;
          if (has(_yuzWordsStrong)) return true; // detektör kaçırdı ama etiket yüz görüyor
          if (has(_elWords) || has(_fincanWords)) return false; // açıkça başka bir şey
          if (face == FaceDurum.yok) return false; // güvenilir: tespit çalıştı, yüz yok
          return true; // kullanilamaz + ipucu yok → engelleme (hoşgörü)

        case FotoKonu.el:
          // Anıl (2026-11-06): el falına YÜZ atınca reddetmeli. Yüz tespiti güçlü RET sinyali;
          // ten miktarı EL kanıtı değil (selfie yüzü kadrajı doldurur) → yüz, ten'den ÖNCE (Codex).
          // Anıl (2026-11-07): "el değilse el değil diye uyarı çıksın" → KATILAŞTI.
          if (has(_elWords)) return true; // güvenilir el etiketi (Hand/Nail)
          if (face == FaceDurum.bulundu) return false; // yüz → el değil (selfie elenir)
          if (has(_fincanWords)) return false; // fincan
          if (has(_yuzWordsStrong)) return false; // güçlü yüz etiketi
          // ML Kit "el" etiketi yok → el close-up BOL ten ister; yoksa el DEĞİL.
          // Dosya çözülemediyse (skin<0: bozuk/eksik foto) ENGELLEME — kullanıcı cezalandırılmaz.
          if (skin < 0) return true;
          // ML Kit yoksa (null) sezgi eşiği biraz daha hoşgörülü.
          return labels == null ? skin >= 0.22 : skin >= 0.30;

        case FotoKonu.fincan:
          // Fincan etiketi EN GÜÇLÜ: kişi fincanı elinde tutup yüzü de kadrajda olabilir → kabul
          // (yüz reddinden önce; aksi halde fincanlı selfie 3 fotoda da reddediliyordu — Codex P2).
          if (has(_fincanWords)) return true; // Coffee/Cup/Cappuccino
          // Anıl (2026-11-07, !!!): "3/3 fincan değilse UYARI ÇIKSIN + hak dolmasın". ML Kit
          // çalıştı ama fincan etiketi YOK → fincan DEĞİL. Kahve ekranındaki "≥1/3 fincan"
          // kuralı gerçek fincanı korur (3 kareden en az biri etiketlenmesi beklenir).
          if (labels == null) {
            // ML Kit yok (test/platform ya da cihazda etiketleme başarısız). Dosya
            // çözülemediyse (skin<0) ENGELLEME. Aksi halde ten-baskın kare (el/yüz kadrajı
            // doldurmuş) fincan DEĞİL → reddet; belirsiz/düşük-ten → hoşgörü (fincan olabilir).
            if (skin < 0) return true;
            return skin < 0.30;
          }
          return false; // etiketler var, fincan yok → fincan değil
      }
    } catch (_) {
      return true; // asla engelleme
    }
  }

  /// YCbCr ten maskesiyle ten piksel oranı (0..1). Çözülemezse -1. Yönelim fark etmez.
  static Future<double> _tenOrani(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      var im = img.decodeImage(bytes);
      if (im == null) return -1;
      if (im.width > 200) im = img.copyResize(im, width: 160);
      var ten = 0, n = 0;
      for (var y = 0; y < im.height; y += 2) {
        for (var x = 0; x < im.width; x += 2) {
          final p = im.getPixel(x, y);
          if (_tenMi(p.r.toDouble(), p.g.toDouble(), p.b.toDouble())) ten++;
          n++;
        }
      }
      return n == 0 ? -1 : ten / n;
    } catch (_) {
      return -1;
    }
  }

  // Sıcak/kırmızımsı ten. ⚠️ Nötr gri ve beyaz (r≈g≈b → Cb≈Cr≈128) HARİÇ: eski maskede gri
  // fincan/masa/duvar ten sayılıyordu (Codex). cr>=137 griyi dışlar, r>b+12 sıcaklık ister.
  static bool _tenMi(double r, double g, double b) {
    final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
    final y = 0.299 * r + 0.587 * g + 0.114 * b;
    return cb >= 77 && cb <= 127 && cr >= 137 && cr <= 178 && y >= 40 && y <= 240 && r > b + 12;
  }
}
