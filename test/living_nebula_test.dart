// LivingNebulaBackground regresyon testleri (shader gerçekten yüklenip çizmeli).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/widgets/living_nebula.dart';

const _bg = 'assets/images/signinbackground.png';

/// Shader + görsel gerçek asenkron yüklenir → runAsync ile bekle, kare ilerlet.
Future<void> _waitPainted(WidgetTester tester) async {
  for (var i = 0; i < 60 && !LivingNebulaBackground.debugShaderPainted; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => LivingNebulaBackground.debugShaderPainted = false);

  testWidgets('shader yüklenir, gerçekten çizer ve zaman içinde hatasız akar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LivingNebulaBackground(asset: _bg),
    ));
    await _waitPainted(tester);
    expect(LivingNebulaBackground.debugShaderPainted, isTrue,
        reason: 'shader sessizce statik yedeğe düşmemeli');
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isTrue); // animasyon sürüyor
  });

  // Codex incelemesi: debugShaderPainted yalnız drawRect'e ulaşıldığını kanıtlar;
  // siyah çıktı / akmayan uniform ile test sahte geçebilirdi → gerçek piksel kontrolü.
  testWidgets('gerçek piksel: çıktı siyah değil ve zamanla değişiyor',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(200, 400);
    addTearDown(tester.view.reset);
    const key = ValueKey('neb');
    await tester.pumpWidget(const MaterialApp(
      home: RepaintBoundary(key: key, child: LivingNebulaBackground(asset: _bg)),
    ));
    await _waitPainted(tester);
    await tester.pump(const Duration(milliseconds: 800)); // cross-fade bitsin

    Future<Uint8List> grab() async {
      final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final img = await ro.toImage(pixelRatio: 1.0);
        final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        return bd!.buffer.asUint8List();
      });
      return bytes!;
    }

    double mean(Uint8List p) {
      var s = 0;
      for (var i = 0; i < p.length; i += 4) {
        s += p[i] + p[i + 1] + p[i + 2];
      }
      return s / (p.length / 4 * 3);
    }

    double diff(Uint8List x, Uint8List y) {
      var s = 0;
      for (var i = 0; i < x.length; i += 4) {
        s += (x[i] - y[i]).abs() + (x[i + 1] - y[i + 1]).abs() + (x[i + 2] - y[i + 2]).abs();
      }
      return s / (x.length / 4 * 3);
    }

    final a = await grab();
    await tester.pump(const Duration(seconds: 30));
    final b = await grab();
    final m = mean(a), d = diff(a, b);
    // ignore: avoid_print
    print('NEBULA_PIKSEL ortalama=${m.toStringAsFixed(2)} fark30sn=${d.toStringAsFixed(3)}');
    expect(m, greaterThan(4), reason: 'shader çıktısı siyah olmamalı');
    expect(d, greaterThan(0.3), reason: 'nebula zamanla değişmeli (uniform akıyor)');
  });

  testWidgets('reduced-motion: shader çizer ama kare planlamaz (pil dostu)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: LivingNebulaBackground(asset: _bg),
      ),
    ));
    await _waitPainted(tester);
    expect(LivingNebulaBackground.debugShaderPainted, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
