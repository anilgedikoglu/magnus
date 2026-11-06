// Kader Kitabı sayfalama (Anıl, 2026-11-06): metin iki sayfaya sığıyorsa tek dengeli açılım
// (dokunma yok); sığmıyorsa küçültmeden birden çok açılıma bölünür (dokununca ilerlenir).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/presentation/kaderkitabi/kader_book_scene.dart';

List<String> _kelimeler(String s) =>
    s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Sayfa boyutu gerçek ekranla uyumlu (390 dp genişlik tipik telefon).
  const bookW = 390 * 0.94;
  final bookH = bookW / kKaderParchmentAspect;
  final page = Size(kKaderLeftPage.width * bookW, kKaderLeftPage.height * bookH);
  const scaler = TextScaler.noScaling;

  testWidgets('kısa metin iki sayfaya sığar → ölçek 1.0 (tek açılım, küçültme yok)',
      (tester) async {
    const kisa = 'Yıldızlar bu gün senin lehine hizalandı. '
        'İçindeki sesi dinle, kapılar açılacak.';
    final (sol, sag, olcek) = splitKaderPages(kisa, page, scaler);
    expect(olcek, 1.0, reason: 'kısa metin küçültülmemeli');
    // Tüm kelimeler korunur (sol+sağ).
    expect(_kelimeler('$sol $sag'), _kelimeler(kisa));
  });

  testWidgets('uzun metin → birden çok açılım, kelime kaybı yok, her sayfa küçültmesiz',
      (tester) async {
    final uzun =
        ('Kader bazen sessiz bir nehir gibi akar ama sen akışın yönünü '
                'değiştirebilecek güçtesin; bu satırları okurken bile içinde bir '
                'kıpırtı var. ' *
            8)
            .trim();

    // Önce: tek açılımda sığmıyor (küçültme gerekir).
    final (_, __, olcek) = splitKaderPages(uzun, page, scaler);
    expect(olcek < 1.0, isTrue, reason: 'uzun metin iki sayfaya sığmamalı');

    // Sayfalama: ≥2 açılım, kelimeler sırayla korunur.
    final spreads = paginateKaderPages(uzun, page, scaler);
    expect(spreads.length, greaterThanOrEqualTo(2));

    final toplanan = <String>[];
    for (final s in spreads) {
      toplanan.addAll(_kelimeler('${s.$1} ${s.$2}'));
    }
    expect(toplanan, _kelimeler(uzun), reason: 'sayfalamada kelime kaybı/karışması olmamalı');

    // Boş açılım olmamalı (en azından sol dolu).
    for (final s in spreads) {
      expect(s.$1.trim().isNotEmpty, isTrue);
    }
  });

  testWidgets('boşluksuz çok uzun metin sayfalamada çökmez', (tester) async {
    final bosluksuz = 'A' * 4000;
    final spreads = paginateKaderPages(bosluksuz, page, scaler);
    expect(spreads, isNotEmpty);
    // Tüm karakterler korunur.
    final birlesik = spreads.map((s) => s.$1 + s.$2).join();
    expect(birlesik.replaceAll(RegExp(r'\s'), ''), bosluksuz);
  });
}
