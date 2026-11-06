// lib/data/services/face_landmarks.dart
//
// Cihaz-içi yüz tespiti (Google ML Kit) — yüz kadrajını bulup analiz bölgelerinin isabetini
// artırır + gülümseme olasılığı (moral). Tamamen offline. Başarısızlık/yüz yoksa null döner
// (çağıran taraf sezgi motoruna düşer) — hiç çökmez.
//
// ⚠️ ML Kit iOS asgari 15.5 ister (Anıl onayladı, 2026-11-06). Test ortamında platform kanalı
// yoktur → processImage istisna atar → null döner (sezgi yedeği devreye girer).
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceBox {
  const FaceBox(this.left, this.top, this.width, this.height, this.smile);
  final double left, top, width, height; // baked görüntü pikselinde
  final double? smile; // 0..1 (gülümseme olasılığı), yoksa null
}

class FaceLandmarks {
  FaceLandmarks._();

  static FaceDetector? _detector;
  static FaceDetector get _d => _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // smilingProbability
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

  /// [bakedPath]: EXIF yönü UYGULANMIŞ görüntü dosyası → döndürülen kutu o görüntünün
  /// koordinatlarındadır. Yüz yoksa / hata olursa null.
  static Future<FaceBox?> detect(String bakedPath) async {
    try {
      final faces = await _d.processImage(InputImage.fromFilePath(bakedPath));
      if (faces.isEmpty) return null;
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final f = faces.first;
      final r = f.boundingBox;
      return FaceBox(r.left, r.top, r.width, r.height, f.smilingProbability);
    } catch (_) {
      return null; // test ortamı / platform / tespit hatası → yedeğe düş
    }
  }
}
