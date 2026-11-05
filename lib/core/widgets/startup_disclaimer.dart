import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../l10n/legal_texts.dart';

/// Her açılışta 6 sn gösterilen yasal bilgilendirme (Oyuncu Dükkânı açılışıyla AYNI süre
/// ve düzen: siyah tam ekran, ortalı beyaz metin, ekrana sığacak şekilde ölçeklenir).
/// Süre bitince 400 ms'de söner ve ağaçtan çıkar; o sırada alttaki uygulamaya dokunulamaz.
class StartupDisclaimer extends StatefulWidget {
  const StartupDisclaimer({super.key, required this.child});

  final Widget child;

  /// Oyuncu Dükkânı SplashScreen ile aynı.
  static const Duration showFor = Duration(seconds: 6);

  /// Yalnız test: uygulama testlerinde açılış perdesini atla.
  @visibleForTesting
  static bool debugSkip = false;

  @override
  State<StartupDisclaimer> createState() => _StartupDisclaimerState();
}

class _StartupDisclaimerState extends State<StartupDisclaimer> {
  late bool _visible = !StartupDisclaimer.debugSkip;
  late bool _mounted = _visible;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_visible) {
      _timer = Timer(StartupDisclaimer.showFor, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_mounted)
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            onEnd: () {
              if (!_visible && mounted) setState(() => _mounted = false);
            },
            child: AbsorbPointer(
              child: Consumer(builder: (context, ref, _) {
                final isEn = ref.watch(localeProvider) == 'en';
                return _NoticePage(items: isEn ? kLegalNoticeEn : kLegalNoticeTr);
              }),
            ),
          ),
      ],
    );
  }
}

class _NoticePage extends StatelessWidget {
  const _NoticePage({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(
      color: Colors.white,
      fontSize: 12.5,
      height: 1.4,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    const body = TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5, height: 1.4);
    final spans = <InlineSpan>[];
    for (var i = 0; i < items.length; i++) {
      final (title, text) = items[i];
      if (i == 0) {
        spans.add(TextSpan(text: '$title\n\n', style: head.copyWith(fontSize: 15, letterSpacing: 1.2)));
        continue;
      }
      spans.add(TextSpan(text: '$title\n', style: head));
      spans.add(TextSpan(text: '$text${i == items.length - 1 ? '' : '\n\n'}', style: body));
    }
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 340,
                child: Text.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
