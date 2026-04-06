import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

const _legalText = '''MAGNUS UYGULAMASI – YASAL BİLGİLENDİRME VE SORUMLULUK REDDİ

Magnus uygulamasını kullanmadan önce lütfen aşağıdaki bilgilendirme metnini dikkatlice okuyunuz. Uygulamayı indirmeniz, açmanız veya kullanmaya devam etmeniz halinde aşağıda yer alan tüm şartları açıkça kabul etmiş sayılırsınız.


1. EĞLENCE AMAÇLI KULLANIM

Magnus uygulaması tamamen eğlence, keyif ve vakit geçirme amacıyla geliştirilmiştir. Uygulama içerisinde yer alan fal, tarot, astroloji, burç yorumları ve benzeri tüm içerikler yalnızca eğlence amaçlıdır. Bu içerikler hiçbir şekilde bilimsel, tıbbi, hukuki, finansal veya profesyonel danışmanlık niteliği taşımaz.

Uygulamada geçen "fal", "tarot", "astroloji" ve benzeri tüm kavramlar gerçek hayattaki uygulamalarla birebir örtüşmez, herhangi bir gerçeklik iddiası taşımaz ve tamamen kurgusal/algoritmik içerik üretimi kapsamında değerlendirilir.

Uygulama, geleceğe dair kesin veya doğrulanabilir herhangi bir bilgi vermez, veremez ve böyle bir iddiada bulunmaz. Uygulamada sunulan hiçbir içerik gerçek hayatta dikkate alınmamalı, karar verme sürecinde kullanılmamalıdır.


2. VERİ GİZLİLİĞİ VE KULLANIMI

Magnus uygulaması kapsamında kullanıcıdan talep edilebilecek bilgiler (isim, soyisim, doğum tarihi, doğum saati, doğum yeri, burç bilgileri vb.):

• Hiçbir şekilde sunucularda saklanmaz
• Üçüncü kişilerle paylaşılmaz
• Herhangi bir veri tabanına kaydedilmez
• Reklam, analiz veya başka herhangi bir amaçla kullanılmaz
• Tamamen cihaz üzerinde (lokal) işlenir ve cihaz dışına aktarılmaz

Kullanıcıya ait tüm bilgiler yalnızca uygulama içerisinde anlık işlem amacıyla kullanılır ve kalıcı olarak tutulmaz.


3. SORUMLULUK REDDİ

Magnus uygulaması:

• Gerçek kişiler, kurumlar veya olaylarla herhangi bir bağlantı kurmaz
• Sunulan içeriklerin doğruluğu, kesinliği veya gerçekleşebilirliği konusunda hiçbir garanti vermez
• Kullanıcının uygulama içeriğine dayanarak aldığı hiçbir karar, eylem veya sonuçtan sorumluluk kabul etmez

Uygulamada üretilen tüm içerikler tamamen algoritmik ve eğlence amaçlıdır. Kullanıcı, uygulamayı kullanarak bu durumu bildiğini ve kabul ettiğini beyan eder.


4. HUKUKİ NİTELİK VE UYARI

Magnus uygulaması herhangi bir şekilde falcılık, kehanet veya geleceği bildirme hizmeti sunmaz. Uygulamada yer alan içerikler hukuki anlamda bağlayıcı değildir ve bu şekilde yorumlanamaz.

Hukuki mevzuatlar kapsamında değerlendirildiğinde, uygulama yalnızca eğlence kategorisinde yer almakta olup herhangi bir ticari falcılık, danışmanlık veya yönlendirme hizmeti sunmaz.

Kullanıcı, uygulamada yer alan içeriklerin gerçek hayatta uygulanmaması gerektiğini, yalnızca eğlence kapsamında değerlendirilmesi gerektiğini kabul eder.


5. GERÇEKLİK BEYANI

Uygulamada üretilen tüm içerikler:

• Kurgusaldır
• Rastlantısal veya algoritmik olarak oluşturulur
• Gerçek hayatla birebir örtüşme iddiası taşımaz

Herhangi bir kişi, kurum veya olayla benzerlik tamamen tesadüfi kabul edilir.


6. KABUL BEYANI

Magnus uygulamasını kullanarak kullanıcı:

• Bu metinde yer alan tüm şartları okuduğunu
• Anladığını
• Açıkça kabul ettiğini

beyan etmiş sayılır.

Uygulamayı kullanmaya devam edilmesi, bu şartların tamamının kesin olarak kabul edildiği anlamına gelir.


© Magnus – Tüm hakları saklıdır.''';

class LegalDisclosureScreen extends StatelessWidget {
  const LegalDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Yasal Bilgilendirme',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.navBarActive,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                _legalText,
                style: AppTextStyles.bubbleText.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.65,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          _buildApproveButton(context),
        ],
      ),
    );
  }

  Widget _buildApproveButton(BuildContext context) {
    return Container(
      color: AppColors.navBarBackground,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.bubble1,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bubble1.first.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Okudum, onaylıyorum',
              textAlign: TextAlign.center,
              style: AppTextStyles.answerText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
