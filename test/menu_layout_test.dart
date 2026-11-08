// Ana menü düzeni (Anıl, 2026-11-05 / 11-08 tek düzen): sıklık sırası, büyük ikon seçimi,
// oturum sabitliği, rastgele düzen seçiminin kalktığı.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/home/menu_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> _ids() => [
      for (var i = 0; i < 27; i++) 'assets/x$i.png',
    ];

void main() {
  setUp(debugResetMenuSession);

  test('sıklık sırası: çoktan aza, eşitlikte varsayılan sıra; Favoriler = ilk 6', () {
    final ids = _ids();
    final counts = {ids[5]: 9, ids[2]: 9, ids[20]: 4, ids[0]: 1};
    final order = orderByUsage(ids, counts);
    expect(order.take(4), [2, 5, 20, 0]); // eşit 9'larda varsayılan sıra (2 < 5)
    expect(order.length, 27);
    expect(order.toSet().length, 27, reason: 'her fal bir kez');
    // Hiç kullanım yoksa varsayılan sıra.
    expect(orderByUsage(ids, const {}), List<int>.generate(27, (i) => i));
  });

  test('kullanım sayımı kalıcı; oturum anlık görüntüsü kullanırken değişmez', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await MenuUsage.increment(p, 'a');
    await MenuUsage.increment(p, 'a');
    final snap = sessionUsage(p);
    expect(snap['a'], 2);
    await MenuUsage.increment(p, 'a');
    expect(MenuUsage.read(p)['a'], 3);
    expect(sessionUsage(p)['a'], 2, reason: 'oturum boyu sabit (her harekette değişmez)');
  });

  test('Diğer Türler: 3 büyük ikon havuzdan, bir önceki açılıştakiler tekrar gelmez', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final ids = [...kBigCapableImages, for (var i = 0; i < 19; i++) 'assets/k$i.png'];
    final first = sessionBigPicks(ids, p);
    expect(first.length, 3);
    for (final i in first) {
      expect(kBigCapableImages, contains(ids[i]));
    }
    expect(sessionBigPicks(ids, p), first, reason: 'oturum boyu aynı');
    debugResetMenuSession();
    final second = sessionBigPicks(ids, p);
    expect(second.toSet().intersection(first.toSet()), isEmpty,
        reason: 'havuz (8) yettiği için önceki 3 tekrar gelmez');
  });

  test('tek düzen: rastgele seçim yok, her açılışta Favoriler + büyük ikonlu düzen', () {
    // Anıl, 2026-11-08: "her seferinde bu set up'la çıksın, randomu kaldırdık".
    debugMenuLayout = null;
    for (var i = 0; i < 200; i++) {
      debugResetMenuSession();
      expect(sessionMenuLayout, MenuLayout.standard);
    }
  });

  test('HD menü görselleri: her ad için dosya var, yalnız eşlenenler HD yola gider', () {
    expect(kMenuHdNames, isNotEmpty);
    for (final n in kMenuHdNames) {
      expect(File('assets/images/menu_hd/$n.jpg').existsSync(), isTrue, reason: n);
    }
    expect(menuImageFor('assets/images/menu/tarot.png'), 'assets/images/menu_hd/tarot.jpg');
    expect(menuImageFor('assets/images/astroloji.png'), 'assets/images/astroloji.png',
        reason: 'kaynağı zaten büyük olan orijinal kalır');
    expect(isBigCapable('assets/images/menu/tarot.png'), isTrue);
    expect(isBigCapable('assets/images/astroloji.png'), isTrue);
  });
}
