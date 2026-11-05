import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import 'swipe_back.dart';

/// Kenar şeridi: kaydırma ekranın en solundaki bu kadar mantıksal pikselde başlamalı
/// (iOS yerel jesti 20 pt; kılıflı telefonda rahat olsun diye biraz geniş).
const double kEdgeSwipeWidth = 28;

/// Geri için gereken yatay mesafe (mevcut [SwipeBack] ile aynı).
const double kEdgeSwipeThreshold = 60;

/// Tüm uygulamada "sol kenardan sağa kaydır = geri".
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
/// - Çekerken sol kenarda cam bir geri oku belirir; eşik geçilince altına döner (+ hafif titreşim).
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
  const NoEdgeSwipeBack({super.key, required this.child});

  final Widget child;

  static int? _blockedPointer;

  /// Bu dokunuş engelli bir alanda mı başladı?
  static bool blocks(int pointer) => _blockedPointer == pointer;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _blockedPointer = e.pointer,
      child: child,
    );
  }
}

class _EdgeDrag {
  const _EdgeDrag(this.y, this.dx);
  final double y;

  /// Geçerli (yatay baskın, sağa) çekme miktarı; değilse 0.
  final double dx;
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  final _drag = ValueNotifier<_EdgeDrag?>(null);
  final _down = <int>{};
  int? _pointer;
  Offset? _start;
  NavigatorState? _nav;
  Route<dynamic>? _route;
  bool _reached = false;

  /// Yön kesinleşti mi (yatay)? Kesinleşmeden gösterge çıkmaz; önce dikeyse takip biter.
  bool _decided = false;
  static const double _slop = 10;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _reset() {
    _pointer = null;
    _start = null;
    _nav = null;
    _route = null;
    _reached = false;
    _decided = false;
    _drag.value = null;
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
    if (e.position.dx >= widget.edgeWidth) return;
    if (NoEdgeSwipeBack.blocks(e.pointer)) return;
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
    _drag.value = _EdgeDrag(e.position.dy, valid ? d.dx : 0);
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
    nav.maybePop();
  }

  void _onCancel(PointerCancelEvent e) {
    // Android sistem kenar jesti dokunuşu devralınca da buraya düşer.
    _down.remove(e.pointer);
    if (e.pointer == _pointer) _reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: Stack(
        fit: StackFit.expand,
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          IgnorePointer(
            child: ValueListenableBuilder<_EdgeDrag?>(
              valueListenable: _drag,
              builder: (context, d, _) {
                if (d == null || d.dx <= 0) return const SizedBox.shrink();
                return _EdgeBackHint(
                  y: d.y,
                  progress: (d.dx / widget.threshold).clamp(0.0, 1.0),
                  reached: d.dx > widget.threshold,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sol kenardan kayarak gelen cam geri oku (Gece Grimuarı: cam + kemik, eşikte mum altını).
class _EdgeBackHint extends StatelessWidget {
  const _EdgeBackHint({required this.y, required this.progress, required this.reached});

  final double y;
  final double progress;
  final bool reached;

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final h = mq?.size.height ?? 800;
    final minTop = (mq?.padding.top ?? 0) + 8;
    final maxTop = h - (mq?.padding.bottom ?? 0) - _size - 8;
    final top = maxTop > minTop ? (y - _size / 2).clamp(minTop, maxTop).toDouble() : minTop;
    final t = Curves.easeOutCubic.transform(progress);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned(
          key: const ValueKey('edge-back-hint'),
          left: -_size + (_size + 10) * t,
          top: top,
          child: Opacity(
            opacity: (0.25 + 0.75 * t).clamp(0.0, 1.0),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassTintReading,
                border: Border.all(
                  color: reached ? AppColors.gold : AppColors.rim,
                  width: reached ? 1.2 : 0.8,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x73000000), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: reached ? AppColors.gold : AppColors.bone,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
