// Sırayla belirme: tüm öğeler sırayla görünür hâle gelir; pencere sonrası animasyonsuz.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/stagger_in.dart';

void main() {
  testWidgets('üç öğe 380 ms arayla gelir, hepsi sonunda tam görünür', (t) async {
    final since = DateTime.now();
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        for (var i = 0; i < 3; i++)
          StaggerIn(
            index: i,
            since: since,
            step: const Duration(milliseconds: 380),
            child: Text('o$i'),
          ),
      ]),
    ));
    double op(int i) {
      final o = find.ancestor(of: find.text('o$i'), matching: find.byType(Opacity));
      return o.evaluate().isEmpty ? 1.0 : t.widget<Opacity>(o.first).opacity;
    }

    await t.pump(const Duration(milliseconds: 100));
    expect(op(2), 0.0, reason: 'üçüncü henüz başlamadı');
    for (var k = 0; k < 20; k++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(op(0), 1.0);
    expect(op(1), 1.0);
    expect(op(2), 1.0, reason: 'üçüncü de geldi');
  });
}
