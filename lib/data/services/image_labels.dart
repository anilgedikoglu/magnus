// lib/data/services/image_labels.dart
//
// Cihaz-içi (OFFLINE) görüntü etiketleme — Google ML Kit varsayılan modeli. Foto ön kontrolü
// için kullanılır (PhotoSubjectDetector): fotoğrafta "Hand", "Coffee", "Cup", "Selfie" gibi
// kavramlar var mı? Tamamen offline (model SDK'ya gömülü). Başarısızlık/test ortamı → null döner
// (çağıran sezgi yedeğine düşer) — hiç çökmez.
//
// ⚠️ Varsayılan model ~400 etiket içerir; ilgili olanlar (2026-11-06 resmî etiket haritasından
// doğrulandı): Hand(425), Nail(132), Coffee(181), Cup(315), Cappuccino(331), Selfie(439),
// Skin(297), Hair(216), Beard(17), Moustache(356), Smile(46), Mouth(149), Ear(204), Eyelash(209),
// Lipstick(283), Sunglasses(30), Glasses(422).
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabels {
  ImageLabels._();

  static ImageLabeler? _labeler;
  static ImageLabeler get _l => _labeler ??= ImageLabeler(
        // Düşük eşik → aday etiketleri topla; güven değerini çağıran tarafta süzeriz.
        options: ImageLabelerOptions(confidenceThreshold: 0.4),
      );

  /// [path] fotoğraf dosyası. Dönen: güveni [minConf] üstü etiketlerin küçük-harf İngilizce
  /// metin kümesi. Hata / platform yoksa / test ortamı → null (sezgi yedeğine düş).
  static Future<Set<String>?> etiketler(String path, {double minConf = 0.5}) async {
    try {
      final labels = await _l.processImage(InputImage.fromFilePath(path));
      final out = <String>{};
      for (final lbl in labels) {
        if (lbl.confidence >= minConf) out.add(lbl.label.toLowerCase());
      }
      return out;
    } catch (_) {
      return null; // test / platform / etiketleme hatası → yedeğe düş
    }
  }
}
