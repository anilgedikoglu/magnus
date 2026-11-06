// Yanan kağıt (Acı Gerçekler, Anıl 2026-11-06): beyaz kağıdın bir köşesi tutuşur,
// alev kağıdı sarar, kağıt KÜLE döner (bütünlüğü bozulmaz; delinmez) — simsiyah kömürleşmiş
// kağıtta çatlaklardan altın-turuncu ışık sızar. uBurn 0 (beyaz kağıt) → 1 (tamamen kül).
// Saf fragment shader (Impeller gerekmez; Skia'da da çalışır). 3D his: lif normali + ışık + vinyet.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;    // 0,1  çizim alanı (px)
uniform float uTime;   // 2    saniye (Dart'ta sarılır)
uniform float uBurn;   // 3    0..1 yanma ilerlemesi
uniform float uSeed;   // 4    desen çeşitlemesi

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
// NOT: pow(x, 2.0) negatif x için GLSL'de TANIMSIZ (NaN) → kareyi çarpımla al.
float sq(float x) { return x * x; }

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = p / uSize;                 // 0..1
  float asp = uSize.x / max(uSize.y, 1.0);
  vec2 st = vec2(uv.x * asp, uv.y);    // en-boy düzeltilmiş
  float t = uTime;
  float seed = uSeed;

  // ── Kağıt lifi + 3D kabartma ışığı ──────────────────────────────────────
  float fiber = fbm(st * vec2(9.0, 240.0) + seed) * 0.5
              + fbm(st * vec2(240.0, 9.0) + seed * 1.7) * 0.5;
  float crump = fbm(st * 3.0 + seed * 2.3);
  float h  = crump * 0.6 + fiber * 0.12;
  float hx = fbm((st + vec2(0.004, 0.0)) * 3.0 + seed * 2.3) * 0.6;
  float hy = fbm((st + vec2(0.0, 0.004)) * 3.0 + seed * 2.3) * 0.6;
  vec3 nrm = normalize(vec3((h - hx) * 6.0, (h - hy) * 6.0, 1.0));
  vec3 lightDir = normalize(vec3(-0.42, -0.5, 0.78));
  float diff = clamp(dot(nrm, lightDir), 0.0, 1.0);
  float shade = 0.86 + 0.20 * diff;

  vec3 paper = vec3(0.96, 0.93, 0.86) * shade;  // kirli beyaz kağıt
  paper *= 0.95 + 0.05 * fiber;

  // ── Yanma cephesi: SAĞ ALT köşeden tutuşur, sol üste doğru ilerler ──────
  float burnCoord = ((1.0 - uv.x) + (1.0 - uv.y)) * 0.5;  // 0 = sağ alt köşe
  float wobble = (fbm(st * 4.5 + seed) - 0.5) * 0.20
               + (fbm(st * 15.0 - seed) - 0.5) * 0.06;
  float edge = burnCoord + wobble;
  float front = mix(-0.28, 1.5, uBurn);
  // 1 yanmış (edge < front), 0 kağıt. (SkSL'de ters-argümanlı smoothstep TANIMSIZ → 1-normal.)
  float charAmt = 1.0 - smoothstep(front - 0.05, front, edge);

  // ── Kömürleşmiş SİMSİYAH kağıt + çatlaklardan sızan İNCE ışık ────────────
  float ash = fbm(st * 6.0 + seed * 3.1);
  vec3 charred = mix(vec3(0.028, 0.022, 0.019), vec3(0.006, 0.005, 0.005), ash);

  // İNCE çatlak çizgileri: işaretli gürültünün SIFIR GEÇİŞLERİ. Manuel sonlu-fark türeviyle
  // normalleştir (dFdx SkSL'de yok) → yaklaşık SABİT genişlikte çizgi.
  float ce = 0.0025;
  vec2 cp = st * vec2(6.0, 7.0) + seed * 5.0;
  float n1  = fbm(cp) - 0.5;
  float n1x = fbm(cp + vec2(ce, 0.0)) - 0.5;
  float n1y = fbm(cp + vec2(0.0, ce)) - 0.5;
  float g1  = length(vec2(n1x - n1, n1y - n1)) / ce + 1e-4;
  float crack1 = 1.0 - smoothstep(0.0, 0.006, abs(n1) / g1);

  vec2 cp2 = st * vec2(13.0, 15.0) - seed * 2.0;
  float n2  = fbm(cp2) - 0.5;
  float n2x = fbm(cp2 + vec2(ce, 0.0)) - 0.5;
  float n2y = fbm(cp2 + vec2(0.0, ce)) - 0.5;
  float g2  = length(vec2(n2x - n2, n2y - n2)) / ce + 1e-4;
  float crack2 = 1.0 - smoothstep(0.0, 0.0038, abs(n2) / g2);

  float crackPulse = 0.55 + 0.45 * sin(t * 1.3 + st.x * 8.0 + st.y * 5.0);
  vec3 crackGlow = vec3(1.0, 0.60, 0.20) * crack1 * crackPulse * 1.15
                 + vec3(1.0, 0.82, 0.45) * crack2 * (0.55 + 0.35 * sin(t * 2.0 + st.y * 20.0)) * 0.85;

  charred += crackGlow;

  // Yanmanın hemen gerisindeki DAR sıcak köz bandı (tüm bölgeye değil).
  float afterGlow = exp(-sq((edge - (front - 0.05)) / 0.045)) * charAmt;
  charred += vec3(1.0, 0.38, 0.10) * afterGlow * 0.5;

  // ── Köz cephesi + alev dilleri ─────────────────────────────────────────
  float band = exp(-sq((edge - front) / 0.05));       // cephedeki sıcak çizgi
  float flameNoise = fbm(st * vec2(11.0, 6.5) + vec2(0.0, -t * 2.4) + seed);
  // Alev dilleri cephenin hemen İLERİSİNDE (yanmamış tarafta) yükselir — Gaussian bant.
  float ahead = exp(-sq((edge - front - 0.05) / 0.06));
  float flame = smoothstep(0.42, 0.92, flameNoise) * ahead;
  vec3 emberCol = mix(vec3(1.0, 0.33, 0.06), vec3(1.0, 0.85, 0.34), band);
  emberCol = mix(emberCol, vec3(1.0, 0.97, 0.86), pow(band, 3.0));  // ak-sıcak çekirdek

  // ── Birleştir ──────────────────────────────────────────────────────────
  vec3 col = mix(paper, charred, charAmt);
  float burning = smoothstep(0.02, 0.2, uBurn) * (1.0 - smoothstep(0.9, 1.02, uBurn));
  col += emberCol * band * (0.5 + 0.9 * burning);
  col += vec3(1.0, 0.45, 0.12) * flame * 0.95 * (0.3 + burning);

  // 3D derinlik: hafif vinyet
  vec2 q = uv - 0.5;
  col *= 1.0 - dot(q, q) * 0.38;

  fragColor = vec4(col, 1.0);
}
