// Kader Kitabı: metin iki sayfaya kelime ortasından bölünmeden, kayıpsız ve sığarak yayılır
// (kısa metinde de sağ sayfa boş kalmaz).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magnus_app/presentation/kaderkitabi/kader_book_scene.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  const page = Size(118, 196); // iPhone 16 Pro'daki sayfa alanı
  const kisa = 'Hayat, her birimizin yaşadığı, hissettiği ve düşündüğü sonsuz sayıda anlardan '
      'oluşur. Her an, kendi içinde bir evren barındırır. Bu anlar, ne kadar küçük veya '
      'önemsiz görünürse görünsün, yaşamın dokusunu oluşturur.';
  final uzun = List.filled(3, kisa).join(' ');

  for (final (ad, metin) in [('kısa', kisa), ('uzun', uzun)]) {
    testWidgets('$ad metin: iki sayfa dolu, kelime bölünmez, kayıp yok, sığar', (t) async {
      await t.runAsync(() => GoogleFonts.pendingFonts([kaderPageStyle(page)]));
      final (sol, sag, olcek) = splitKaderPages(metin, page, TextScaler.noScaling);
      expect(sol, isNotEmpty);
      expect(sag, isNotEmpty, reason: 'sağ sayfa boş kalmasın');
      expect('$sol $sag', metin, reason: 'metin kayıpsız');
      expect(sol.endsWith(' '), isFalse);
      expect(metin.substring(sol.length, sol.length + 1), ' ', reason: 'kelime sınırında');
      for (final p in [sol, sag]) {
        final tp = TextPainter(
          text: TextSpan(text: p, style: kaderPageStyle(page, scale: olcek)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: page.width);
        expect(tp.height, lessThanOrEqualTo(page.height), reason: '$ad sayfaya sığar');
        tp.dispose();
      }
    });
  }
}
