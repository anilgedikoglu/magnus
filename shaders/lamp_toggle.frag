// shaders/lamp_toggle.frag
//
// Bildirimler düğmesi: koyu çerçeve + oyuk iz + geniş cam sürgü + LED şerit
// (Anıl, 2026-11-08). Çerçeve ve iz her durumda koyu; sürgünün rengi değişir, LED ışığı ikisine yansır.
// Ölçüler "tasarım pikseli"; ekrana uScale ile ölçeklenir. AÇIK / KAPALI yazısı Dart'ta üste konur.

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uOrigin;    // 0,1   izin merkezi (mantıksal px)
uniform float uScale;    // 2     mantıksal px / tasarım px
uniform float uKx;       // 3     düğme merkezi x (tasarım px, izin merkezine göre)
uniform vec2 uKH;        // 4,5   düğme yarı boyu
uniform float uKR;       // 6     düğme köşe yarıçapı
uniform float uTheme;    // 7     sürgünün rengi: 0 karanlık … 1 aydınlık
uniform float uGrain;    // 8     film greni fazı
uniform float uLed;      // 9     LED şiddeti
uniform float uLift;     // 10    düğme kalkışı (gölge)
uniform vec3 uLight;     // 11-13 LED rengi
uniform float uTheta;    // 14    şeridin düğme çevresindeki açısı
uniform float uDpr;      // 15    fiziksel / mantıksal px
uniform float uTrackW;   // 16    izin yarı eni (tasarım px; ekran enine göre)

out vec4 fragColor;

#define TRACK_HALF vec2(uTrackW, 90.0)
#define OUTER_HALF vec2(uTrackW + 22.0, 112.0)
const float TRACK_R    = 90.0;   // oyuk iz: kapsül
const float OUTER_R    = 112.0;  // dış çerçeve: tam kapsül
const float STRIP_HALF = 0.92;   // şeridin açısal yarı uzunluğu (rad)
const float STRIP_GAP  = 6.5;    // şeridin camdan uzaklığı
const float REFRACT    = 24.0;

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
vec3 emit(vec3 col, float amt, float t) {
  vec3 onDark = col + uLight * amt;
  vec3 onLight = mix(col, uLight * 1.04 + 0.03, clamp(1.0 - exp(-amt * 1.3), 0.0, 0.88));
  return mix(onDark, onLight, t);
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

// Camın altındaki dünya: iz tabanı + LED yıkaması.
vec3 underGlass(vec2 p, float washK) {
  vec3 base = vec3(0.030);
  base *= 1.0 + p.y / TRACK_HALF.y * 0.05;
  float inner = ramp(-14.0, 3.0, roundBox(p - vec2(0.0, 7.0), TRACK_HALF, TRACK_R));
  base *= 1.0 - inner * 0.6;
  return emit(base, floorWash(p) * washK * 0.55, 0.0);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - uOrigin) / uScale;
  float th = uTheme;
  vec2 knob = vec2(uKx, 0.0);

  float outerD = roundBox(p, OUTER_HALF, OUTER_R);
  float alpha = ramp(1.2, -1.2, outerD);
  if (alpha <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Çerçeve: koyu plaka, sağ üstten hafif ışık alır; kenarında ince parlama.
  vec2 uv = (p + OUTER_HALF) / (2.0 * OUTER_HALF);
  float sky = ramp(1.5, 0.0, length((uv - vec2(0.92, -0.08)) * vec2(1.0, 1.25)));
  vec3 col = mix(vec3(0.050), vec3(0.135), sky);
  float outerRim = 1.0 - ramp(0.0, 1.6, abs(outerD + 0.9));
  float outerLow = ramp(-OUTER_HALF.y, OUTER_HALF.y, p.y);
  col += outerRim * mix(0.17, 0.05, outerLow);

  // Oyuk izin çerçeveye düşürdüğü gölge
  float trackD = roundBox(p, TRACK_HALF, TRACK_R);
  col *= 1.0 - (1.0 - ramp(-10.0, 24.0, roundBox(p - vec2(0.0, 10.0), TRACK_HALF, TRACK_R))) * 0.5;
  col *= 1.0 - (1.0 - ramp(-2.0, 4.0, roundBox(p - vec2(0.0, 1.5), TRACK_HALF, TRACK_R))) * 0.3;

  // LED'in çerçeveye yansıması
  float toStrip = max(stripDist(p), 0.0);
  col = emit(col, (exp(-toStrip / 18.0) * 0.5 + exp(-toStrip / 85.0) * 0.34) * uLed * 0.6, 0.0);

  // Oyuk iz (sürgünün oturduğu yer)
  if (trackD < 2.0) {
    vec3 tc = underGlass(p, 1.0);
    float shadow = 1.0 - ramp(-8.0, 20.0 + uLift * 8.0,
        roundBox(p - knob - vec2(0.0, 7.0 + uLift * 5.0), uKH, uKR));
    tc *= 1.0 - shadow * 0.6;
    float rim = 1.0 - ramp(0.0, 1.3, abs(trackD + 0.75));
    float low = ramp(-TRACK_HALF.y * 0.6, TRACK_HALF.y, p.y);
    tc += rim * mix(0.035, 0.09, low);
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
    vec3 seen = underGlass(p + bend, 1.0);

    float vy = clamp((p.y + uKH.y) / (2.0 * uKH.y), 0.0, 1.0);
    // Her iki hâl de koyu cam; açıkken cam amber ışıkla dolar.
    vec3 glass = seen * 0.84 + vec3(0.135) * (1.0 - vy * 0.55);
    glass += uLight * th * (0.20 + 0.16 * (1.0 - vy));

    float toLed = max(stripDist(p), 0.0);
    glass = emit(glass, (exp(-toLed / 24.0) * 0.8 + exp(-toLed / 64.0) * 0.2) * uLed * 0.8, 0.0);
    glass = emit(glass, exp(-depth / 2.2) * exp(-toLed / 40.0) * uLed * 1.3, 0.0);

    float ndl = dot(n, normalize(vec2(-0.35, -1.0)));
    glass += pow(max(ndl, 0.0), 2.0) * exp(-depth / 1.25) * 0.42;
    glass += max(ndl, 0.0) * bevel * 0.07;
    glass *= 1.0 - max(-ndl, 0.0) * bevel * 0.28;
    glass += exp(-depth / 0.7) * 0.07;

    col = mix(glass, col, ramp(-0.7, 0.7, knobD));
  }

  // Işık kaynağının kendisi
  float sd = stripDist(p);
  float inStrip = 1.0 - ramp(-0.6, 0.6, sd);
  vec3 ledCol = mix(uLight * 1.05, mix(uLight, vec3(1.0), 0.65), ramp(-0.2, -1.4, sd));
  col = mix(col, ledCol * (0.8 + 0.35 * uLed), inStrip);
  col = emit(col, exp(-max(sd, 0.0) / 4.5) * 0.55 * uLed * (1.0 - inStrip), 0.0);

  col += (noise(frag * uDpr + uGrain) - 0.5) * 0.022;
  col = clamp(col, 0.0, 1.0);
  fragColor = vec4(col * alpha, alpha);
}
