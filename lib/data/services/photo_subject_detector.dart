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
          // Hedef sinyalini öncele: avuç + yüz AYNI karede olabilir (kişi kendi avucunu
          // yüzüyle çekebilir) → yüz bulundu diye eli reddetme (Codex).
          if (has(_elWords)) return true; // ML Kit "Hand/Nail" gördü
          if (has(_fincanWords)) return false; // fincan (el etiketi yoksa)
          if (skin >= 0.35) return true; // bol ten → el (yüz de kadrajdaysa bile)
          if (face == FaceDurum.bulundu) return false; // yüz var + az ten → el'e yollanmış selfie
          if (skin >= 0.12) return true; // el gibi ten, yüz yok → el
          if (skin >= 0 && skin < 0.03) return false; // neredeyse hiç ten → el değil
          return true; // ara/belirsiz → engelleme

        case FotoKonu.fincan:
          if (has(_fincanWords)) return true; // ML Kit "Coffee/Cup/Cappuccino" gördü (varsa en güçlü)
          if (face == FaceDurum.bulundu) return false; // yüz
          if (has(_elWords)) return false; // el
          if (has(_yuzWordsStrong)) return false; // yüz
          // Ten-reddi SON ÇARE + çok yüksek eşik: gri/beyaz/krem fincan maskeden çıkarıldı ama
          // yine de yanlış rete karşı eşik yüksek; asıl işi etiket + yüz tespiti yapar (Codex).
          if (skin >= 0.55) return false; // açıkça ten-baskın → el/yüz, fincan değil
          return true; // fincan'ı offline pozitif doğrulamak zor → varsayılan kabul
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
