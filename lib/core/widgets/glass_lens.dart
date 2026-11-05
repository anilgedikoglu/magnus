// lib/core/widgets/glass_lens.dart
//
// Sıvı cam kırılması (Impeller) — cam alt bar, seçimde havalanan damla ve cam kaydırıcı
// topuzu tarafından ortak kullanılır. Shader: `shaders/glass_lens.frag` (Instagram iOS 26
// barından ölçülen kenar merceği + [zoom] büyütme). Impeller yoksa
// (`ImageFilter.isShaderFilterSupported` false, Skia) program null döner → çağıran eski
// buzlu cama düşer.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const String _kLensAsset = 'shaders/glass_lens.frag';
Future<ui.FragmentProgram?>? _lensLoad;

/// Yüklenmiş program (yoksa null) — ilk karede buzlu cam görünmesin diye önceden yüklenir.
ui.FragmentProgram? glassLensLoaded;

/// Hata ayıklama / görsel karşılaştırma: true → kırılma kapalı, eski buzlu cam.
bool debugDisableGlassLens = false;

/// Kırılma programını yükle (bir kez). Impeller değilse / hata olursa null.
Future<ui.FragmentProgram?> loadGlassLens() {
  if (!ui.ImageFilter.isShaderFilterSupported) return Future.value();
  return _lensLoad ??= ui.FragmentProgram.fromAsset(_kLensAsset).then<ui.FragmentProgram?>(
    (p) => glassLensLoaded = p,
    onError: (Object _) => null,
  );
}

/// Arka planı `glass_lens.frag` ile büken backdrop. Shader alanın GLOBAL fiziksel
/// dikdörtgenini ister → her boyamada dönüşümden hesaplanır (ölçek dahil; Transform
/// değişince bu nesne de yeniden boyanır).
class GlassLensBackdrop extends SingleChildRenderObjectWidget {
  const GlassLensBackdrop({super.key, required this.program, this.zoom = 1, super.child});

  final ui.FragmentProgram program;

  /// Büyütme (bar 1; havalanan damla / kaydırıcı topuzu >1 → alttaki büyür).
  final double zoom;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderGlassLensBackdrop(program, MediaQuery.devicePixelRatioOf(context), zoom);

  @override
  void updateRenderObject(BuildContext context, RenderGlassLensBackdrop renderObject) {
    renderObject
      ..program = program
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..zoom = zoom;
  }
}

class RenderGlassLensBackdrop extends RenderProxyBox {
  RenderGlassLensBackdrop(this._program, this._dpr, this._zoom);

  // Ölçülen model (bkz. shaders/glass_lens.frag başlığı). Doygunluk = bizim buzlu camla aynı.
  static const double _refract = 0.238;
  static const double _bevel = 0.234;
  static const double _blur = 0.028;
  static const double _saturation = 1.25;

  ui.FragmentProgram _program;
  ui.FragmentShader? _shader;
  double _dpr;

  set devicePixelRatio(double value) {
    if (value == _dpr) return;
    _dpr = value;
    markNeedsPaint();
  }

  double _zoom;
  set zoom(double value) {
    if (value == _zoom) return;
    _zoom = value;
    markNeedsPaint();
  }

  set program(ui.FragmentProgram value) {
    if (identical(value, _program)) return;
    _program = value;
    _shader?.dispose();
    _shader = null;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    // getTransformTo(null) MANTIKSAL global verir (ölçüldü: DPR'yi içermiyor;
    // object.dart RenderView dönüşümünü atlar) → FlutterFragCoord fiziksel olduğundan ×DPR.
    final r = MatrixUtils.transformRect(getTransformTo(null), Offset.zero & size);
    final shader = _shader ??= _program.fragmentShader();
    shader
      ..setFloat(0, 0) // uSize: motor doldurur
      ..setFloat(1, 0)
      ..setFloat(2, r.left * _dpr)
      ..setFloat(3, r.top * _dpr)
      ..setFloat(4, r.width * _dpr)
      ..setFloat(5, r.height * _dpr)
      ..setFloat(6, _refract)
      ..setFloat(7, _bevel)
      ..setFloat(8, _blur)
      ..setFloat(9, _saturation)
      ..setFloat(10, _zoom);
    final l = layer ??= BackdropFilterLayer();
    l.filter = ui.ImageFilter.shader(shader);
    context.pushLayer(l, super.paint, offset);
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    super.dispose();
  }
}
