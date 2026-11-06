// Codex gece incelemesi: azaltılmış hareket ekran AÇIKKEN değişirse de uyulmalı
// (El Falı avuç taraması sonsuz döner; ayar açılınca durmalı, kapanınca sürmeli).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/presentation/kehanet/el_fali_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  Widget host(bool reduced) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 200, height: 200, child: AvucCizgileri()),
        ),
      );

  testWidgets('El Falı taraması: ekran açıkken azaltılmış hareket açılınca durur, kapanınca sürer',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 12)); // çizim bitti, döngüde
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(host(true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'azaltılmış harekette döngü durmalı');

    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'ayar kapanınca tarama sürmeli');
  });

  testWidgets('El Falı: baştan azaltılmış harekette animasyon yok', (tester) async {
    await tester.pumpWidget(host(true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
