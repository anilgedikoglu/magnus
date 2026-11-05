import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/tarot/deck_deal.dart';

void main() {
  test('dağıtım: başta herkes destede, sonda herkes yerinde, sırayla gelir', () {
    for (var i = 0; i < 78; i++) {
      expect(DeckDeal.progress(i, 0), 0);
      expect(DeckDeal.progress(i, 1), closeTo(1, 1e-9));
    }
    // Ortada: soldaki kart sağdakinden önde, ilerleme zamanla azalmaz.
    expect(DeckDeal.progress(1, 0.4), greaterThan(DeckDeal.progress(10, 0.4)));
    for (var i = 0; i < 20; i++) {
      var last = 0.0;
      for (var k = 0; k <= 100; k++) {
        final p = DeckDeal.progress(i, k / 100);
        expect(p, greaterThanOrEqualTo(last - 1e-12));
        last = p;
      }
    }
  });
}
