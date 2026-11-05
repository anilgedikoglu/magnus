// shaders/glass_lens.frag
//
// Cam alt barın "sıvı cam" ışık kırılması (Anıl, 2026-11-05: "bizde buzlu cam gibi,
// pürüzlü; onlarda iki cam arası sıvı var gibi kırıyor ışığı, saptırıyor").
// BackdropFilter + ImageFilter.shader (YALNIZ Impeller; Skia'da Dart tarafı eski buzlu
// cama düşer).
//
// Model, Instagram'ın iOS 26 barından ÖLÇÜLDÜ (aynı sayfanın iki ekran görüntüsü 7 px
// kaydırılmış; bar içindeki her satır arkadaki içerikle eşleştirildi, ort. hata 2.4/255):
//   • Barın ortası arkayı neredeyse aynen gösterir (yer değiştirme ~0).
//   • Kenarda yuvarlak bir cam PAHI var (genişlik w = 0.234h, h = bar yüksekliği): kenardan
//     d uzaklıkta örnek, barın İÇİNE doğru Δ = 0.238h · eğim kayar; eğim = dairesel pah
//     yüzeyinin eğimi t/√(w²−t²), t = w−d (en çok 0.5h). Ölçülen eşleme s(d)=d+Δ ile
//     9 noktanın 8'inde ±1–4 px uyumlu. Sonuç: pahın büyük kısmında (d≈0.07h–0.23h) görüntü
//     neredeyse sabit bir satırdan gelir → yatay çizgiler dikeyde AKAR; en dış ~0.07h'de
//     kısa, sıkışık bir ayna. (İlk deneme exp(−d/λ) modeli, kenar bandında yazıyı net ve
//     ters gösterdi — Instagram'da o bant akışkan; eğim modeli bunu düzeltti.)
//   • Bulanıklık ÇOK hafif ve normal yönünde (düz kısımda dikey): σ ≈ 0.028h.
//     Yatay ayrıntı keskin kalır (dikey çizgiler camdan geçer, yatay çizgiler akar).
// Kapsül (stadyum) geometrisi: yer değiştirme yönü kenarın normali (uçlarda radyal).
//
// Koordinatlar: FlutterFragCoord = global FİZİKSEL piksel; doku = tüm arka plan
// (uSize motor tarafından verilir). Sonda doku örneklemesi GLES'te y ekseni ters.

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // 0,1  doku boyutu (motor doldurur)
uniform vec4 uRect;     // 2-5  barın global fiziksel dikdörtgeni: sol, üst, genişlik, yükseklik
uniform float uRefract; // 6    kırılma katsayısı (h oranı), ölçüm 0.238
uniform float uBevel;   // 7    cam pahının genişliği (h oranı), ölçüm 0.234
uniform float uBlur;    // 8    normal yönünde bulanıklık σ (h oranı), ölçüm 0.028
uniform float uSat;     // 9    doygunluk (bizim cam: 1.25)
uniform sampler2D uTex; // arka plan

out vec4 fragColor;

vec4 tapAt(vec2 p) {
  vec2 uv = clamp(p / uSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTex, uv);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float h = max(uRect.w, 1.0);
  float rad = 0.5 * h;

  // Kapsülün orta çizgisine en yakın nokta → dışa normal + kenara uzaklık.
  float x0 = uRect.x + rad;
  float x1 = max(x0, uRect.x + uRect.z - rad);
  vec2 q = vec2(clamp(p.x, x0, x1), uRect.y + rad);
  vec2 v = p - q;
  float r = length(v);
  vec2 n = r > 0.001 ? v / r : vec2(0.0, -1.0);
  float d = max(rad - r, 0.0);

  // Kırılma: kenara yakın pikseller içeriden örnek alır.
  float w = max(uBevel * h, 0.001);
  float t = clamp(w - d, 0.0, w * 0.9999);
  float slope = t / sqrt(w * w - t * t);
  float disp = min(uRefract * h * slope, rad);
  vec2 s = p - n * disp;

  // Normal yönünde 9 dokunuşlu Gauss (±2.4σ).
  float sig = uBlur * h;
  vec4 acc = vec4(0.0);
  float wsum = 0.0;
  for (int i = -4; i <= 4; i++) {
    float k = float(i) * 0.6;
    float w = exp(-0.5 * k * k);
    acc += w * tapAt(s + n * (k * sig));
    wsum += w;
  }
  vec4 c = acc / wsum;

  float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
  fragColor = vec4(mix(vec3(l), c.rgb, uSat), c.a);
}
