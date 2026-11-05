import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/widgets/filmed_image.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/occult_cards.dart';
import '../../data/models/inbox_item.dart';
import '../../data/services/fortune_service.dart';
import '../../data/providers.dart';

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

/// Fal metninin tamamını gösteren detay ekranı.
/// Unity'deki PanelShowWholeTextManager karşılığı.
///
/// Gece Grimuarı (2026-11): tüm fal türleri TEK okuma dili — filmlenmiş tür arka planı
/// (GrimoireBackdrop), şeffaf başlık, okuma camı (GlassPanel.reading) + EB Garamond
/// okuma metni, mum altını kıl çizgiler. Türe özgü renkler (I-Ching altını, Japon
/// kırmızısı, rüya moru) kalktı; tür kimliği logo + başlıkta kalır.
class InboxDetailScreen extends ConsumerWidget {
  final InboxItem item;

  const InboxDetailScreen({super.key, required this.item});

  /// Türe göre arka plan görseli (yoksa düz mürekkep + atmosfer).
  String? get _bgAsset => switch (item.fortuneType) {
        FortuneType.tarot => 'assets/images/tarot_bg.png',
        FortuneType.coffee => 'assets/images/kahvefalibg.png',
        FortuneType.iching => 'assets/images/falbg/ichingbg.png',
        FortuneType.japonfali => 'assets/images/falbg/omikujibg.png',
        FortuneType.yuzfali => 'assets/images/falbg/yuzfalibg.png',
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Scaffold(
      backgroundColor: AppColors.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        flexibleSpace: const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.70, 1.0],
                colors: [Color(0xF20D0A20), Color(0xCC0D0A20), Color(0x000D0A20)],
              ),
            ),
          ),
        ),
        title: Text(item.fortuneTypeLabel, style: AppTextStyles.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.bone, size: 28),
          tooltip: s.backButton,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GrimoireBackdrop(
        asset: _bgAsset,
        imageSaturation: 0.16,
        imageBrightness: 0.48,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: topPad,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kahve: kullanıcının fincan fotoğrafları
              if (_hasPhotos) _buildPhotos(context),
              // Tarot: özel başlık (kartlar görselli)
              if (item.fortuneType == FortuneType.tarot) _buildTarotHeader(s),
              if (item.fortuneType == FortuneType.elfali)
                _buildElFaliContent(s)
              else if (item.fortuneType == FortuneType.dream)
                _buildRitualContent(context, s,
                    logo: 'assets/images/ruyaozel.png',
                    fallbackIcon: Icons.nightlight_outlined,
                    title: s.dreamTitle)
              else if (item.fortuneType == FortuneType.iching)
                _buildRitualContent(context, s,
                    logo: 'assets/images/ichingikonlogo.png',
                    fallbackIcon: Icons.contrast_rounded,
                    title: s.ichingTitle)
              else if (item.fortuneType == FortuneType.japonfali)
                _buildRitualContent(context, s,
                    logo: 'assets/images/japonfalilogo.png',
                    fallbackIcon: Icons.temple_buddhist_outlined,
                    title: s.japonFaliTitle)
              else
                _buildGenericContent(s),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Genel okuma (kahve, astroloji, motivasyon, durugörü, yüz falı…) ──────────

  Widget _buildGenericContent(AppStrings s) {
    final isTarot = item.fortuneType == FortuneType.tarot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isTarot) ...[
            Center(
              child: Text(
                _formatDate(item.date, s),
                style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const _GoldRule(withStar: true),
            const SizedBox(height: 18),
          ],
          _readingPanel(item.text),
          const SizedBox(height: 32),
          _buildMagnusFooter(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Okuma camı: kıl çizgi + EB Garamond metin + kıl çizgi.
  Widget _readingPanel(String text, {Widget? ornament}) {
    return GlassPanel(
      variant: GlassVariant.reading,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GoldRule(),
          const SizedBox(height: 16),
          RichTextParser.build(text, style: AppTextStyles.reading),
          const SizedBox(height: 16),
          const _GoldRule(),
          if (ornament != null) ...[
            const SizedBox(height: 12),
            Center(child: ornament),
          ],
        ],
      ),
    );
  }

  // ─── Ritüel okumaları (I-Ching, Japon Falı, Rüya): logo + başlık + okuma camı ──

  Widget _buildRitualContent(
    BuildContext context,
    AppStrings s, {
    required String logo,
    required IconData fallbackIcon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          // Renkli tür logosu filmlenir (tanınır ama bağırmaz).
          ColorFiltered(
            colorFilter: ColorFilter.matrix(FilmedImage.matrix(1.0, 1.0)),
            child: Image.asset(
              logo,
              height: 68,
              width: 68,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: AppColors.gold, size: 52),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardLabel.copyWith(
              color: AppColors.gold,
              fontSize: 13,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date, s),
            style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
          ),
          const SizedBox(height: 20),
          _readingPanel(
            item.text,
            ornament: Icon(fallbackIcon, size: 14, color: AppColors.gold.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 28),
          _buildMagnusFooter(),
          const SizedBox(height: 24),
          _buildBackButton(context, s),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Magnus imzası (renkli yazı logosu filmli — mum ışığında silik bir mühür) ───

  Widget _buildMagnusFooter() {
    return Center(
      child: Opacity(
        opacity: 0.85,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(FilmedImage.matrix(1.0, 1.0)),
          child: Image.asset(
            'assets/images/magnusYaziLogoRenkli.PNG',
            height: 84,
            errorBuilder: (_, __, ___) => Text(
              'Magnus',
              style: AppTextStyles.screenTitle.copyWith(color: AppColors.boneDim),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Geri Git butonu (CLAUDE.md standardı) ────────────────────────────────────

  Widget _buildBackButton(BuildContext context, AppStrings s) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 2),
            Text(
              s.backButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── El Falı: hat barları ───────────────────────────────────────────────────

  Widget _buildElFaliContent(AppStrings s) {
    try {
      final data = jsonDecode(item.text) as Map<String, dynamic>;
      final genel = data['genel'] as String? ?? '';
      final hatlarRaw = data['hatlar'] as List? ?? [];
      final hatlar = hatlarRaw.map((h) => h as Map<String, dynamic>).toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                _formatDate(item.date, s),
                style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
              ),
            ),
            const SizedBox(height: 16),
            if (genel.isNotEmpty) ...[
              OccultSectionLabel(s.generalAssessment),
              const SizedBox(height: 10),
              _readingPanel(genel),
              const SizedBox(height: 22),
            ],
            for (final hat in hatlar) ...[
              _buildHat(hat),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            _buildMagnusFooter(),
            const SizedBox(height: 12),
          ],
        ),
      );
    } catch (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: _readingPanel(item.text),
      );
    }
  }

  Widget _buildHat(Map<String, dynamic> hat) {
    final ad = hat['ad'] as String? ?? '';
    final renk = hat['renk'] as String? ?? '';
    final yuzde = (hat['yuzde'] as num?)?.toInt() ?? 0;
    final metin = hat['metin'] as String? ?? '';
    // Hat rengi ANLAM taşır (yapay zekâ seçer) → ton korunur, neon kısılır.
    final color = RichTextParser.mute(_elfaliHatRengi(renk));
    return GlassPanel(
      variant: GlassVariant.reading,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(ad, style: AppTextStyles.value.copyWith(fontSize: 15))),
              Text(
                '%$yuzde',
                style: AppTextStyles.meta.copyWith(
                  color: AppColors.boneDim,
                  fontSize: 13,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (yuzde / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.bone.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                  yuzde < 25 ? AppColors.blood : AppColors.gold),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 12),
          RichTextParser.build(metin, style: AppTextStyles.reading.copyWith(fontSize: 16)),
        ],
      ),
    );
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

  // Başlık formatı (VERİ — Türkçe kalır, yalnız ayrıştırılır):
  //   Klasik: "Tarot Falın: Kart1, Ters Kart2, Kart3"
  //   Tek kart: "Aşk Kartı Falın: JsonKartAdi" / "Dilek Kartı Falın: …" / "Şans Kartı Falın: …"

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(headerLabel, textAlign: TextAlign.center, style: AppTextStyles.screenTitle),
              const SizedBox(height: 6),
              Text(
                _formatDate(item.date, s),
                textAlign: TextAlign.center,
                style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
              ),
              const SizedBox(height: 20),
              SizedBox(width: 124, child: _buildCardThumb(jsonName, jsonName, false, s, type: type)),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Text(s.tarotYourReading, textAlign: TextAlign.center, style: AppTextStyles.screenTitle),
            const SizedBox(height: 6),
            Text(
              _formatDate(item.date, s),
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(fontFeatures: AppTextStyles.tabular),
            ),
            const SizedBox(height: 20),
            if (cards.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards
                    .map((c) => Expanded(child: _buildCardThumb(c.key, c.label, c.reversed, s)))
                    .toList(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Tarot kart görseli oranı: 276 × 480  →  ratio = 276/480 = 0.575
  static const double _cardRatio = 276 / 480;

  /// [cardName] görsel anahtarı (Türkçe ad / JSON adı), [label] ekranda yazan ad.
  Widget _buildCardThumb(String cardName, String label, bool isReversed, AppStrings s,
      {String? type}) {
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
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: _cardRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.rotate(
                      angle: isReversed ? 3.14159 : 0,
                      // Kader açıldı: kartlar filmin biraz üstünde renk taşır (active).
                      child: asset != null
                          ? FilmedImage(asset, active: true, vignette: 0.30,
                              errorBuilder: (_, __, ___) => _cardPlaceholder())
                          : _cardPlaceholder(),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.45), width: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReversed ? s.reversedCard(label) : label,
            style: AppTextStyles.meta.copyWith(fontSize: 11, color: AppColors.boneDim),
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
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.rim),
      ),
      child: const Center(
        child: Icon(Icons.style_outlined, color: AppColors.ash, size: 28),
      ),
    );
  }

  /// Başlıktan kart isimlerini ve ters bilgisini parse eder.
  /// TR: "Tarot Falın: Kart1, Ters Kart2, Kart3"
  /// EN: "Your Tarot Reading: The Moon, Reversed Death, The Star" → görsel için TR ada çevrilir.
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

  Widget _buildPhotos(BuildContext context) {
    final photos = [item.photoPath1, item.photoPath2, item.photoPath3]
        .whereType<String>()
        .toList();

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _viewPhoto(context, photos[i]),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.rim, width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photos[i]),
                width: 148,
                height: 148,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 148,
                  height: 148,
                  child: ColoredBox(color: AppColors.inkCard),
                ),
              ),
            ),
          ),
        ),
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
          ? '${s.monthName(dt.month)} ${dt.day}, ${dt.year} · $hm'
          : '${dt.day} ${s.monthName(dt.month)} ${dt.year} · $hm';
    } catch (_) {
      return isoDate;
    }
  }
}

/// Mum altını kıl çizgi (iki ucu sönen); istenirse ortada küçük dört köşeli yıldız.
class _GoldRule extends StatelessWidget {
  final bool withStar;
  const _GoldRule({this.withStar = false});

  @override
  Widget build(BuildContext context) {
    const line = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x00FF55FF), Color(0x8CFF55FF), Color(0x00FF55FF)],
        ),
      ),
      child: SizedBox(height: 1),
    );
    if (!withStar) return line;
    return Row(
      children: [
        const Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.auto_awesome, size: 12, color: AppColors.gold.withValues(alpha: 0.8)),
        ),
        const Expanded(child: line),
      ],
    );
  }
}
