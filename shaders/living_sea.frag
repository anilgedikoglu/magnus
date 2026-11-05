// Yaşayan deniz (Kader Kitabı, Anıl 2026-11-06: "tıpkı Hooop oyununda denizi dalgalandırdığın
// gibi dalgalandır"). Hooop'un MenuSea shader'ından uyarlandı (C:\src\jumpjump\Assets\Game\
// Resources\Shaders\MenuSea.shader): boyalı resimde UFKUN ALTI dalgalanır, küçük parıltılar
// yanıp söner, ışık bantları izleyiciye doğru yuvarlanır, suyun parlaklığı nefes alır.
// Flutter'da y aşağı doğru artar: su = uv.y > uHorizon.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // 0,1  çizim alanı (mantıksal px)
uniform vec2 uImgSize;   // 2,3  görsel boyutu (px)
uniform float uTime;     // 4    saniye (Dart'ta sarılır)
uniform float uHorizon;  // 5    ufuk (görselin uv.y'si, 0 = üst)
uniform float uRipple;   // 6    dalga gücü
uniform float uDark;     // 7    ek karartma (0..1)
uniform sampler2D uImage;

out vec4 fragColor;

// BoxFit.cover eşlemesi: ekran pikseli → görsel uv.
vec2 coverUv(vec2 p) {
  float s = max(uSize.x / uImgSize.x, uSize.y / uImgSize.y);
  vec2 sz = uImgSize * s;
  vec2 off = (uSize - sz) * 0.5;
  return (p - off) / sz;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = coverUv(p);
  float t = uTime;
  vec4 orig = texture(uImage, uv);

  // Su maskesi: ufkun altı, ufukta yumuşak geçiş.
  float m = smoothstep(uHorizon - 0.005, uHorizon + 0.045, uv.y);
  // Yakın (alt) bölgede dalgalar daha büyük ve yavaş.
  float near = clamp((uv.y - uHorizon) / max(1.0 - uHorizon, 0.001), 0.0, 1.0);
  float k = mix(0.35, 1.0, near);

  vec2 d;
  d.x = sin(uv.y * mix(260.0, 90.0, near) + t * 1.3) * 0.6
      + sin(uv.y * 170.0 - t * 0.9 + uv.x * 20.0) * 0.4;
  d.y = sin(uv.x * 60.0 + t * 1.1 + uv.y * 140.0) * 0.5
      + sin(uv.x * 23.0 - t * 0.7) * 0.5;
  vec2 duv = uv + d * uRipple * k * vec2(1.0, 0.6) * m;
  vec4 moved = texture(uImage, duv);
  vec4 col = mix(orig, moved, m);

  // Parıltılar: rastgele hücreler kendi anında kısa yanar (deniz eğik görüldüğü için yatay).
  vec2 grid = vec2(70.0, 150.0);
  vec2 cell = floor(uv * grid);
  float h = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
  vec2 f = fract(uv * grid) - 0.5;
  float dotShape = clamp(1.0 - length(f * vec2(1.0, 1.8)) * 2.6, 0.0, 1.0);
  float flash = pow(clamp(sin(t * (0.6 + h * 0.9) + h * 40.0), 0.0, 1.0), 24.0);
  // Gece: ay ışığı gümüşü, biraz seyrek.
  col.rgb += step(0.78, h) * flash * dotShape * 1.05 * m * mix(0.5, 1.0, near)
      * vec3(0.82, 0.90, 1.0);

  // Ufuktan izleyiciye yuvarlanan yumuşak ışık bantları.
  float swell = pow(clamp(sin(uv.y * 55.0 - t * 1.6 + sin(uv.x * 8.0 + t * 0.4) * 1.5), 0.0, 1.0), 6.0);
  col.rgb += swell * 0.06 * m * mix(0.3, 1.0, near) * vec3(0.70, 0.80, 1.0);

  // Suyun parlaklığı dalgalar geçtikçe hafifçe nefes alır.
  col.rgb *= 1.0 + 0.08 * sin(uv.y * 30.0 - t * 0.8 + uv.x * 6.0) * m;

  col.rgb *= (1.0 - uDark);
  fragColor = vec4(col.rgb, 1.0);
}
