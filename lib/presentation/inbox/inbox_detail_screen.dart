import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/widgets/bir_tane_daha.dart';
import '../../core/widgets/floating_bar_spacer.dart';
import '../../core/widgets/result_reveal.dart';
import '../home/home_screen.dart' show kHomeBackground;
import '../../data/models/inbox_item.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/providers.dart';
import '../../data/services/fortune_service.dart';

// Kart adı → asset yolu eşleştirmesi (tarot_screen._allCards ile birebir)
const _tarotAssets = <String, String>{
  'Azize': 'assets/images/tarot/Azize.jpg',
  'Budala (Deli)': 'assets/images/tarot/Budala-Deli.jpg',
  'Büyücü': 'assets/images/tarot/Buyucu.jpg',
  'Adalet': 'assets/images/tarot/adalet.jpg',
  'Araba': 'assets/images/tarot/araba.jpg',
  'Asa Altılısı': 'assets/images/tarot/asaaltilisi.jpg',
  'Asa Ası': 'assets/images/tarot/asaasi.jpg',
  'Asa Beşlisi': 'assets/images/tarot/asabeslisi.jpg',
  'Asa Dokuzlusu': 'assets/images/tarot/asadokuzlusu.jpg',
  'Asa Dörtlüsü': 'assets/images/tarot/asadortlusu.jpg',
  'Asa İkilisi': 'assets/images/tarot/asaikilisi.jpg',
  'Asa Kralı': 'assets/images/tarot/asakrali.jpg',
  'Asa Kraliçesi': 'assets/images/tarot/asakralicesi.jpg',
  'Asa Onlusu': 'assets/images/tarot/asaonlusu.jpg',
  'Asa Prensi': 'assets/images/tarot/asaprensi.jpg',
  'Asa Sekizlisi': 'assets/images/tarot/asasekizlisi.jpg',
  'Asa Şövalyesi': 'assets/images/tarot/asasovalyesi.jpg',
  'Asa Üçlüsü': 'assets/images/tarot/asauclusu.jpg',
  'Asa Yedilisi': 'assets/images/tarot/asayedilisi.jpg',
  'Aşıklar': 'assets/images/tarot/asiklar.jpg',
  'Asılan Adam': 'assets/images/tarot/asilanadam.jpg',
  'Ay': 'assets/images/tarot/ay.jpg',
  'Aziz': 'assets/images/tarot/aziz.jpg',
  'Denge': 'assets/images/tarot/denge.jpg',
  'Dünya': 'assets/images/tarot/dunya.jpg',
  'Güç': 'assets/images/tarot/guc.jpg',
  'Güneş': 'assets/images/tarot/gunes.jpg',
  'İmparator': 'assets/images/tarot/imparator.jpg',
  'İmparatoriçe': 'assets/images/tarot/imparatorice.jpg',
  'Kader Çarkı': 'assets/images/tarot/kadercarki.jpg',
  'Kılıç Altılısı': 'assets/images/tarot/kilicaltilisi.jpg',
  'Kılıç Ası': 'assets/images/tarot/kilicasi.jpg',
  'Kılıç Beşlisi': 'assets/images/tarot/kilicbeslisi.jpg',
  'Kılıç Dokuzlusu': 'assets/images/tarot/kilicdokuzlusu.jpg',
  'Kılıç Dörtlüsü': 'assets/images/tarot/kilicdortlusu.jpg',
  'Kılıç İkilisi': 'assets/images/tarot/kilicikilisi.jpg',
  'Kılıç Kralı': 'assets/images/tarot/kilickrali.jpg',
  'Kılıç Kraliçesi': 'assets/images/tarot/kilickralicesi.jpg',
  'Kılıç Onlusu': 'assets/images/tarot/kiliconlusu.jpg',
  'Kılıç Prensi': 'assets/images/tarot/kilicprensi.jpg',
  'Kılıç Sekizlisi': 'assets/images/tarot/kilicsekizlisi.jpg',
  'Kılıç Şövalyesi': 'assets/images/tarot/kilicsovalyesi.jpg',
  'Kılıç Üçlüsü': 'assets/images/tarot/kilicuclusu.jpg',
  'Kılıç Yedilisi': 'assets/images/tarot/kilicyedilisi.jpg',
  'Kupa Altılısı': 'assets/images/tarot/kupaaltilisi.jpg',
  'Kupa Ası': 'assets/images/tarot/kupaasi.jpg',
  'Kupa Beşlisi': 'assets/images/tarot/kupabeslisi.jpg',
  'Kupa Dokuzlusu': 'assets/images/tarot/kupadokuzlusu.jpg',
  'Kupa Dörtlüsü': 'assets/images/tarot/kupadortlusu.jpg',
  'Kupa İkilisi': 'assets/images/tarot/kupaikilisi.jpg',
  'Kupa Kralı': 'assets/images/tarot/kupakrali.jpg',
  'Kupa Kraliçesi': 'assets/images/tarot/kupakralicesi.jpg',
  'Kupa Onlusu': 'assets/images/tarot/kupaonlusu.jpg',
  'Kupa Prensi': 'assets/images/tarot/kupaprensi.jpg',
  'Kupa Sekizlisi': 'assets/images/tarot/kupasekizlisi.jpg',
  'Kupa Şövalyesi': 'assets/images/tarot/kupasovalyesi.jpg',
  'Kupa Üçlüsü': 'assets/images/tarot/kupauclusu.jpg',
  'Kupa Yedilisi': 'assets/images/tarot/kupayedilisi.jpg',
  'Mahkeme': 'assets/images/tarot/mahkeme.jpg',
  'Münzevi': 'assets/images/tarot/munzevi.jpg',
  'Ölüm': 'assets/images/tarot/olum.jpg',
  'Şeytan': 'assets/images/tarot/seytan.jpg',
  'Tılsım Altılısı': 'assets/images/tarot/tilsimaltilisi.jpg',
  'Tılsım Ası': 'assets/images/tarot/tilsimasi.jpg',
  'Tılsım Beşlisi': 'assets/images/tarot/tilsimbeslisi.jpg',
  'Tılsım Dokuzlusu': 'assets/images/tarot/tilsimdokuzlusu.jpg',
  'Tılsım Dörtlüsü': 'assets/images/tarot/tilsimdortlusu.jpg',
  'Tılsım İkilisi': 'assets/images/tarot/tilsimikilisi.jpg',
  'Tılsım Kralı': 'assets/images/tarot/tilsimkrali.jpg',
  'Tılsım Kraliçesi': 'assets/images/tarot/tilsimkralicesi.jpg',
  'Tılsım Onlusu': 'assets/images/tarot/tilsimonlusu.jpg',
  'Tılsım Prensi': 'assets/images/tarot/tilsimprensi.jpg',
  'Tılsım Sekizlisi': 'assets/images/tarot/tilsimsekizlisi.jpg',
  'Tılsım Şövalyesi': 'assets/images/tarot/tilsimsovalyesi.jpg',
  'Tılsım Üçlüsü': 'assets/images/tarot/tilsimuclusu.jpg',
  'Tılsım Yedilisi': 'assets/images/tarot/tilsimyedilisi.jpg',
  'Yıkılan Kule': 'assets/images/tarot/yikilankule.jpg',
  'Yıldız': 'assets/images/tarot/yildiz.jpg',
};

// Şans kartları (tarot2) jsonName → PNG dosya adı
const _sans2file = <String, String>{
  'Adalet': 'Adalet.png', 'Asiklar': 'Asiklar.png', 'AsilanAdam': 'AsilanAdam.png',
  'Ay': 'Ay.png', 'Aziz': 'Aziz.png', 'Azize': 'Azize.png', 'Buyucu': 'Buyucu.png',
  'Deli': 'Budala.png', 'Degnekaltilisi': 'DegnekAltilisi.png', 'Degnekasi': 'DegnekAsi.png',
  'Degnekbeslisi': 'DegnekBeslisi.png', 'Degnekdokuzlusu': 'DegnekDokuzlusu.png',
  'Degnekdortlusu': 'DegnekDortlusu.png', 'Degnekikilisi': 'Degnekikilisi.png',
  'Degnekkrali': 'DegnekKrali.png', 'Degnekkralicesi': 'DegnekKralicesi.png',
  'Degnekonlusu': 'DegnekOnlusu.png', 'Degnekprensi': 'DegnekPrensi.png',
  'Degneksekizlisi': 'DegnekSekizlisi.png', 'Degneksovalyesi': 'DegnekSovalyesi.png',
  'Degnekuclusu': 'DegnekUclusu.png', 'Degnekyedilisi': 'DegnekYedilisi.png',
  'Denge': 'Denge.png', 'Dunya': 'Dunya.png', 'Ermis': 'Ermis.png',
  'Guc': 'Guc.png', 'Gunes': 'Gunes.png', 'Imparator': 'Imparator.png',
  'Imparatorice': 'Imparatorice.png', 'KaderCarki': 'KaderCarki.png',
  'KilicAsi': 'KilicAsi.png', 'Kilicaltilisi': 'KilicAltilisi.png',
  'Kilicbeslisi': 'Kilicbeslisi.png', 'Kilicdokuzlusu': 'KilicDokuzlusu.png',
  'Kilicdortlusu': 'Kilicdortlusu.png', 'Kilicikilisi': 'Kilicikilisi.png',
  'Kilickrali': 'KilicKrali.png', 'Kilickralicesi': 'KilicKralicesi.png',
  'Kiliconlusu': 'KilicOnlusu.png', 'Kilicprensi': 'KilicPrensi.png',
  'Kilicsekizlisi': 'KilicSekizlisi.png', 'Kilicsovalyesi': 'KilicSovalyesi.png',
  'Kilicuclusu': 'Kilicuclusu.png', 'Kilicyedilisi': 'KilicYedilisi.png',
  'KupaAsi': 'KupaAsi.png', 'Kupaaltilisi': 'KupaAltilisi.png',
  'Kupabeslisi': 'KupaBeslisi.png', 'Kupadokuzlusu': 'KupaDokuzlusu.png',
  'Kupadortlusu': 'KupaDortlusu.png', 'Kupaikilisi': 'Kupaikilisi.png',
  'Kupakrali': 'KupaKrali.png', 'Kupakralicesi': 'KupaKralicesi.png',
  'Kupaonlusu': 'KupaOnlusu.png', 'Kupaprensi': 'KupaPrensi.png',
  'Kupasekizlisi': 'KupaSekizlisi.png', 'Kupasovalyesi': 'KupaSovalyesi.png',
  'Kupauclusu': 'KupaUclusu.png', 'Kupayedilisi': 'KupaYedilisi.png',
  'Mahkeme': 'Mahkeme.png', 'Olum': 'Olum.png', 'SavasArabasi': 'SavasArabasi.png',
  'Seytan': 'Seytan.png', 'Tilsimaltilisi': 'Tilsimaltilisi.png',
  'Tilsimasi': 'TilsimAsi.png', 'Tilsimbeslisi': 'TilsimBeslisi.png',
  'Tilsimdokuzlusu': 'Tilsimdokuzlusu.png', 'Tilsimdortlusu': 'Tilsimdortlusu.png',
  'Tilsimikilisi': 'Tilsimikilisi.png', 'Tilsimkrali': 'TilsimKrali.png',
  'Tilsimkralicesi': 'TilsimKralicesi.png', 'Tilsimonlusu': 'Tilsimonlusu.png',
  'Tilsimprensi': 'TilsimPrensi.png', 'Tilsimsekizlisi': 'TilsimSekizlisi.png',
  'Tilsimsovalyesi': 'TilsimSovalyesi.png', 'Tilsimuclusu': 'Tilsimuclusu.png',
  'Tilsimyedilisi': 'Tilsimyedilisi.png', 'YikilanKule': 'YikilanKule.png',
  'Yildiz': 'Yildiz.png',
};

/// Gelen kutusu türü → (fal türü, rota, günlük hak anahtarı).
const _kBirTaneDahaHedefleri = <String, (String, String, String)>{
  'coffee': ('kahve', '/coffee', 'kahve_bugun_tarih'),
  'tarot': ('tarot', '/tarot', 'tarot_bugun_tarih'),
  'iching': ('iching', '/iching', 'iching_bugun_tarih'),
  'japonfali': ('japonfali', '/japonfali', 'japonfali_bugun_tarih'),
};

/// Fal metninin tamamını gösteren detay ekranı.
/// Unity'deki PanelShowWholeTextManager karşılığı.
class InboxDetailScreen extends ConsumerWidget {
  final InboxItem item;

  const InboxDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    return Scaffold(
      // Arka planı olmayan türlerde (motivasyon, olumlama, özlü söz…) zemin gelen
      // kutusu listesiyle AYNI renk olsun (Anıl, 2026-11-06): kHomeBackground #0C0F14.
      backgroundColor: kHomeBackground,
      appBar: AppBar(
        // Başlık bandı gelen kutusu bg'siyle AYNI renk (Anıl: açık lacivert istenmiyor).
        backgroundColor: kHomeBackground,
        title: Text(item.fortuneTypeLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Tarot: arka plan görseli + koyu overlay
          if (item.fortuneType == FortuneType.tarot) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/images/tarot_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
          // Kahve: özel arka plan YOK — diğer türler gibi normal koyu zemin (Anıl).
          // I-Ching: arka plan görseli + koyu overlay
          if (item.fortuneType == FortuneType.iching) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/images/falbg/ichingbg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
          // Japon Falı: arka plan görseli + koyu overlay
          if (item.fortuneType == FortuneType.japonfali) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/images/falbg/omikujibg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
          // Yüz Falı: arka plan görseli + koyu overlay
          if (item.fortuneType == FortuneType.yuzfali) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/images/falbg/yuzfalibg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
          SingleChildScrollView(
        // Sonuç açılışı: belirir + yukarıdan aşağı mürekkep gibi açılır; dokununca tamamlanır.
        child: ResultReveal(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kahve falı: 3 foto üstte yan yana (kaydırmasız, eşit, kırpılı)
            if (item.fortuneType == FortuneType.coffee && _hasPhotos)
              _buildPhotos(context),
            // Yüz falı: tek yüz fotoğrafı üst-orta, çerçeveli + altında ince ayraç
            if (item.fortuneType == FortuneType.yuzfali && item.photoPath1 != null)
              _buildFacePhoto(context),
            // Tarot: özel başlık (kartlar görselli)
            if (item.fortuneType == FortuneType.tarot)
              _buildTarotHeader(s),
            // El Falı: özel bar görünümü (metin alanı yerine geçer)
            if (item.fortuneType == FortuneType.elfali)
              _buildElFaliContent(s)
            // Rüya Yorumu: özel logo + çerçeveli metin
            else if (item.fortuneType == FortuneType.dream)
              _buildDreamContent(context, s)
            // I-Ching: koyu altın temalı metin kutusu
            else if (item.fortuneType == FortuneType.iching)
              _buildIChingContent(context, s)
            // Japon Falı: kırmızı temalı metin kutusu
            else if (item.fortuneType == FortuneType.japonfali)
              _buildJaponFaliContent(context, s)
            else
            // Fortune text
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Non-tarot: sadece tarih (başlık ve süslü ayraç kaldırıldı)
                  if (item.fortuneType != FortuneType.tarot) ...[
                    Text(
                      _formatDate(item.date, s),
                      style: AppTextStyles.inboxMeta,
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Decorative divider — sadece tarot için göster
                  if (item.fortuneType == FortuneType.tarot)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.bubble1.first.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color: AppColors.bubble1.first,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.bubble1.first.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.fortuneType == FortuneType.tarot)
                    const SizedBox(height: 24),
                  // Fortune text — <color=X>...</color> tag'larını renklendir.
                  // Arka planı olan türlerde (kahve/tarot/yüz falı) okunaklı kutu içinde
                  // (I-Ching/Japon gibi) — bg üstünde yazı okunsun (Anıl, 2026-11-06).
                  if (_elseHasBg)
                    _readableBox(
                      accent: _elseBoxAccent,
                      child: RichTextParser.build(
                        item.text,
                        style: AppTextStyles.bubbleText.copyWith(
                          height: 1.85,
                          color: const Color(0xFFEDE6F5),
                          fontSize: 14.5,
                        ),
                      ),
                    )
                  else
                    RichTextParser.build(
                      item.text,
                      style: AppTextStyles.bubbleText.copyWith(
                        height: 1.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 40),
                  // Footer
                  _buildMagnusFooter(),
                  const SizedBox(height: 20),
                  // Okuma bitti: hak kullanıldıysa isteğe bağlı "bir tane daha".
                  if (_kBirTaneDahaHedefleri[item.fortuneTypeKey] case final h?)
                    BirTaneDaha(
                      falTuru: h.$1,
                      hakAnahtari: h.$3,
                      sonra: (c) {
                        // Detay kapanır: fal bitince eski detaya dönülmez, düğme boşa kalmaz.
                        final router = GoRouter.of(c);
                        Navigator.of(c).pop();
                        router.push(h.$2);
                      },
                    ),
                ],
              ),
            ),
            // Yüzen cam bar içeriği kapatmasın
            const FloatingBarSpacer(),
          ],
        )),
          ), // SingleChildScrollView
        ],
      ), // Stack
    );
  }

  // ─── Arka planı olan türlerde genel metin: okunaklı kutu ────────────────────
  // Arka plan görseli olan ve kendi özel kutusu OLMAYAN türler (kahve/tarot/yüz falı) genel
  // metni I-Ching/Japon gibi koyu, çerçeveli bir kutuda gösterir → bg üstünde yazı okunur.
  bool get _elseHasBg =>
      item.fortuneType == FortuneType.tarot ||
      item.fortuneType == FortuneType.coffee ||
      item.fortuneType == FortuneType.yuzfali;

  Color get _elseBoxAccent {
    switch (item.fortuneType) {
      case FortuneType.coffee:
        return const Color(0xFFC9A86B); // kahve: sıcak altın
      case FortuneType.yuzfali:
        return const Color(0xFFFF55FF); // yüz falı: pembe
      case FortuneType.tarot:
        return AppColors.bubble1.first; // tarot: pembe/mor
      default:
        return const Color(0xFF9A86C8); // nötr lavanta
    }
  }

  /// I-Ching kutusuyla aynı aileden: koyu yarı saydam panel + aksan çerçeve + üst/alt ayraç.
  Widget _readableBox({required Widget child, required Color accent}) {
    Widget divider() => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              accent.withValues(alpha: 0.5),
              Colors.transparent,
            ]),
          ),
        );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0A0912).withValues(alpha: 0.86),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: divider()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: child,
          ),
          Padding(padding: const EdgeInsets.only(bottom: 16), child: divider()),
        ],
      ),
    );
  }

  // ─── Magnus footer (renkli logo) ────────────────────────────────────────────

  Widget _buildMagnusFooter() {
    return Center(
      child: Image.asset(
        'assets/images/magnusYaziLogoRenkli.PNG',
        height: 110,
        errorBuilder: (_, __, ___) => Text(
          '✦ Magnus ✦',
          style: AppTextStyles.magnusLabel,
        ),
      ),
    );
  }

  // ─── I-Ching: koyu altın temalı kutu ────────────────────────────────────────

  Widget _buildIChingContent(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        children: [
          // Logo
          Image.asset(
            'assets/images/ichingikonlogo.png',
            height: 72,
            width: 72,
            errorBuilder: (_, __, ___) => const Text('☯', style: TextStyle(fontSize: 56, color: Color(0xFFD4AF37))),
          ),
          const SizedBox(height: 8),
          Consumer(builder: (ctx, ref, _) => Text(
            ref.watch(l10nProvider).ichingTitle,
            style: AppTextStyles.screenTitle.copyWith(color: Color(0xFFD4AF37).withValues(alpha: 0.9)),
          )),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date, s),
            style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 20),
          // Metin kutusu — koyu, altın border
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF080E18).withValues(alpha: 0.90),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFD4AF37).withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: RichTextParser.build(
                    item.text,
                    style: AppTextStyles.bubbleText.copyWith(
                      height: 1.88,
                      color: const Color(0xFFE8E0CC),
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFD4AF37).withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('☯',
                    style: TextStyle(fontSize: 14, color: const Color(0xFFD4AF37).withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildMagnusFooter(),
        ],
      ),
    );
  }

  // ─── Japon Falı: kırmızı temalı kutu ───────────────────────────────────────

  Widget _buildJaponFaliContent(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        children: [
          // Logo
          Image.asset(
            'assets/images/japonfalilogo.png',
            height: 72,
            width: 72,
            errorBuilder: (_, __, ___) => const Text('⛩', style: TextStyle(fontSize: 52, color: Color(0xFFFF4466))),
          ),
          const SizedBox(height: 8),
          Consumer(builder: (ctx, ref, _) => Text(
            ref.watch(l10nProvider).japonFaliTitle,
            style: AppTextStyles.screenTitle.copyWith(color: Color(0xFFFF4466).withValues(alpha: 0.9)),
          )),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date, s),
            style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 20),
          // Metin kutusu — koyu, kırmızı border
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF180008).withValues(alpha: 0.90),
              border: Border.all(
                color: const Color(0xFFFF4466).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4466).withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF4466).withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: RichTextParser.build(
                    item.text,
                    style: AppTextStyles.bubbleText.copyWith(
                      height: 1.88,
                      color: const Color(0xFFFFE0E8),
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF4466).withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('⛩',
                    style: TextStyle(fontSize: 14, color: const Color(0xFFFF4466).withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildMagnusFooter(),
        ],
      ),
    );
  }

  // ─── Rüya Yorumu: logo + çerçeveli metin ─────────────────────────────────────

  Widget _buildDreamContent(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        children: [
          // Logo
          Image.asset(
            'assets/images/ruyaozel.png',
            height: 80,
            width: 80,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.bedtime_rounded,
              color: Color(0xFFA78BFA),
              size: 64,
            ),
          ),
          const SizedBox(height: 8),
          Consumer(builder: (ctx, ref, _) => Text(
            ref.watch(l10nProvider).dreamTitle,
            style: AppTextStyles.screenTitle.copyWith(color: Color(0xFFA78BFA).withValues(alpha: 0.9)),
          )),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date, s),
            style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 20),
          // Çerçeveli metin kutusu
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A0E2E).withValues(alpha: 0.92),
                  const Color(0xFF0D0820).withValues(alpha: 0.92),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Üst ayraç çizgisi
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF9D6EF5).withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: RichTextParser.build(
                    item.text,
                    style: AppTextStyles.bubbleText.copyWith(
                      height: 1.85,
                      color: const Color(0xFFEDE9FE),
                      fontSize: 14.5,
                    ),
                  ),
                ),
                // Alt ayraç çizgisi
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF9D6EF5).withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildMagnusFooter(),
        ],
      ),
    );
  }

  // ─── El Falı: bar görünümü ────────────────────────────────────────────────────
  Widget _buildElFaliContent(AppStrings s) {
    try {
      final data      = jsonDecode(item.text) as Map<String, dynamic>;
      final genel     = data['genel'] as String? ?? '';
      final hatlarRaw = data['hatlar'] as List? ?? [];
      final hatlar    = hatlarRaw.map((h) => h as Map<String, dynamic>).toList();

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(item.date, s), style: AppTextStyles.inboxMeta),
            const SizedBox(height: 20),
            // Genel değerlendirme
            if (genel.isNotEmpty) ...[
              Text(
                s.generalAssessment,
                style: TextStyle(
                  color: Color(0xFFD8B4FE),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                genel,
                style: AppTextStyles.bubbleText.copyWith(height: 1.75),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
            ],
            // Hatlar
            ...hatlar.map((hat) {
              final ad    = hat['ad'] as String;
              final renk  = hat['renk'] as String;
              final yuzde = hat['yuzde'] as int;
              final metin = hat['metin'] as String;
              final color = _elfaliHatRengi(renk);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ad,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '%$yuzde',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: yuzde / 100,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metin,
                      style: AppTextStyles.bubbleText.copyWith(height: 1.65),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            _buildMagnusFooter(),
            const SizedBox(height: 20),
          ],
        ),
      );
    } catch (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(item.text, style: AppTextStyles.bubbleText),
      );
    }
  }

  static Color _elfaliHatRengi(String renk) {
    switch (renk.toLowerCase()) {
      case 'red':       return const Color(0xFFEF4444);
      case 'darkgreen': return const Color(0xFF22C55E);
      case 'green':     return const Color(0xFF4ADE80);
      case 'blue':      return const Color(0xFF60A5FA);
      case 'orange':    return const Color(0xFFFB923C);
      case 'brown':     return const Color(0xFFD97706);
      case 'yellow':    return const Color(0xFFFBBF24);
      case 'pink':      return const Color(0xFFF472B6);
      case 'magenta':   return const Color(0xFFA855F7);
      case 'cyan':      return const Color(0xFF22D3EE);
      default:          return const Color(0xFF818CF8);
    }
  }

  // ─── Tarot başlığı: başlık + tarih + kart görseli(leri) ─────────────────────

  // Başlık formatı:
  //   Klasik: "Tarot Falın: Kart1, Ters Kart2, Kart3"
  //   Tek kart: "Aşk Kartı Falın: JsonKartAdi"
  //             "Dilek Kartı Falın: JsonKartAdi"
  //             "Şans Kartı Falın: JsonKartAdi"

  // TR ve EN başlık önekleri (fortune_service: isEn ? '<Type> Reading: ' : '<Tür> Falın: ').
  static const _singlePrefixes = [
    'Aşk Kartı Falın: ', 'Dilek Kartı Falın: ', 'Şans Kartı Falın: ',
    'Love Card Reading: ', 'Wish Card Reading: ', 'Luck Card Reading: ',
  ];

  String get _isSingleTarotType {
    for (final p in _singlePrefixes) {
      if (item.title.startsWith(p)) return p;
    }
    return '';
  }

  Widget _buildTarotHeader(AppStrings s) {
    final singlePrefix = _isSingleTarotType;

    if (singlePrefix.isNotEmpty) {
      // ── Tek kart ──
      final jsonName = item.title.substring(singlePrefix.length).trim();
      final type = (singlePrefix.startsWith('Aşk') || singlePrefix.startsWith('Love'))
          ? 'ask'
          : (singlePrefix.startsWith('Dilek') || singlePrefix.startsWith('Wish'))
              ? 'dilek'
              : 'sans';
      final headerLabel = type == 'ask'
          ? s.loveCardYours
          : type == 'dilek'
              ? s.wishCardYours
              : s.luckCardYours;
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                headerLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(letterSpacing: 2.0),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(item.date, s),
                textAlign: TextAlign.center,
                style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 116,
                child: _buildCardThumb(jsonName, jsonName, false, s, type: type),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    // ── Klasik 3 kart ──
    final cards = _parseTarotCards();
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              s.tarotYourReading,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(letterSpacing: 2.0),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(item.date, s),
              textAlign: TextAlign.center,
              style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (cards.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards.map((c) => Expanded(child: _buildCardThumb(c.key, c.label, c.reversed, s))).toList(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Tarot kart görseli oranı: 276 × 480  →  ratio = 276/480 = 0.575
  static const double _cardRatio = 276 / 480;

  Widget _buildCardThumb(String cardName, String label, bool isReversed, AppStrings s, {String? type}) {
    // type == null → klasik (tarot/ klasör), aksi halde tek kart türü
    String? asset;
    if (type == null) {
      asset = _tarotAssets[cardName];
    } else {
      final base = cardName == 'Deli' ? 'budala' : cardName.toLowerCase();
      asset = switch (type) {
        'ask'   => 'assets/images/tarot3/${base}a.jpg',
        'dilek' => 'assets/images/tarot4/${base}b.jpg',
        'sans'  => 'assets/images/tarot2/${_sans2file[cardName] ?? '$cardName.png'}',
        _       => null,
      };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: _cardRatio,
              child: Transform.rotate(
                angle: isReversed ? 3.14159 : 0,
                child: asset != null
                    ? Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _cardPlaceholder(),
                      )
                    : _cardPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isReversed ? s.reversedCard(label) : label,
            style: AppTextStyles.inboxMeta.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _cardPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Text('🃏', style: TextStyle(fontSize: 28)),
      ),
    );
  }

  /// Başlıktan kart isimlerini ve ters bilgisini parse eder.
  /// TR: "Tarot Falın: Kart1, Ters Kart2, Kart3"
  /// EN: "Your Tarot Reading: The Moon, Reversed Death" → görsel için TR ada çevrilir.
  List<({String key, String label, bool reversed})> _parseTarotCards() {
    const trPrefix = 'Tarot Falın: ';
    const enPrefix = 'Your Tarot Reading: ';
    final isEnTitle = item.title.startsWith(enPrefix);
    if (!isEnTitle && !item.title.startsWith(trPrefix)) return [];
    final part = item.title.substring(isEnTitle ? enPrefix.length : trPrefix.length);
    return part.split(', ').map((raw) {
      var name = raw.trim();
      var reversed = false;
      for (final r in const ['Ters ', 'Reversed ']) {
        if (name.startsWith(r)) {
          name = name.substring(r.length);
          reversed = true;
          break;
        }
      }
      final key = isEnTitle ? (FortuneService.trCardNameForEn(name) ?? name) : name;
      return (key: key, label: name, reversed: reversed);
    }).toList();
  }

  bool get _hasPhotos =>
      item.photoPath1 != null ||
      item.photoPath2 != null ||
      item.photoPath3 != null;

  // Kahve falı: 3 foto üstte yan yana — yatay kaydırma YOK (Anıl). Row + Expanded +
  // kare (AspectRatio 1) → eşit genişlik, kırpılarak ekrana sığar.
  Widget _buildPhotos(BuildContext context) {
    final photos = [item.photoPath1, item.photoPath2, item.photoPath3]
        .whereType<String>()
        .toList();
    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < photos.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _viewPhoto(context, photos[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      File(photos[i]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Yüz falı: tek yüz fotoğrafı üst-orta, çerçeveli kutuda (kahve stiliyle aynı dil) +
  // altında ince ayraç çizgi.
  Widget _buildFacePhoto(BuildContext context) {
    final path = item.photoPath1!;
    const accent = Color(0xFFFF55FF); // yüz falı pembe teması
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _viewPhoto(context, path),
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(path),
                  width: 148,
                  height: 148,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                accent.withValues(alpha: 0.5),
                Colors.transparent,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate, AppStrings s) {
    try {
      final dt = DateTime.parse(isoDate);
      final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return s.isEn
          ? '${s.monthName(dt.month)} ${dt.day}, ${dt.year}, $hm'
          : '${dt.day} ${s.monthName(dt.month)} ${dt.year}, $hm';
    } catch (_) {
      return isoDate;
    }
  }
}
