import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../data/models/inbox_item.dart';

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
class InboxDetailScreen extends StatelessWidget {
  final InboxItem item;

  const InboxDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
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
          // Kahve: arka plan görseli + koyu overlay
          if (item.fortuneType == FortuneType.coffee) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/images/kahvefalibg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
          SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos for coffee fortune
            if (_hasPhotos) _buildPhotos(context),
            // Tarot: özel başlık (kartlar görselli)
            if (item.fortuneType == FortuneType.tarot)
              _buildTarotHeader(),
            // El Falı: özel bar görünümü (metin alanı yerine geçer)
            if (item.fortuneType == FortuneType.elfali)
              _buildElFaliContent()
            // Rüya Yorumu: özel logo + çerçeveli metin
            else if (item.fortuneType == FortuneType.dream)
              _buildDreamContent(context)
            // I-Ching: koyu altın temalı metin kutusu
            else if (item.fortuneType == FortuneType.iching)
              _buildIChingContent(context)
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
                      _formatDate(item.date),
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
                  // Fortune text — <color=X>...</color> tag'larını renklendir
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
                ],
              ),
            ),
          ],
        ),
          ), // SingleChildScrollView
        ],
      ), // Stack
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

  // ─── Geri Git butonu ─────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
            SizedBox(width: 2),
            Text(
              'Geri Git',
              style: TextStyle(
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

  // ─── I-Ching: koyu altın temalı kutu ────────────────────────────────────────

  Widget _buildIChingContent(BuildContext context) {
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
          Text(
            'I-CHING',
            style: TextStyle(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date),
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
          const SizedBox(height: 24),
          _buildBackButton(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Rüya Yorumu: logo + çerçeveli metin ─────────────────────────────────────

  Widget _buildDreamContent(BuildContext context) {
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
          Text(
            'RÜYA YORUMU',
            style: TextStyle(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.date),
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
          const SizedBox(height: 24),
          _buildBackButton(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── El Falı: bar görünümü ────────────────────────────────────────────────────
  Widget _buildElFaliContent() {
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
            Text(_formatDate(item.date), style: AppTextStyles.inboxMeta),
            const SizedBox(height: 20),
            // Genel değerlendirme
            if (genel.isNotEmpty) ...[
              const Text(
                'Genel Değerlendirme',
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

  String get _isSingleTarotType {
    for (final p in ['Aşk Kartı Falın: ', 'Dilek Kartı Falın: ', 'Şans Kartı Falın: ']) {
      if (item.title.startsWith(p)) return p;
    }
    return '';
  }

  Widget _buildTarotHeader() {
    final singlePrefix = _isSingleTarotType;

    if (singlePrefix.isNotEmpty) {
      // ── Tek kart ──
      final jsonName = item.title.substring(singlePrefix.length).trim();
      final type = singlePrefix.startsWith('Aşk')
          ? 'ask'
          : singlePrefix.startsWith('Dilek')
              ? 'dilek'
              : 'sans';
      final headerLabel = type == 'ask'
          ? 'AŞK KARTIN'
          : type == 'dilek'
              ? 'DİLEK KARTIN'
              : 'ŞANS KARTIN';
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
                _formatDate(item.date),
                textAlign: TextAlign.center,
                style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 116,
                child: _buildCardThumb(jsonName, false, type: type),
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
              'TAROT FALIN',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(letterSpacing: 2.0),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(item.date),
              textAlign: TextAlign.center,
              style: AppTextStyles.inboxMeta.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (cards.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards.map((c) => Expanded(child: _buildCardThumb(c.$1, c.$2))).toList(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Tarot kart görseli oranı: 276 × 480  →  ratio = 276/480 = 0.575
  static const double _cardRatio = 276 / 480;

  Widget _buildCardThumb(String cardName, bool isReversed, {String? type}) {
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
            isReversed ? 'Ters $cardName' : cardName,
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
  /// Başlık formatı: "Tarot Falın: Kart1, Ters Kart2, Kart3"
  List<(String, bool)> _parseTarotCards() {
    const prefix = 'Tarot Falın: ';
    if (!item.title.startsWith(prefix)) return [];
    final part = item.title.substring(prefix.length);
    return part.split(', ').map((s) {
      final trimmed = s.trim();
      if (trimmed.startsWith('Ters ')) {
        return (trimmed.substring(5), true);
      }
      return (trimmed, false);
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photos[i]),
              width: 148,
              height: 148,
              fit: BoxFit.cover,
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

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
