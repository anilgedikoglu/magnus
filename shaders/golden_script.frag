// Altın yazı + glif-İÇİ ışık huzmesi (Acı Gerçekler, Anıl 2026-11-07).
// ShaderMask(BlendMode.srcIn) ile kullanılır: çocuk widget (beyaz metin) GLİF ALFASINI
// verir, bu shader RENGİ verir → ışık yalnız harflerin İÇİNDEN geçer (başka yerden değil).
// Faz 5: altın yazı belirir (fade Flutter tarafında). Faz 6: tek bir ışık bandı harflerin
// içinden çapraz GELİP GEÇER (uBeam>0). Faz 7: durgun altın kalır.
//
// SkSL / Impeller: pow(x,2.0) negatifte NaN → sq(); #version 460 core +
// <flutter/runtime_effect.glsl>; FlutterFragCoord(). Çıkış alfası 1.0; kapsama
// (coverage) srcIn ile çocuğun alfasından gelir, bu yüzden gölge halesi = yumuşak altın bloom.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;  // 0,1  maske kutusu (px)
uniform float uTime;  // 2    saniye (Dart'ta sarılır)
uniform float uBeam;  // 3    0..1 ışık huzmesi gücü (reduced-motion = 0)
uniform float uSeed;  // 4    hafif pırıltı çeşitlemesi

out vec4 fragColor;

float sq(float x) { return x * x; }
float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 p  = FlutterFragCoord().xy;
  vec2 uv = p / uSize;

  // ── Durgun altın: dikey degrade (üst biraz daha parlak) + ince pırıltı ─────────
  vec3 goldLo = vec3(0.78, 0.62, 0.30);   // ~#C79E4D sıcak koyu altın
  vec3 goldHi = vec3(0.95, 0.83, 0.53);   // ~#F2D387 açık altın
  vec3 gold = mix(goldLo, goldHi, clamp(1.0 - uv.y, 0.0, 1.0));
  float gr = hash(p * 0.7 + uSeed);
  gold *= 0.96 + 0.04 * gr;               // mürekkep ışığı yakalıyor hissi

  // ── Işık huzmesi: çapraz band, yavaş döngü; uzun aralıkla GELİP GEÇER ──────────
  float diag  = uv.x * 0.80 + uv.y * 0.20;
  float phase = fract(uTime * 0.16);                 // ~6.25 sn'de bir geçiş
  float center = mix(-0.35, 1.35, phase);            // metin dışından girip çıkar
  float wide = exp(-sq((diag - center) / 0.070));    // yumuşak parlama
  float core = exp(-sq((diag - center) / 0.016));    // dar ak-sıcak öz
  vec3 beamCol = vec3(1.0, 0.96, 0.82);
  vec3 col = gold + beamCol * (wide * 0.70 + core * 0.65) * uBeam;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
