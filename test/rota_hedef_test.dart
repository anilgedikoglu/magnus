// MagnusRotaGozlemci: fal rotası kapanınca hedef (menü mü?) bildirilir; geçiş reklamı buna bakar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/magnus_ses/magnus_rota_gozlemci.dart';

void main() {
  testWidgets('geri dönüşte sonHedefRota /home', (t) async {
    final gozlemci = MagnusRotaGozlemci();
    String? kapanan;
    MagnusRotaGozlemci.cikti = (tur, sure) => kapanan = tur;
    addTearDown(() => MagnusRotaGozlemci.cikti = null);
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      navigatorObservers: [gozlemci],
      initialRoute: '/home',
      onGenerateRoute: (s) => MaterialPageRoute(settings: s, builder: (_) => Text(s.name ?? '')),
    ));
    nav.currentState!.pushNamed('/coffee');
    await t.pumpAndSettle();
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(kapanan, 'kahve');
    expect(MagnusRotaGozlemci.sonHedefRota, '/home');
  });
}
