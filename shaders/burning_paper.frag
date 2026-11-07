// Yanan papirüs — SİNEMATİK sekans (Acı Gerçekler, Anıl 2026-11-07, yeniden yazım).
// Fazlar (tek uBurn 0→1 + uSmoke zarfı ile sürülür, Dart'ta):
//   1) Açık, eski bir papirüs (gerçek görsel varsa uPaper, yoksa prosedürel yedek).
//   2) SAĞ ALT köşeden tutuşur; ak-sıcak cephe + alev dilleri + köz/ember + yoğun duman
//      yavaşça sola-yukarı tüm kağıdı sarar.
//   3) Cephenin gerisinden KAPKARA (kömürleşmiş) kağıt çıkar; bütünlük bozulmaz.
//   4) Kömür üstündeki gri dumanlar yavaşça kaybolur → geriye yanık izli kara kağıt.
//   (Altın yazı + glif-içi ışık huzmeleri AYRI katmanda: golden_script.frag + ShaderMask.)
//
// SkSL / Impeller kısıtları (DEĞİŞTİRME):
//   • pow(x,2.0) negatif x için NaN → kareyi çarpımla al (sq()); küp için x*x*x.
//   • dFdx/dFdy YOK → manuel sonlu-fark.
//   • ters-argümanlı smoothstep (a>b) TANIMSIZ → 1.0 - smoothstep(a,b,x) kullan (a<b).
//   • #version 460 core + #include <flutter/runtime_effect.glsl>, FlutterFragCoord().
//   • Sampler'lar NORMALİZE koordinatla; görsel premultiplied → rgb /= a ile çöz.
//   • uPaper her zaman bağlıdır (yoksa 1×1 kukla); uHasPaper 0 iken kullanılmaz,
//     uImgSize böleni max(.,1) ile korunur (div-by-zero yok).
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;     // 0,1  çizim alanı (px)
uniform float uTime;     // 2    saniye (Dart'ta sarılır)
uniform float uBurn;     // 3    0..1 yanma cephesi ilerlemesi
uniform float uSmoke;    // 4    0..1 duman yoğunluğu zarfı (yüksel→dağıl)
uniform float uSeed;     // 5    desen çeşitlemesi
uniform float uHasPaper; // 6    1.0 = gerçek papirüs görseli bağlı
uniform vec2  uImgSize;  // 7,8  papirüs görseli (px)
uniform sampler2D uPaper; // sampler 0

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}
float vnoise(vec2 p) {
  vec2 i = floor(p), f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
  float s = 0.0, a = 0.5;
  for (int i = 0; i < 5; i++) { s += a * vnoise(p); p *= 2.03; a *= 0.5; }
  return s;
}
float sq(float x) { return x * x; }

void main() {
  vec2 p   = FlutterFragCoord().xy;
  vec2 uv  = p / uSize;                        // 0..1
  float asp = uSize.x / max(uSize.y, 1.0);
  vec2 st  = vec2(uv.x * asp, uv.y);           // en-boy düzeltilmiş
  float t  = uTime;
  float seed = uSeed;

  // ── Kağıt lifi + kırışık kabartması (3D ışık) ───────────────────────────────
  float h  = fbm(st * 3.0 + seed * 2.3) * 0.6;
  float hx = fbm((st + vec2(0.004, 0.0)) * 3.0 + seed * 2.3) * 0.6;
  float hy = fbm((st + vec2(0.0, 0.004)) * 3.0 + seed * 2.3) * 0.6;
  vec3 nrm = normalize(vec3((h - hx) * 6.0, (h - hy) * 6.0, 1.0));
  vec3 lightDir = normalize(vec3(-0.42, -0.5, 0.78));
  float diff = clamp(dot(nrm, lightDir), 0.0, 1.0);
  float shade = 0.84 + 0.24 * diff;

  // ── Faz 1: PAPİRÜS zemini ────────────────────────────────────────────────────
  vec3 paper;
  if (uHasPaper > 0.5) {
    // Ortalanmış BoxFit.cover örnekleme.
    float cover = max(uSize.x / max(uImgSize.x, 1.0), uSize.y / max(uImgSize.y, 1.0));
    vec2 tuv = vec2(0.5) + ((uv - 0.5) * uSize) / (uImgSize * cover);
    vec2 ht = vec2(0.5) / max(uImgSize, vec2(1.0));
    tuv = clamp(tuv, ht, vec2(1.0) - ht);
    vec4 tx = texture(uPaper, tuv);
    paper = tx.rgb / max(tx.a, 0.0001);
    paper *= 0.92 + 0.08 * shade;              // görseli bozmadan hafif kabartma
  } else {
    // Prosedürel eski/açık papirüs (görsel gelene kadar). Sıcak kirli-ten.
    float mottle = fbm(st * 4.0 + seed * 3.3);
    paper = mix(vec3(0.87, 0.78, 0.57), vec3(0.72, 0.60, 0.40), mottle);
    float fibh = fbm(st * vec2(6.0, 130.0) + seed);          // yatay lif
    float fibv = fbm(st * vec2(130.0, 6.0) + seed * 1.7);    // dikey lif
    paper *= 0.93 + 0.07 * fibh + 0.05 * (fibv - 0.5);
    float spots = fbm(st * 7.0 + seed * 5.0);                // yaş lekeleri
    paper *= 0.86 + 0.14 * smoothstep(0.35, 0.72, spots);
    paper *= shade;
  }

  // ── Yanma cephesi: SAĞ ALT köşeden (burnCoord=0) sol-üste ──────────────────────
  float burnCoord = ((1.0 - uv.x) + (1.0 - uv.y)) * 0.5;     // 0 = sağ alt
  float wobble = (fbm(st * 4.5 + seed) - 0.5) * 0.22
               + (fbm(st * 15.0 - seed) - 0.5) * 0.06;        // organik kenar
  float edge  = burnCoord + wobble;
  float front = mix(-0.30, 1.62, uBurn);                      // cephe konumu
  // 1 = yanmış (edge < front), 0 = kağıt. (ters-arg smoothstep yok → 1-normal.)
  float charAmt = 1.0 - smoothstep(front - 0.055, front, edge);

  // Aktif yanma kapısı (başta/sonda cephe efektleri sönük).
  float burning = smoothstep(0.015, 0.14, uBurn) * (1.0 - smoothstep(0.86, 1.0, uBurn));

  // ── Faz 3: KÖMÜRLEŞMİŞ kara kağıt + yanık izi dokusu ──────────────────────────
  float ash = fbm(st * 6.0 + seed * 3.1);
  vec3 charred = mix(vec3(0.020, 0.016, 0.014), vec3(0.006, 0.005, 0.005), ash);
  // Kalıcı yanık izi: soluk kahve/kül mottling (parlamaz) → "yanık izli kara kağıt".
  float scorch = fbm(st * vec2(9.0, 11.0) + seed * 4.0);
  charred += vec3(0.035, 0.022, 0.012) * smoothstep(0.48, 0.82, scorch);
  charred += vec3(0.018, 0.016, 0.015) * smoothstep(0.60, 0.90, ash); // gri kül parçaları

  // Cephenin HEMEN gerisinde dar sıcak köz bandı (yalnız yanarken).
  float afterGlow = exp(-sq((edge - (front - 0.05)) / 0.05)) * charAmt;
  charred += vec3(1.0, 0.38, 0.10) * afterGlow * 0.55 * burning;

  // ── Köz cephesi + ak-sıcak çekirdek + alev dilleri ────────────────────────────
  float band = exp(-sq((edge - front) / 0.05));              // cephedeki sıcak çizgi
  vec3 emberCol = mix(vec3(1.0, 0.33, 0.06), vec3(1.0, 0.85, 0.34), band);
  emberCol = mix(emberCol, vec3(1.0, 0.97, 0.86), band * band * band); // ak-sıcak çekirdek

  float flameNoise = fbm(st * vec2(11.0, 6.5) + vec2(0.0, -t * 2.6) + seed);
  float aheadFlame = exp(-sq((edge - front - 0.05) / 0.07)); // cephenin İLERİSİ
  float flame = smoothstep(0.42, 0.92, flameNoise) * aheadFlame * burning;

  // Yükselen köz/ember kıvılcımları (yüksek frekans gürültü, yukarı kayar).
  vec2 sp = st * vec2(40.0, 24.0) + vec2(fbm(st * 3.0 + seed) * 3.0, -t * 3.2);
  float sparkN = fbm(sp);
  float ahead = exp(-sq((edge - front - 0.04) / 0.11));
  float spark = smoothstep(0.80, 0.90, sparkN) * ahead * burning;

  // ── Birleştir: kağıt → kömür + cephe efektleri ────────────────────────────────
  vec3 col = mix(paper, charred, charAmt);
  col += emberCol * band * (0.40 + 0.90 * burning);
  col += vec3(1.0, 0.45, 0.12) * flame * 0.95;
  col += vec3(1.0, 0.55, 0.18) * spark * 1.60;

  // ── Faz 2-4: KATMANLI DUMAN (fbm advection + yükselme + domain-warp) ──────────
  // Kara kağıt üstünde OKUNUR gri duman: "ortalık dumanlanır", sonra yavaşça dağılır.
  vec2 smk = st * vec2(2.0, 1.6);
  vec2 warp = vec2(fbm(smk * 1.3 + vec2(0.0, t * 0.25) + seed),
                   fbm(smk * 1.3 + vec2(5.2, t * 0.22) - seed));
  smk += (warp - 0.5) * 1.0;                                  // kıvrım/billow
  smk.y += t * 0.34;                                          // yükselme
  float sN = fbm(smk) * 0.62 + fbm(smk * 2.7 + vec2(0.0, t * 0.5)) * 0.38;
  float dens = clamp((sN - 0.34) * 3.0, 0.0, 1.0);
  dens *= mix(1.10, 0.80, uv.y);                              // alt kısımda biraz yoğun
  float smokeAmt = clamp(dens * uSmoke, 0.0, 0.92);
  vec3 smokeCol = mix(vec3(0.34, 0.33, 0.32), vec3(0.78, 0.77, 0.75), sN);
  // Cephe çevresinde alev ışığıyla aydınlanan sıcak duman (sinematik).
  float frontProx = exp(-sq((edge - front) / 0.20));
  smokeCol += vec3(0.60, 0.28, 0.08) * frontProx * burning * 0.55;
  col = mix(col, smokeCol, smokeAmt);

  // ── Film grani + eliptik vinyet (sinematik) ───────────────────────────────────
  float grain = hash(p + vec2(t * 37.0, t * 17.0));
  col += (grain - 0.5) * 0.024;
  vec2 q = uv - 0.5;
  col *= 1.0 - dot(q, q) * 0.42;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
