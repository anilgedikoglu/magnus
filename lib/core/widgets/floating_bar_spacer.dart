// lib/core/widgets/floating_bar_spacer.dart
//
// Yüzen cam alt bar (Anıl, 2026-11-05: "alt menü kompartmanı tüm app'te her fal türünde
// floating, sabit yerde; alttaki Geri Git tuşları kaldırılacak") TÜM rotaların üstünde
// durur (lib/presentation/shell/floating_bar.dart). Ekran içerikleri en alttaki
// öğelerini barın altında bırakmamak için bu boşluğu kullanır.
//
// Hesap: güvenli alan (bulunduğu yerde kalan) + bar boşluğu + bar yüksekliği + pay.
// SafeArea İÇİNDE kullanılırsa MediaQuery alt dolgusu zaten 0'dır → çift sayılmaz.

import 'package:flutter/widgets.dart';

import 'glass_tab_bar.dart';

/// Yüzen bar için alttan bırakılması gereken yükseklik (bu bağlamda).
double floatingBarInset(BuildContext context, {double extra = 8}) =>
    glassBarBottom(MediaQuery.paddingOf(context).bottom) + kGlassBarHeight + extra;

/// Sütunların en altına konur: içerik yüzen barın altında kalmaz.
class FloatingBarSpacer extends StatelessWidget {
  const FloatingBarSpacer({super.key, this.extra = 8});

  /// Bar üstünde ek nefes payı.
  final double extra;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: floatingBarInset(context, extra: extra));
}
