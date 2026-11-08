// shaders/lamp_toggle.frag
//
// Bildirimler düğmesi: cam sürgü + LED şerit + noktalı ikon (Anıl, 2026-11-08; referans:
// Zsolt Kacso "Glass Light Toggle" kaydı). Tüm optik tek geçişte: sahne zemini, iz, iz
// üstündeki gölgeler, camdan kırılarak görünen zemin/ikon, camın içine dolan LED ışığı,
// ışık kaynağının kendisi. Ölçüler "tasarım pikseli"; ekrana uScale ile ölçeklenir.
// Noktalı ikon Dart'ta (lamp_toggle.dart) dokuya basılır, burada camın ardından okunur.

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // 0,1   çizim alanı (mantıksal px)
uniform vec2 uOrigin;    // 2,3   izin merkezi (mantıksal px)
uniform float uScale;    // 4     mantıksal px / tasarım px
uniform float uKx;       // 5     düğme merkezi x (tasarım px, izin merkezine göre)
uniform vec2 uKH;        // 6,7   düğme yarı boyu
uniform float uKR;       // 8     düğme köşe yarıçapı
uniform float uTheme;    // 9     0 karanlık … 1 aydınlık
uniform float uGrain;    // 10    film greni fazı
uniform float uLed;      // 11    LED şiddeti
uniform float uLift;     // 12    düğme kalkışı (gölge)
uniform vec3 uLight;     // 13-15 LED rengi
uniform float uTheta;    // 16    şeridin düğme çevresindeki açısı
uniform vec2 uBoxHalf;   // 17,18 ikon dokusunun yarı boyu (tasarım px)
uniform float uDpr;      // 19    fiziksel / mantıksal px
uniform sampler2D uPix;  // sampler 0: keskin noktalar
uniform sampler2D uGlow; // sampler 1: bulanık noktalar

out vec4 fragColor;

const vec2  TRACK_HALF = vec2(216.0, 112.0);
const float TRACK_R    = 72.0;
const float STRIP_HALF = 0.92;   // şeridin açısal yarı uzunluğu (rad)
const float STRIP_GAP  = 6.5;    // şeridin camdan uzaklığı
const float REFRACT    = 40.0;
const float FROST      = 0.76;
const float ICON_GLOW  = 0.64;

// smoothstep; kenarlar ters verilebilir (GLSL'de tanımsız olan durum).
float ramp(float a, float b, float x) {
  float t = clamp((x - a) / (b - a), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

float roundBox(vec2 p, vec2 half_, float r) {
  vec2 q = abs(p) - half_ + r;
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float noise(vec2 p) {
  p = fract(p * vec2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return fract((p.x + p.y) * p.x);
}

// Karanlıkta ışık eklenir; parlak yüzeyde eklemek görünmez, aynı düşüşle doygun tonlanır.
vec3 emit(vec3 col, float amt) {
  vec3 onDark = col + uLight * amt;
  vec3 onLight = mix(col, uLight * 1.04 + 0.03, clamp(1.0 - exp(-amt * 1.3), 0.0, 0.88));
  return mix(onDark, onLight, uTheme);
}

vec2 boxUv(vec2 p) {
  vec2 uv = (p + uBoxHalf) / (2.0 * uBoxHalf);
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return uv;
}

bool outsideBox(vec2 p) {
  return abs(p.x) > uBoxHalf.x || abs(p.y) > uBoxHalf.y;
}

float dotsSharp(vec2 p) {
  return outsideBox(p) ? 0.0 : texture(uPix, boxUv(p)).a;
}

float dotsSoft(vec2 p) {
  return outsideBox(p) ? 0.0 : texture(uGlow, boxUv(p)).a;
}

// Düğmeyi dışarıdan saran, çevresinde dönen ışık şeridinin uzaklık alanı.
float stripDist(vec2 p) {
  vec2 q = p - vec2(uKx, 0.0);
  float a = atan(q.y, q.x);
  float da = abs(atan(sin(a - uTheta), cos(a - uTheta)));
  float along = max(da - STRIP_HALF, 0.0) * 104.0;
  float across = roundBox(q, uKH, uKR) - STRIP_GAP;
  return length(vec2(across, along)) - 1.5;
}

float floorWash(vec2 p) {
  float d = max(stripDist(p), 0.0);
  return (exp(-d / 14.0) * 0.85 + exp(-d / 55.0) * 0.32) * uLed;
}

// Camın altındaki dünya: iz tabanı + LED yıkaması + nokta matrisi.
// [iconA]: bu noktadaki ikon örtüsü (cam tonu için).
vec3 underGlass(vec2 p, float frost, vec2 split, out float iconA) {
  float th = uTheme;
  vec3 base = vec3(mix(0.030, 0.900, th));
  base *= 1.0 + p.y / TRACK_HALF.y * mix(0.05, 0.012, th);
  float inner = ramp(-14.0, 3.0, roundBox(p - vec2(0.0, 7.0), TRACK_HALF, TRACK_R));
  base = mix(base * (1.0 - inner * 0.6), base - inner * 0.085, th);

  float wash = floorWash(p);
  base = emit(base, wash * 0.55);

  float softC = dotsSoft(p);
  vec3 a = vec3(
    mix(dotsSharp(p - split), dotsSoft(p - split) * 1.35, frost),
    mix(dotsSharp(p), softC * 1.35, frost),
    mix(dotsSharp(p + split), dotsSoft(p + split) * 1.35, frost));
  float lum = dot(base, vec3(0.299, 0.587, 0.114));
  vec3 ink = mix(vec3(1.0, 0.965, 0.925), vec3(0.11, 0.105, 0.10), ramp(0.40, 0.56, lum));
  ink = mix(ink + uLight * wash * 0.9, ink + vec3(0.25, 0.08, 0.0) * wash, th);
  iconA = clamp(a.g, 0.0, 1.0);
  vec3 col = mix(base, ink, clamp(a, 0.0, 1.0));
  col += vec3(1.0, 0.78, 0.55) * softC * ICON_GLOW * (1.0 - th);
  return col;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - uOrigin) / uScale;
  vec2 uv = frag / uSize;
  float th = uTheme;
  vec2 knob = vec2(uKx, 0.0);

  // Sahne zemini + izin zemine düşürdüğü gölgeler
  float sky = ramp(1.5, 0.0, length((uv - vec2(0.92, -0.08)) * vec2(1.0, 1.25)));
  vec3 col = mix(mix(vec3(0.040), vec3(0.120), sky), mix(vec3(0.800), vec3(0.925), sky), th);
  float trackD = roundBox(p, TRACK_HALF, TRACK_R);
  col *= 1.0 - (1.0 - ramp(-10.0, 34.0, roundBox(p - vec2(0.0, 14.0), TRACK_HALF, TRACK_R))) * mix(0.5, 0.17, th);
  col *= 1.0 - (1.0 - ramp(-2.0, 4.0, roundBox(p - vec2(0.0, 1.5), TRACK_HALF, TRACK_R))) * mix(0.3, 0.08, th);

  // LED'in sahneye taşması
  float toStrip = max(stripDist(p), 0.0);
  col = emit(col, (exp(-toStrip / 18.0) * 0.5 + exp(-toStrip / 85.0) * 0.34) * uLed * 0.6);

  // İz
  if (trackD < 2.0) {
    float ignored;
    vec3 tc = underGlass(p, 0.0, vec2(0.0), ignored);
    float shadow = 1.0 - ramp(-8.0, 20.0 + uLift * 8.0,
        roundBox(p - knob - vec2(0.0, 7.0 + uLift * 5.0), uKH, uKR));
    tc *= 1.0 - shadow * mix(0.6, 0.2, th);
    float rim = 1.0 - ramp(0.0, 1.3, abs(trackD + 0.75));
    float low = ramp(-TRACK_HALF.y * 0.6, TRACK_HALF.y, p.y);
    tc += rim * mix(mix(0.035, 0.09, low), mix(-0.07, 0.07, low), th);
    col = mix(tc, col, ramp(-0.6, 0.6, trackD));
  }

  // Cam düğme
  float knobD = roundBox(p - knob, uKH, uKR);
  if (knobD < 2.0) {
    vec2 e = vec2(0.5, 0.0);
    vec2 n = vec2(
      roundBox(p + e.xy - knob, uKH, uKR) - roundBox(p - e.xy - knob, uKH, uKR),
      roundBox(p + e.yx - knob, uKH, uKR) - roundBox(p - e.yx - knob, uKH, uKR));
    n /= max(length(n), 0.0001);
    float depth = max(-knobD, 0.0);
    float bevel = pow(1.0 - clamp(depth / 26.0, 0.0, 1.0), 2.6);

    vec2 bend = -n * bevel * REFRACT - (p - knob) * 0.055;
    float iconA;
    vec3 seen = underGlass(p + bend, 0.06 + FROST * bevel, n * bevel * 3.2 + (p - knob) * 0.006, iconA);

    float vy = clamp((p.y + uKH.y) / (2.0 * uKH.y), 0.0, 1.0);
    vec3 glass = mix(seen * 0.84 + vec3(0.135) * (1.0 - vy * 0.55),
                     mix(seen, vec3(0.99), 0.5 * (1.0 - iconA * 0.8)), th);

    float toLed = max(stripDist(p), 0.0);
    glass = emit(glass, (exp(-toLed / 24.0) * 0.8 + exp(-toLed / 64.0) * 0.2) * uLed * 0.8);
    glass = emit(glass, exp(-depth / 2.2) * exp(-toLed / 40.0) * uLed * 1.3);

    float ndl = dot(n, normalize(vec2(-0.35, -1.0)));
    glass += pow(max(ndl, 0.0), 2.0) * exp(-depth / 1.25) * mix(0.42, 0.7, th);
    glass += max(ndl, 0.0) * bevel * mix(0.07, 0.16, th);
    glass *= 1.0 - max(-ndl, 0.0) * bevel * mix(0.28, 0.07, th);
    glass += exp(-depth / 0.7) * mix(0.07, 0.12, th);

    col = mix(glass, col, ramp(-0.7, 0.7, knobD));
  }

  // Işık kaynağının kendisi
  float sd = stripDist(p);
  float inStrip = 1.0 - ramp(-0.6, 0.6, sd);
  vec3 ledCol = mix(uLight * 1.05, mix(uLight, vec3(1.0), 0.65), ramp(-0.2, -1.4, sd));
  col = mix(col, ledCol * (0.8 + 0.35 * uLed), inStrip);
  col = emit(col, exp(-max(sd, 0.0) / 4.5) * 0.55 * uLed * (1.0 - inStrip));

  col += (noise(frag * uDpr + uGrain) - 0.5) * 0.022;
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
