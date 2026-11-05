import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'swipe_back.dart';

/// Kenar şeridi genişliği — yalnız [NoEdgeSwipeBack] `edgeOnly` alanlarında kullanılır
/// (orada geri için kaydırma en soldaki bu şeritte başlamalı). Diğer her yerde kaydırma
/// ekranın HERHANGİ bir yerinden başlayabilir (Anıl, 2026-11-05: "daha kolay geri gelinsin").
const double kEdgeSwipeWidth = 28;

/// Geri için gereken yatay mesafe (mevcut [SwipeBack] ile aynı).
const double kEdgeSwipeThreshold = 60;

/// Tüm uygulamada "soldan sağa kaydır = geri" (ekranın her yerinden).
///
/// `MaterialApp.router(builder:)` içinde bir kez sarılır; her sayfaya ayrı eklemek gerekmez.
/// - Yalnız geri gidilebilecek bir sayfa/pencere açıkken çalışır: ana sekmelerde
///   (Ana Menü / Kullanıcı Bilgileri / Gelen Kutusu) ve onboarding'de hiçbir şey yapmaz,
///   uygulamayı kapatmaz, sekme değiştirmez.
/// - Hedef: en üstteki açık pencere (kök navigatörde dialog / alt sayfa), yoksa go_router'ın
///   geri tuşunda seçtiği navigatör (iç içe dal navigatörü dahil). `maybePop` → `PopScope`
///   engellerine uyar; engelliyse gösterge de çıkmaz.
/// - Ekranın kendi [SwipeBack]'i (ör. adım adım geri dönen numeroloji) önceliklidir: aynı
///   dokunuşu o işlerse burada hiçbir şey yapılmaz (çift geri yok).
/// - Kenara değen sürükleme alanları (çark, kazıma) [NoEdgeSwipeBack] ile sarılır.
/// - Raw `Listener` → jest arenasına girmez; ScrollView/PageView/düğmelerle yarışmaz.
/// - Görsel gösterge YOK (Anıl, 2026-11-06: "sağ sol swipe'larda kenardaki şey çıkmasın");
///   eşik geçilince yalnız hafif titreşim.
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    super.key,
    required this.router,
    required this.child,
    this.edgeWidth = kEdgeSwipeWidth,
    this.threshold = kEdgeSwipeThreshold,
  });

  final GoRouter router;
  final Widget child;
  final double edgeWidth;
  final double threshold;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

/// İçindeki dokunuşlarda global kenar-geri jestini kapatır (kenara değen çark/kazıma alanları).
/// Daha derindeki Listener önce çalıştığı için işaret, global izleyiciden önce konur.
class NoEdgeSwipeBack extends StatelessWidget {
  const NoEdgeSwipeBack({super.key, required this.child, this.edgeOnly = false});

  final Widget child;

  /// true → bu alanda geri YALNIZ sol kenar şeridinden ([kEdgeSwipeWidth]) başlayan
  /// kaydırmayla olur (alanın kendi sağa kaydırma işi var: önceki öğe / önceki sekme).
  /// false → bu alanda başlayan dokunuş hiç geri yapmaz (çark, kazıma).
  final bool edgeOnly;

  static int? _blockedPointer;
  static int? _edgeOnlyPointer;

  /// Bu dokunuş tamamen engelli bir alanda mı başladı?
  static bool blocks(int pointer) => _blockedPointer == pointer;

  /// Bu dokunuş "yalnız kenar" alanında mı başladı?
  static bool edgeOnlyFor(int pointer) => _edgeOnlyPointer == pointer;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        if (edgeOnly) {
          _edgeOnlyPointer = e.pointer;
        } else {
          _blockedPointer = e.pointer;
        }
      },
      child: child,
    );
  }
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  final _down = <int>{};
  int? _pointer;
  Offset? _start;
  NavigatorState? _nav;
  Route<dynamic>? _route;
  bool _reached = false;

  /// Yön kesinleşti mi (yatay)? Kesinleşmeden gösterge çıkmaz; önce dikeyse takip biter.
  bool _decided = false;
  static const double _slop = 10;

  void _reset() {
    _pointer = null;
    _start = null;
    _nav = null;
    _route = null;
    _reached = false;
    _decided = false;
  }

  /// Navigatörün en üstteki rotası (hiçbir şeyi kapatmadan okunur).
  static Route<dynamic>? _topOf(NavigatorState nav) {
    Route<dynamic>? top;
    nav.popUntil((r) {
      top = r;
      return true;
    });
    return top;
  }

  /// Geri jestinin kapatacağı navigatör: kökte açık popup varsa o, yoksa go_router'ın
  /// geri tuşu mantığı (kök → en derin pop edebilen dal navigatörü).
  NavigatorState? _activeNavigator() {
    final delegate = widget.router.routerDelegate;
    final root = delegate.navigatorKey.currentState;
    if (root == null) return null;
    NavigatorState? state;
    if (root.canPop()) {
      if (_topOf(root) is PopupRoute) return root;
      state = root;
    }
    final matches = delegate.currentConfiguration.matches;
    if (matches.isEmpty) return state;
    RouteMatchBase walker = matches.last;
    while (walker is ShellRouteMatch) {
      final nav = walker.navigatorKey.currentState;
      if (nav?.canPop() ?? false) state = nav;
      if (walker.matches.isEmpty) break;
      walker = walker.matches.last;
    }
    return state;
  }

  void _onDown(PointerDownEvent e) {
    _down.add(e.pointer);
    if (_down.length > 1) {
      // İkinci parmak: yakınlaştırma / çok parmaklı jest — geri değil.
      _reset();
      return;
    }
    if (NoEdgeSwipeBack.blocks(e.pointer)) return;
    if (NoEdgeSwipeBack.edgeOnlyFor(e.pointer) && e.position.dx >= widget.edgeWidth) return;
    final nav = _activeNavigator();
    if (nav == null) return;
    final route = _topOf(nav);
    if (route == null || route.popDisposition == RoutePopDisposition.doNotPop) return;
    _pointer = e.pointer;
    _start = e.position;
    _nav = nav;
    _route = route;
  }

  void _onMove(PointerMoveEvent e) {
    final start = _start;
    if (e.pointer != _pointer || start == null) return;
    final d = e.position - start;
    // Yön kesinleşene kadar (slop) karar verme; ilk belirgin hareket dikeyse (veya sola)
    // bu bir kaydırmadır → takibi kalıcı bırak (Codex: küçük (0,5) adımı iptali atlatıyordu).
    if (!_decided) {
      if (d.distance < _slop) return;
      if (d.dx <= 0 || d.dy.abs() >= d.dx.abs()) {
        _reset();
        return;
      }
      _decided = true;
    }
    final valid = d.dx > 0 && d.dx.abs() > d.dy.abs() * 1.5;
    final reached = valid && d.dx > widget.threshold;
    if (reached && !_reached) HapticFeedback.selectionClick();
    _reached = reached;
  }

  void _onUp(PointerUpEvent e) {
    _down.remove(e.pointer);
    final start = _start;
    final nav = _nav;
    final route = _route;
    if (e.pointer != _pointer || start == null || nav == null || route == null) return;
    final d = e.position - start;
    final decided = _decided;
    _reset();
    if (!decided) return;
    // Ekranın kendi SwipeBack'i bu dokunuşu işlediyse dokunma.
    if (SwipeBack.wasClaimed(e.pointer)) return;
    if (!(d.dx > widget.threshold && d.dx.abs() > d.dy.abs() * 1.5)) return;
    // Parmak inip kalkana kadar sayfa değiştiyse (otomatik yönlendirme vb.) iptal.
    final now = _activeNavigator();
    if (!identical(now, nav) || !identical(_topOf(nav), route)) return;
    if (nav.userGestureInProgress) return;
    HapticFeedback.heavyImpact(); // her kaydırma hareketinde güçlü titreşim (Anıl)
    nav.maybePop();
  }

  void _onCancel(PointerCancelEvent e) {
    // Android sistem kenar jesti dokunuşu devralınca da buraya düşer.
    _down.remove(e.pointer);
    if (e.pointer == _pointer) _reset();
  }

  /// Bu dokunuş sırasında yatay bir Scrollable sürüklendiyse (liste, PageView) geri yapma.
  bool _onScroll(ScrollNotification n) {
    if (_pointer == null || n.metrics.axis != Axis.horizontal) return false;
    final dragged = (n is ScrollUpdateNotification && n.dragDetails != null) ||
        (n is OverscrollNotification && n.dragDetails != null) ||
        (n is ScrollStartNotification && n.dragDetails != null);
    if (dragged) _reset();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: widget.child,
    ));
  }
}
