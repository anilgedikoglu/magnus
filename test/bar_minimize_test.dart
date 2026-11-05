// BarMinimizeLogic: kaydırmayla bar küçülme/büyüme kararı (Instagram iOS 26 ölçümü).
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/bar_minimize.dart';

class _Log {
  final creeps = <double>[];
  final commits = <bool>[];
  final releases = <bool>[];
  late final logic = BarMinimizeLogic(
    onCreep: creeps.add,
    onCommit: commits.add,
    onRelease: releases.add,
  );
}

void main() {
  test('küçülme: ilk 45 pt ölü bölge, sonra sürünme, 72 pt\'de karar', () {
    final l = _Log();
    for (var i = 0; i < 9; i++) {
      l.logic.add(5); // 45 pt
    }
    expect(l.creeps, isEmpty);
    expect(l.commits, isEmpty);
    l.logic.add(13.5); // 58.5 pt → sürünmenin yarısı
    expect(l.creeps.single, closeTo(BarMinimizeLogic.creep / 2, 1e-9));
    l.logic.add(13.5); // 72 pt → karar
    expect(l.commits, [true]);
    expect(l.logic.compact, isTrue);
  });

  test('büyüme: ilk 12 pt ölü bölge (Anıl: çekildiği anda değil), sonra sürünme, 60 pt\'de karar', () {
    final l = _Log();
    l.logic.add(80); // küçült
    expect(l.commits, [true]);
    final before = l.creeps.length;
    l.logic.add(-10); // ölü bölge: kımıldamaz
    expect(l.creeps.length, before);
    l.logic.add(-26); // toplam 36 → (36-12)/48 = yarı yol
    expect(l.creeps.last, closeTo(1 - BarMinimizeLogic.creep * 0.5, 1e-9));
    l.logic.add(-24); // toplam 60 → karar
    expect(l.commits, [true, false]);
    expect(l.logic.compact, isFalse);
  });

  test('yön dönünce biriken yol sıfırlanır ve sürünme geri alınır', () {
    final l = _Log();
    l.logic.add(60); // sürünmede (45..72)
    expect(l.creeps, isNotEmpty);
    l.logic.add(-2); // geri → tam boya dön
    expect(l.releases, [false]);
    l.logic.add(60); // yeniden 0'dan: henüz karar yok
    expect(l.commits, isEmpty);
  });

  test('kaydırma bitince yarım sürünme geri döner, karar kalır', () {
    final l = _Log();
    l.logic.add(50);
    l.logic.release();
    expect(l.releases, [false]);
    expect(l.logic.compact, isFalse);
    l.logic.add(100);
    l.logic.release(); // sürünme yok → olay yok
    expect(l.releases, [false]);
    expect(l.logic.compact, isTrue);
  });

  test('reset (liste başı / sekme değişimi) → tam boy', () {
    final l = _Log();
    l.logic.add(100);
    expect(l.logic.compact, isTrue);
    l.logic.reset();
    expect(l.commits, [true, false]);
    expect(l.logic.compact, isFalse);
    l.logic.reset(); // zaten tam boy → tekrar karar yok
    expect(l.commits, [true, false]);
  });

  test('aynı yöne devam: küçükken yukarı kaydırma birikmez', () {
    final l = _Log();
    l.logic.add(100);
    for (var i = 0; i < 50; i++) {
      l.logic.add(10);
    }
    expect(l.commits, [true]);
    l.logic.add(-59);
    expect(l.commits, [true]); // 59 < 60
    l.logic.add(-1);
    expect(l.commits, [true, false]);
  });
}
