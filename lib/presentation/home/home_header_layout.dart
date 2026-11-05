// lib/presentation/home/home_header_layout.dart
//
// Ana menünün iki katmanını bağlayan iki küçük render parçası (Anıl, 2026-11-06:
// "chat ne kadar satıra ihtiyaç duyarsa o esnada o kadar aşağı alsın menüyü"):
//
//  • [HeaderSpacerSliver]: ızgaranın (layer 1) en üstündeki boşluk = layer 2'nin o anki
//    yüksekliği + aralık. Yükseklik bir Animation'dan okunur (her karede yeniden kurulum
//    yok). Layer 2 tamamen kaydırılıp gizlenmişken boy değişirse kaydırma ofseti AYNI
//    miktarda düzeltilir (sliver scrollOffsetCorrection) → kullanıcı aşağıdayken yeni balon
//    gelince menü zıplamaz; başlık görünürken ise menü balonla birlikte yumuşakça iner.
//  • [ScrollFollower]: layer 2'yi ızgaranın kaydırmasıyla yukarı taşır. Ofseti BOYAMA
//    anında okur: düzeltme (bildirim üretmez) yerleşimde uygulandığı için build anında
//    okunan ofset bir kare geride kalır ve gizli başlık birkaç piksel görünürdü.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Izgaranın üst boşluğu: `extra + height.value`. Başlık gizliyken (kaydırma ofseti
/// ≥ eski boşluk − [slack]) boy değişimi kadar ofset düzeltilir.
class HeaderSpacerSliver extends LeafRenderObjectWidget {
  const HeaderSpacerSliver({
    super.key,
    required this.height,
    this.extra = 0,
    this.slack = 0,
  });

  /// Layer 2'nin güvenli alan altındaki (canlı) yüksekliği.
  final ValueListenable<double> height;

  /// Sabit ek: üst güvenli alan + başlık ile ızgara arası aralık.
  final double extra;

  /// Boşluğun alttaki bu kadarı görünse de başlık gizli sayılır (başlık–ızgara aralığı).
  final double slack;

  @override
  RenderHeaderSpacerSliver createRenderObject(BuildContext context) =>
      RenderHeaderSpacerSliver(height: height, extra: extra, slack: slack);

  @override
  void updateRenderObject(BuildContext context, RenderHeaderSpacerSliver renderObject) {
    renderObject
      ..height = height
      ..extra = extra
      ..slack = slack;
  }
}

class RenderHeaderSpacerSliver extends RenderSliver {
  RenderHeaderSpacerSliver({
    required ValueListenable<double> height,
    double extra = 0,
    double slack = 0,
  })  : _height = height,
        _extra = extra,
        _slack = slack;

  ValueListenable<double> _height;
  set height(ValueListenable<double> v) {
    if (identical(v, _height)) return;
    if (attached) {
      _height.removeListener(markNeedsLayout);
      v.addListener(markNeedsLayout);
    }
    _height = v;
    markNeedsLayout();
  }

  double _extra;
  set extra(double v) {
    if (v == _extra) return;
    _extra = v;
    markNeedsLayout();
  }

  double _slack;
  set slack(double v) {
    if (v == _slack) return;
    _slack = v;
    markNeedsLayout();
  }

  /// Son yerleşimdeki boşluk (ilk yerleşimden önce null).
  double? _laidOut;

  double get _extent => _extra + (_height.value < 0 ? 0.0 : _height.value);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _height.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _height.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    final c = constraints;
    final extent = _extent;
    final old = _laidOut;
    _laidOut = extent;
    if (old != null && old != extent && c.scrollOffset > 0 && c.scrollOffset >= old - _slack) {
      // Başlık ekranın üstünde, görünmüyor: altındaki menü yerinde kalsın.
      geometry = SliverGeometry(scrollOffsetCorrection: extent - old);
      return;
    }
    final paintExtent = calculatePaintOffset(c, from: 0, to: extent);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintExtent,
      maxPaintExtent: extent,
      hitTestExtent: paintExtent,
    );
  }
}

/// Çocuğunu [controller]'ın ofseti kadar (0 … kendi yüksekliği) yukarı taşır.
/// Ofset boyama anında okunur; kaydırmada yalnız yeniden boyar (yeniden kurulum yok).
class ScrollFollower extends SingleChildRenderObjectWidget {
  const ScrollFollower({super.key, required this.controller, super.child});

  final ScrollController controller;

  @override
  RenderScrollFollower createRenderObject(BuildContext context) =>
      RenderScrollFollower(controller);

  @override
  void updateRenderObject(BuildContext context, RenderScrollFollower renderObject) {
    renderObject.controller = controller;
  }
}

class RenderScrollFollower extends RenderProxyBox {
  RenderScrollFollower(this._controller);

  ScrollController _controller;
  set controller(ScrollController v) {
    if (identical(v, _controller)) return;
    if (attached) {
      _controller.removeListener(_moved);
      v.addListener(_moved);
    }
    _controller = v;
    _moved();
  }

  /// Kaydırma: yeniden boya + ekran okuyucu koordinatlarını güncelle (Codex: yalnız
  /// boyamak, VoiceOver/TalkBack düğümlerini eski yerde bırakırdı).
  void _moved() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(_moved);
  }

  @override
  void detach() {
    _controller.removeListener(_moved);
    super.detach();
  }

  /// Yukarı kayma miktarı: ofset, [0, kendi yüksekliği] aralığına kırpılır
  /// (üstte esneme olsa da aşağı inmez; tamamen gizlenince durur).
  double get shift {
    if (!_controller.hasClients || !hasSize) return 0;
    final px = _controller.positions.first.pixels;
    return px.clamp(0.0, size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child!, offset.translate(0, -shift));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, -shift),
      position: position,
      hitTest: (r, p) => child!.hitTest(r, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0.0, -shift, 0.0, 1.0);
  }
}

/// Çocuğunun yüksekliğini yerleşimden sonra bildirir (değiştiğinde, kare sonunda).
class HeightReporter extends SingleChildRenderObjectWidget {
  const HeightReporter({super.key, required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderHeightReporter createRenderObject(BuildContext context) => RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(BuildContext context, RenderHeightReporter renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class RenderHeightReporter extends RenderProxyBox {
  RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(h);
    });
  }
}

/// Layer 2 yüksekliği için aşmasız yay (profil kartlarıyla aynı: kütle 1, 180/27).
const SpringDescription kHomeHeaderSpring = SpringDescription(mass: 1, stiffness: 180, damping: 27);
