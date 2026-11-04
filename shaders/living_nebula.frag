// shaders/living_nebula.frag
//
// "Yaşayan nebula": arka plan görselini çizer ve
//   1) domain-warp ile nebulanın kendisini çok yavaş dalgalandırır,
//   2) bulut bölgelerinde gezinen ALACALI renk yamaları (ton yönlendirme,
//      sis/örtü değil — görsel dokusu korunur),
//   3) bölgeden bölgeye değişen yavaş parlaklık nefesi (ışık oyunları),
//   4) koyulaştırma + eliptik vinyet.
// Taslak Codex ile birlikte (2026-11-04); düzeltmeler:
//   - Zaman yerine Dart'ta (double) hesaplanan SINIRLI dairesel ofsetler
//     (uFlow*/uCol*/uBreath) → mediump GPU'da hassasiyet bozulması / sarma sıçraması yok.
//   - Warp genliği fbm dağılımına göre normalize (fbm ~0.5±0.15 → ham hâli <1 px idi).

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // 0,1  çizim alanı (mantıksal px)
uniform vec2 uImgSize;   // 2,3  görsel (piksel)
uniform float uDark;     // 4    ek karartma
uniform vec2 uFlow1;     // 5,6  warp alanı ofseti
uniform vec2 uFlow2;     // 7,8
uniform vec2 uCol1;      // 9,10 renk alanı ofseti
uniform vec2 uCol2;      // 11,12
uniform float uBreath;   // 13   nefes fazı (rad, 0..2π)
uniform sampler2D uImage; // sampler 0

out vec4 fragColor;

const float WARP_PX   = 14.0; // (flow-0.5)*14 → tipik ±2, tepe ~±5.5 mantıksal px
// Görsel doğrulama (v1): palet tinti 0.40 tüm nebulayı mora boyuyordu = "sabit morluk".
// v2: ana alacalanma = nebulanın KENDİ renklerini bölge bölge döndürmek; tint az.
const float TINT      = 0.12; // mor/indigo palet tinti (kimlik bağı, düşük)
// YIQ ton açısı θ=atan(Q,I): kırmızı ≈+19°, magenta +62°, mor +93°, mavi +136°;
// turuncu −6°, sarı −44°, yeşil −118°. → POZİTİF dönüş = soğuk (magenta/mor/mavi),
// NEGATİF dönüş = sarı/yeşil (koyu sarı = zeytin/kirli).
// Görsel doğrulama geçmişi: v2 simetrik ±72° → +taraf güzel mavi-mor, −taraf zeytin;
// v3/v4'te yön ters kurulmuştu (zeytin arttı). v5: soğuk yamalar +72°, sıcaklar en
// fazla −10° (kırmızı→altın-turuncu) + canlılık/parıltı. Yeşil oluşamaz.
const float HUE_COOL  = 1.25;  // +72°
const float HUE_WARM  = 0.17;  // −10°
const float BREATH    = 0.10; // bölgesel parlaklık nefesi ±%10 (sadece bulutlarda)
// Gece Grimuarı (2026-11): arayüz kemik/altın/cam diline geçti; nebula hâlâ alacalı ama
// kırmızı-turuncu bağırmasın diye son çıktı doygunluğu %58'e çekilir (ton/hareket aynı).
const float GRIMOIRE_SAT = 0.58;

// YIQ uzayında ton döndürme: parlaklık (Y) korunur, sadece renk açısı döner.
vec3 hueRotate(vec3 c, float ang) {
  const mat3 toYIQ = mat3(0.299, 0.596, 0.211,
                          0.587, -0.274, -0.523,
                          0.114, -0.322, 0.312);
  const mat3 toRGB = mat3(1.0, 1.0, 1.0,
                          0.956, -0.272, -1.106,
                          0.621, -0.647, 1.703);
  vec3 yiq = toYIQ * c;
  float cs = cos(ang), sn = sin(ang);
  yiq.yz = vec2(yiq.y * cs - yiq.z * sn, yiq.y * sn + yiq.z * cs);
  return toRGB * yiq;
}

float hash21(vec2 p) {
  vec3 q = fract(vec3(p.xyx) * 0.1031);
  q += dot(q, q.yzx + 33.33);
  return fract((q.x + q.y) * q.z);
}

float noise2(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
    mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
    f.y);
}

float fbm2(vec2 p) {
  mat2 r = mat2(0.8, -0.6, 0.6, 0.8); // oktavları döndür → karemsi iz olmasın
  return (2.0 * noise2(p) + noise2(r * p * 2.03 + vec2(17.1, 9.2))) / 3.0;
}

void main() {
  vec2 st = FlutterFragCoord().xy / uSize;
  vec2 p = (st - 0.5) * uSize / min(uSize.x, uSize.y);

  // ── 1) Dalgalanma: iki yavaş alan; ekran kenarlarında söner (clamp şeridi olmasın).
  vec2 flow = vec2(
    fbm2(p * 2.1 + uFlow1),
    fbm2(p * 2.1 + uFlow2 + vec2(12.7, 5.3)));
  vec2 edge = min(st, vec2(1.0) - st);
  float edgeFade = smoothstep(0.0, 0.06, min(edge.x, edge.y));
  vec2 warpPx = (flow - 0.5) * WARP_PX * edgeFade;

  // Ortalanmış BoxFit.cover; warp mantıksal pikselde.
  float cover = max(uSize.x / uImgSize.x, uSize.y / uImgSize.y);
  vec2 uv = vec2(0.5) + ((st - 0.5) * uSize + warpPx) / (uImgSize * cover);
  vec2 halfTexel = vec2(0.5) / uImgSize;
  uv = clamp(uv, halfTexel, vec2(1.0) - halfTexel);

  vec4 texel = texture(uImage, uv);
  vec3 src = texel.rgb / max(texel.a, 0.0001);

  // Yaklaşık bulut maskesi: karanlık uzay ve beyaz (doygunluğu düşük) yıldızlar hariç.
  float hi = max(src.r, max(src.g, src.b));
  float lo = min(src.r, min(src.g, src.b));
  float sat = (hi - lo) / max(hi, 0.001);
  float cloud = smoothstep(0.035, 0.30, hi) * smoothstep(0.08, 0.42, sat);

  // ── 2) Alacalı renk: iki bağımsız, gezinen alan. Yamalar v1'den küçük (1.65→2.4)
  //    → aynı anda ekranda birden çok renk bölgesi görünür.
  float a = fbm2(p * 2.4 + flow * 0.55 + uCol1);
  float b = noise2(p * 1.3 + vec2(8.4, 3.7) + uCol2);

  // Bölgesel ton döndürme: fbm ~0.5±0.15 → [-1,1]'e gerilir; işaretine göre bir bölge
  // sıcağa (altın/turuncu), komşusu soğuğa (magenta/mor/mavi) döner. Yalnız bulutlarda.
  float hn = clamp((a - 0.5) * 3.2 + (b - 0.5) * 1.2, -1.0, 1.0);
  float cool = max(-hn, 0.0);
  float warm = max(hn, 0.0);
  src = max(hueRotate(src, (cool * HUE_COOL - warm * HUE_WARM) * cloud), vec3(0.0));
  // Doygunluk: sıcak yamalar canlanır (+%30), ayrıca bağımsız ±%22 oynama (tozlu/canlı).
  float luma = dot(src, vec3(0.299, 0.587, 0.114));
  src = mix(vec3(luma), src, 1.0 + cloud * (0.30 * warm + 0.22 * (b - 0.5) * 2.0));
  src *= 1.0 + 0.08 * warm * cloud; // sıcak çekirdekler hafif parlar
  hi = max(src.r, max(src.g, src.b));

  // Kimlik tinti: yalnız indigo/mor/magenta. Teal ÇIKARILDI (görsel doğrulama: teal,
  // "a" yüksek = sıcak yamalarla aynı yere düşüp turuncuyla karışınca zeytin yapıyordu).
  vec3 indigo  = vec3(0.169, 0.180, 0.373); // #2B2E5F
  vec3 violet  = vec3(0.420, 0.290, 0.518); // #6B4A84
  vec3 magenta = vec3(0.541, 0.263, 0.408); // #8A4368

  vec3 palette = mix(indigo, violet, smoothstep(0.22, 0.62, a));
  palette = mix(palette, magenta, smoothstep(0.46, 0.76, b));

  // Ton yönlendirme: paletin rengini, pikselin kendi parlaklığında uygula —
  // sadece soğuk yamalarda (sıcak yamalar nebulanın doğal kırmızı/turuncusu kalsın).
  palette /= max(max(palette.r, palette.g), palette.b);
  vec3 colored = mix(src, palette * hi, cloud * TINT * (0.35 + 0.65 * cool));

  // ── 3) Bölgesel nefes (ışık oyunları): faz uzaya göre değişir → senkron değil.
  float breath = 1.0 + BREATH * cloud * sin(uBreath + a * 6.2831853 + b * 2.0);

  // ── 4) Koyulaştırma + eliptik vinyet.
  float vertical = abs(st.y * 2.0 - 1.0);
  float transmission = clamp(0.60 - 0.08 * vertical * vertical - uDark, 0.0, 1.0);
  vec2 e = (st - 0.5) / vec2(0.72, 0.76);
  float vignette = 1.0 - 0.27 * smoothstep(0.35, 0.95, length(e));

  vec3 rgb = colored * breath * transmission * vignette;
  rgb = mix(vec3(dot(rgb, vec3(0.299, 0.587, 0.114))), rgb, GRIMOIRE_SAT);
  fragColor = vec4(clamp(rgb * texel.a, 0.0, 1.0), 1.0); // opak
}
