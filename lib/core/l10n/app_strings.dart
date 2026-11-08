// Magnus App — Localization Strings
// Usage: final s = ref.watch(l10nProvider);
// Then: Text(s.backButton), Text(s.settings), etc.

class AppStrings {
  final String locale;
  AppStrings(this.locale);

  bool get isEn => locale == 'en';
  String _s(String tr, String en) => isEn ? en : tr;

  // ── Common ──────────────────────────────────────────────────────────────
  String get backButton     => _s('Geri Git',    'Go Back');
  String get save           => _s('Kaydet',      'Save');
  String get cancel         => _s('İptal',       'Cancel');
  String get loading        => _s('Yükleniyor…', 'Loading…');
  String get saved          => _s('Kaydedildi',  'Saved');
  String get close          => _s('Kapat',       'Close');
  String get next           => _s('Sonraki',     'Next');
  String get prev           => _s('Önceki',      'Previous');
  String get info           => _s('Bilgi',       'Info');
  String get inbox          => _s('Gelen Kutusu','Inbox');
  String get delete         => _s('Sil',         'Delete');
  String get send           => _s('Gönder',      'Send');
  String get yes            => _s('Evet',        'Yes');
  String get no             => _s('Hayır',       'No');
  String get ok             => _s('Tamam',       'OK');
  String get soon           => _s('Yakında...', 'Coming Soon...');
  // Ana menü boş slotu: "mühürlü kapı" (Gece Grimuarı, 2026-11)
  String get sealed         => _s('Mühürlü',    'Sealed');

  // ── Home Screen ─────────────────────────────────────────────────────────
  String get mainMenu       => _s('Ana Menü',    'Main Menu');
  String get settings       => _s('Ayarlar',     'Settings');
  String get page           => _s('Sayfa',       'Page');
  String get readyInbox     => _s('Hazır',       'Ready');

  // ── Fortune Type Names ───────────────────────────────────────────────────
  String get coffeeFortune  => _s('Kahve Falı',      'Coffee Reading');
  String get tarot          => _s('Tarot',            'Tarot');
  String get astrology      => _s('Astroloji',        'Astrology');
  String get numerology     => _s('Numeroloji',       'Numerology');
  String get durugoru       => _s('Durugörü',         'Clairvoyance');
  String get faceFortune    => _s('Yüz Falı',         'Face Reading');
  String get astroCalendar  => _s('AstroTakvim',      'AstroCalendar');
  String get biorhythm      => _s('Biyoritim',        'Biorhythm');
  String get birthChart     => _s('Doğum Haritası',   'Birth Chart');
  String get motivation     => _s('Motivasyon',       'Motivation');
  String get companion      => _s('Dert Ortağı',      'Companion');
  String get affirmation    => _s('Olumlama',         'Affirmation');
  String get quotes         => _s('Özlü Sözler',      'Wise Words');
  String get bitterTruths   => _s('Acı Gerçekler',    'Bitter Truths');
  String get fatebook       => _s('Kader Kitabı',     'Book of Fate');
  String get prophecy       => _s('Kehanet',          'Prophecy');
  String get intention      => _s('Niyet',            'Intention');
  String get japaneseFortune => _s('Japon Falı',      'Japanese Fortune');
  // 2026-11-05 yeni fal türleri
  String get rabbitFortune   => _s('Tavşan Falı',     'Rabbit Fortune');
  String get whoIsMyDestiny  => _s('Kısmetim Kim?',   'Who Is My Destiny?');
  String get whatIsMyCar     => _s('Arabam Ne?',      'What Is My Car?');
  String get whereIsMyHome   => _s('Evim Neresi?',    'Where Is My Home?');
  String get iching         => _s('I-Ching',          'I-Ching');
  String get loveCompatibility => _s('Aşk Uyumu',     'Love Compatibility');
  String get wheelOfFate    => _s('Kader Çarkı',      'Wheel of Fate');
  String get dreamReading   => _s('Rüya Yorumu',      'Dream Reading');
  String get palmReading    => _s('El Falı',          'Palm Reading');
  String get prophets       => _s('Kahinlere Sor',    'Ask the Oracles');
  String get yana           => _s('Yana',             'Yana');

  // ── Coffee Screen ───────────────────────────────────────────────────────
  String get coffeeTitle    => _s('KAHVE FALI',       'COFFEE READING');
  String get howToSend      => _s('Fincan görsellerini nasıl iletmek istersin?', 'How would you like to send your cup images?');
  String get takePhoto      => _s('Foto Çek',         'Take Photo');
  String get fromFile       => _s('Dosyadan',         'From Gallery');
  String get drinkForMe     => _s('Yerime İç',        'Drink for Me');
  // Gece Grimuarı: buton metninde emoji YOK (eski: '✨').
  String get sendFortune    => _s('Falımı Gönder', 'Send My Reading');
  String photoCount(int n)  => _s('$n/3 Fotoğraf', '$n/3 Photos');
  String get sending        => _s('Falın gönderiliyor...', 'Your reading is being sent...');
  String get checkingPhotos => _s('Kontrol ediliyor...', 'Checking...');
  // ── Foto ön kontrol uyarıları (fincan/el/yüz tanınmazsa) ────────────────
  String get photoNotCup  => _s('Ben bu fotoğraftan bir fincan göremiyorum, karışıklık olmuş olabilir mi?',
      "I can't make out a coffee cup in this photo — could there have been a mix-up?");
  String get photoNotHand => _s('Ben bu fotoğraftan bir el göremiyorum, karışıklık olmuş olabilir mi?',
      "I can't make out a hand in this photo — could there have been a mix-up?");
  String get photoNotFace => _s('Ben bu fotoğraftan bir yüz göremiyorum, karışıklık olmuş olabilir mi?',
      "I can't make out a face in this photo — could there have been a mix-up?");
  String get fortuneSubject => _s('Fal konusu ne olsun?', 'What topic for the reading?');
  String get general        => _s('Genel',            'General');
  String get love           => _s('Aşk',              'Love');
  String get career         => _s('Kariyer',          'Career');
  String get health         => _s('Sağlık',           'Health');

  // ── Motivation Screen ───────────────────────────────────────────────────
  String get motivationTitle   => _s('MOTİVASYON',     'MOTIVATION');
  String get savedToInbox      => _s("Gelen Kutusu'na kaydedildi...", 'Saved to Inbox...');

  // ── Inbox Screen ────────────────────────────────────────────────────────
  String get inboxTitle        => _s('GELEN KUTUSU',   'INBOX');
  // Cam alt bar erişilebilirlik etiketleri (ekranda metin yok; ekran okuyucu için)
  String get tabInbox          => _s('Gelen Kutusu',   'Inbox');
  String get tabInboxUnread    => _s('Gelen Kutusu, okunmamış fal var', 'Inbox, unread reading');
  String get tabInboxPreparing => _s('Gelen Kutusu, hazırlanan fal var', 'Inbox, a reading is being prepared');
  String get tabHome           => _s('Ana Menü',       'Main Menu');
  String get menuFavorites     => _s('Favoriler',      'Favorites');
  String get menuOtherTypes    => _s('Diğer Türler',   'Other Readings');
  String get glassSectionTitle => _s('CAM / GLASS',    'GLASS');
  String get glassTransparency => _s('Alt bar cam saydamlığı', 'Bottom bar glass transparency');
  String get notificationsSection => _s('BİLDİRİMLER', 'NOTIFICATIONS');
  String get notificationsLabel  => _s('Bildirimler', 'Notifications');
  String get notificationsChannel => _s('Fal bildirimleri', 'Reading notifications');
  String get notificationsDenied => _s('Bildirim izni kapalı. Telefon ayarlarından açabilirsin.', 'Notifications are off. You can enable them in your phone settings.');
  String get fortuneReadyTitle   => _s('Falın hazır', 'Your reading is ready');
  String get glassClear        => _s('Şeffaf',         'Clear');
  String get glassTinted       => _s('Renkli',         'Tinted');
  String get clearAll          => _s('Temizle',        'Clear');
  String get inboxEmpty        => _s('BURALAR ÇOK SESSİZ...', 'SO QUIET HERE...');
  String get inboxEmptyDesc    => _s('Okumaya değer bir şey henüz almadın.', "You haven't received anything worth reading yet.");
  String get deleteAllConfirm  => _s('Tüm falları sil?', 'Delete all readings?');
  String get deleteAllSubtitle => _s('Hazırlanmakta olan fallar korunur, geri kalanlar silinir.', 'Readings in preparation will be preserved, the rest will be deleted.');
  String get locked            => _s('Hazırlanıyor...', 'Preparing...');
  String get openInMin         => _s('dk sonra açılır', 'min to open');

  // ── Settings Screen ──────────────────────────────────────────────────────
  String get settingsTitle     => _s('Kullanıcı Bilgileri', 'User Profile');
  String get editProfile       => _s('Profili Düzenle',     'Edit Profile');
  String get birthDate         => _s('Doğum Tarihi',        'Birth Date');
  String get maritalStatus     => _s('Medeni Hal',          'Marital Status');
  String get gender            => _s('Cinsiyet',            'Gender');
  String get occupation        => _s('Meslek',              'Occupation');
  String get birthTime         => _s('Doğum Saati',         'Birth Time');
  String get birthPlace        => _s('Doğum Yeri',          'Birth Place');
  String get zodiac            => _s('Burç',                'Zodiac Sign');
  String get planet            => _s('Gezegen',             'Planet');
  String get rising            => _s('Yükselen',            'Rising');
  String get moonSign          => _s('Ay Burcu',            'Moon Sign');
  String get autoCalc          => _s('✦ Otomatik Hesapla',  '✦ Auto Calculate');
  String get language          => _s('DİL',                 'LANGUAGE');
  String get languageTurkish   => _s('Türkçe',              'Turkish');
  String get languageEnglish   => _s('English',             'English');
  String get settingsSection   => _s('AYARLAR',             'SETTINGS');
  String get warnings          => _s('UYARILAR',            'DISCLAIMERS');
  String get entertainmentOnly => _s(
    '⚠️ Magnus yalnızca eğlence amaçlıdır. İçerikler kurgusal ve sembolik niteliktedir; gerçek kehanet, tıbbi, hukuki veya finansal tavsiye sunmaz.',
    '⚠️ Magnus is for entertainment purposes only. Content is fictional and symbolic; it does not provide real prophecy, medical, legal, or financial advice.',
  );
  String get termsOfUse        => _s('Kullanım Koşulları',  'Terms of Use');
  String get privacyPolicy     => _s('Gizlilik Politikası', 'Privacy Policy');
  String get explicitConsent   => _s('Açık Rıza Metni',     'Explicit Consent');
  String get dangerousActions  => _s('TEHLİKELİ İŞLEMLER', 'DANGEROUS ACTIONS');
  String get resetProfile      => _s('Profili Sıfırla',     'Reset Profile');
  String get deleteAllReadings => _s('Tüm Falları Sil',     'Delete All Readings');
  String get resetProfileConfirm => _s('Profili sıfırla?',  'Reset profile?');
  String get resetProfileDesc  => _s('Tüm bilgilerin silinir ve yeniden tanışma ekranına gidersin.', 'All your info will be deleted and you will return to the onboarding screen.');
  String get resetAction       => _s('Sıfırla',             'Reset');
  String get deleteForever     => _s('Bu işlem geri alınamaz.', 'This action cannot be undone.');
  String get userFallback      => _s('Kullanıcı',               'User');
  String get typeYourName      => _s('Adını yaz...',            'Type your name...');
  String get typeYourAge       => _s('Yaşını yaz...',           'Type your age...');
  String get legalDisclosure   => _s('Yasal Bilgilendirme',     'Legal Disclosure');
  String get readAndApprove    => _s('Okudum, onaylıyorum',     'I have read and I agree');
  String get mainMenuBtn       => _s('Ana Menü',            'Main Menu');
  String get nameLabel         => _s('İsim',                'Name');
  String get nameHint          => _s('Adınız',              'Your name');
  String get chooseAvatar      => _s('Avatar Seç',          'Choose Avatar');
  String get camera            => _s('Kamera',              'Camera');
  String get gallery           => _s('Galeri',              'Gallery');
  String get saveProfile       => _s('Kaydet',              'Save');
  String get timeHint          => _s('SS  :  DD   (örn. 13 : 30)', 'HH  :  MM   (e.g. 13 : 30)');
  String get element           => _s('Element',             'Element');
  String get modality          => _s('Modalite',            'Modality');
  String get polarity          => _s('Polarite',            'Polarity');

  // ── Tarot ────────────────────────────────────────────────────────────────
  String get tarotTitle        => _s('TAROT',               'TAROT');
  String get tarotType         => _s('Tarot Türü',          'Tarot Type');
  String get classicTarot      => _s('Klasik Tarot',        'Classic Tarot');
  String get loveTarot         => _s('Aşk Tarot',          'Love Tarot');
  String get wishTarot         => _s('Dilek Tarot',         'Wish Tarot');
  String get luckTarot         => _s('Şans Tarot',          'Luck Tarot');
  String get drawCard          => _s('Kart Çek',            'Draw a Card');
  String get chooseCard        => _s('Kartını Seç',         'Choose Your Card');
  String get cardMeaning       => _s('Kart Yorumu',         'Card Reading');
  String get sendReading       => _s('Falımı Gönder',       'Send My Reading');
  String get fortuneSending    => _s('Falın gönderiliyor...', 'Your reading is being sent...');
  String get card              => _s('Kart',                'Card');

  // ── Astroloji / Astrology ──────────────────────────────────────────────
  String get astrologyTitle    => _s('GÜNLÜK ASTROLOJİ',   'DAILY ASTROLOGY');
  String get dailyAstrology    => _s('Günlük Astroloji',    'Daily Astrology');

  // ── Biorhythm ──────────────────────────────────────────────────────────
  String get biyoritimTitle    => _s('BİYORİTİM',          'BIORHYTHM');
  String get physical          => _s('Fiziksel',            'Physical');
  String get emotional         => _s('Duygusal',            'Emotional');
  String get intellectual      => _s('Entelektüel',         'Intellectual');
  String get today             => _s('Bugün',               'Today');

  // ── Birth Chart ──────────────────────────────────────────────────────────
  String get birthChartTitle   => _s('DOĞUM HARİTASI',     'BIRTH CHART');

  // ── Numerology ──────────────────────────────────────────────────────────
  String get numerologyTitle   => _s('NUMEROLOJİ',         'NUMEROLOGY');

  // ── Durugörü ──────────────────────────────────────────────────────────
  String get durugoruTitle     => _s('DURUGÖRÜ',           'CLAIRVOYANCE');
  String get durugoruDesc      => _s('Sana bakan gözler var...', 'There are eyes watching over you...');
  String get sendDurugoru      => _s('Durugörüye Gönder',  'Send to Clairvoyance');
  String get durugoruSending   => _s('Durugörü çalışılıyor...', 'Clairvoyance in progress...');

  // ── Dream Reading ────────────────────────────────────────────────────────
  String get dreamTitle        => _s('RÜYA YORUMU',        'DREAM READING');

  // ── Fal detayı (inbox_detail_screen) — 2026-11 Gece Grimuarı ─────────────
  String get tarotYourReading  => _s('TAROT FALIN',        'YOUR TAROT READING');
  String get loveCardYours     => _s('AŞK KARTIN',         'YOUR LOVE CARD');
  String get wishCardYours     => _s('DİLEK KARTIN',       'YOUR WISH CARD');
  String get luckCardYours     => _s('ŞANS KARTIN',        'YOUR LUCK CARD');
  String reversedCard(String name) => _s('Ters $name', 'Reversed $name');
  String get generalAssessment => _s('Genel Değerlendirme', 'Overall Reading');
  static const _monthsTr = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _monthsEn = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
  String monthName(int m) => (isEn ? _monthsEn : _monthsTr)[m.clamp(1, 12)];
  String get dreamHint         => _s('Rüyanda ne gördün?', 'What did you dream?');
  String get interpret         => _s('Yorumla',            'Interpret');
  // Serbest metin rüya yorumu (2026-11-05)
  String get dreamInterpretMine => _s('Rüyamı Yorumla', 'Interpret My Dream');
  String get dreamFreeHint => _s('Rüyanı bir cümleyle anlat, senin için yorumlayayım.\nÖrn: "Rüyamda beyaz bir kedi gördüm"',
      'Describe your dream in a sentence and I will interpret it.\nE.g. "I saw a white cat in my dream"');
  String get dreamInterpreting => _s('Rüyan yorumlanıyor...', 'Your dream is being interpreted...');
  String get dreamResultTitle => _s('Rüya Yorumun', 'Your Dream Reading');
  String get dreamAiConsentTitle => _s('Rüyanı nasıl yorumlayayım?', 'How should I read your dream?');
  String get dreamAiConsentBody => _s(
      'Daha kişisel bir yorum için rüya metnin bir yapay zekâ hizmet sağlayıcısına gönderilir. Profilindeki adın gönderilmez; metinde geçse bile gizlenir. Rüyana başka kişisel bilgi yazmamanı öneririz. İstemezsen yorum cihazında hazırlanır. Yorumlar eğlence amaçlıdır.',
      'For a more personal reading, your dream text is sent to an AI service provider. Your profile name is never sent; it is masked even if you type it. Please avoid adding other personal details. If you prefer, the reading is prepared on your device. Readings are for entertainment.');
  String get dreamAiAccept => _s('Yapay zekâ ile', 'Use AI');
  String get dreamDeviceOnly => _s('Cihazda yorumla', 'On my device');
  String get dreamSending      => _s('Rüyan yorumlanıyor...', 'Your dream is being interpreted...');
  String dreamWhatDidYouSee(String name) => _s('Rüyanda ne gördün, $name?', 'What did you see in your dream, $name?');
  String get searchHint        => _s('Ara…',               'Search…');
  String get noResults         => _s('Sonuç bulunamadı.',  'No results found.');
  String get dreamEvaluating   => _s('Rüyanı değerlendiriyorum...', 'I am evaluating your dream...');
  String dreamInboxTitle(String word) => _s('Rüya: $word', 'Dream: $word');

  // ── Kehanet Menu ─────────────────────────────────────────────────────────
  String get prophecyTitle     => _s('KEHANET',            'PROPHECY');
  String get selectProphecy    => _s('Bir kehanet seç',    'Choose a prophecy');

  // ── Dert Ortağı ──────────────────────────────────────────────────────────
  String get companionTitle    => _s('DERT ORTAĞI',        'COMPANION');
  String get companionDesc     => _s('Derdini anlat...', 'Tell me what troubles you...');
  String get companionSending  => _s('Dert Ortağın düşünüyor...', 'Your companion is thinking...');
  String get dertEnoughToday   => _s('Bugün yeterince dertleştik.', 'We have shared enough troubles for today.');
  String get dertComeTomorrow  => _s('Yarın tekrar gel, her zaman buradayım.', 'Come back tomorrow, I am always here.');
  String dertAskTopic(String name) => name.isEmpty
      ? _s('Derdin neyle ilgili?', 'What is troubling you?')
      : _s('Derdin neyle ilgili $name?', 'What is troubling you, $name?');
  String get dertNoneInCategory => _s('Bu kategori için uygun dert bulunamadı.', 'No matching troubles found for this category.');
  String get dertWhichFits     => _s('Hangisi seni daha iyi anlatıyor?', 'Which one describes you best?');
  String get dertAnalyzing     => _s('Dertlerini çözümlüyorum...', 'I am untangling your troubles...');
  String get dertPatience      => _s('Biraz sabır...', 'A little patience...');
  String get dertMyAdvice      => _s('İşte sana tavsiyelerim!', 'Here is my advice for you!');
  String get thanks            => _s('Teşekkürler', 'Thank you');

  // ── Affirmation ───────────────────────────────────────────────────────────
  String get affirmationTitle  => _s('OLUMLAMA',           'AFFIRMATION');

  // ── Özlü Sözler ──────────────────────────────────────────────────────────
  String get quotesTitle       => _s('ÖZLÜ SÖZLER',        'WISE WORDS');

  // ── Acı Gerçekler ─────────────────────────────────────────────────────────
  String get bitterTruthsTitle => _s('ACI GERÇEKLER',      'BITTER TRUTHS');
  String get bitterTruthsSending => _s('Acı gerçeğin hazırlanıyor...', 'Your bitter truth is being prepared...');

  // ── Kader Kitabı ─────────────────────────────────────────────────────────
  String get fatebookTitle     => _s('KADER KİTABI',       'BOOK OF FATE');
  String get fatebookOpen      => _s('Kitabı Aç',          'Open the Book');

  // ── Kader Çarkı ──────────────────────────────────────────────────────────
  String get wheelOfFateTitle  => _s('KADER ÇARKI',        'WHEEL OF FATE');
  String get spinWheel         => _s('Çarkı Döndür',       'Spin the Wheel');
  String get wheelSending      => _s('Kader çarkı dönüyor...', 'The wheel of fate is spinning...');

  // ── Aşk Uyumu ─────────────────────────────────────────────────────────────
  String get loveCompatTitle   => _s('AŞK UYUMU',          'LOVE COMPATIBILITY');
  String get yourSign          => _s('Senin Burcun',       'Your Sign');
  String get partnerSign       => _s('Partnerinin Burcun', "Partner's Sign");
  String get check             => _s('Uyumu Kontrol Et',   'Check Compatibility');

  // ── I-Ching ────────────────────────────────────────────────────────────
  String get ichingTitle       => _s('I-CHING',            'I-CHING');
  String get ichingDesc        => _s('Sorunuzu zihinsel olarak netleştirin...', 'Mentally clarify your question...');
  String get ichingSending     => _s('I-Ching çalışılıyor...', 'I-Ching in progress...');

  // ── Japon Falı ────────────────────────────────────────────────────────
  String get japonFaliTitle    => _s('JAPON FALI',         'JAPANESE FORTUNE');
  String get japonFaliDesc     => _s('Japonya\'nın mistik kehaneti...', 'Japan\'s mystic oracle...');
  String get japonFaliSending  => _s('Japon Falı çalışılıyor...', 'Japanese Fortune in progress...');

  // ── El Falı ────────────────────────────────────────────────────────────
  String get palmReadingTitle  => _s('EL FALI',            'PALM READING');
  String get palmReadingDesc   => _s('Avucunu kameraya göster', 'Show your palm to the camera');
  String get palmSending       => _s('El falın analiz ediliyor...', 'Your palm reading is being analyzed...');
  String get takePhotoOfPalm   => _s('Avuç İçi Fotoğrafı Çek', 'Take Palm Photo');
  String get fromGallery       => _s('Galeriden Seç',      'Choose from Gallery');

  // ── Yüz Falı ────────────────────────────────────────────────────────────
  String get faceFortuneTilte  => _s('YÜZ FALI',           'FACE READING');
  String get faceFortuneDesc   => _s('Yüzünü kameraya göster', 'Show your face to the camera');
  String get faceSending       => _s('Yüz falın analiz ediliyor...', 'Your face reading is being analyzed...');
  String get whoseFace         => _s('Kimin yüzü?',        'Whose face?');
  String get myFace            => _s('Benim',              'Mine');
  String get partnerFace       => _s('Partnerim',          "My Partner's");

  // ── AstroTakvim ─────────────────────────────────────────────────────────
  String get astroCalendarTitle => _s('ASTRO TAKVİM',      'ASTRO CALENDAR');
  String get transit           => _s('Transit',            'Transit');
  String get moonPhase         => _s('Ay Evreleri',        'Moon Phases');
  String get planets           => _s('Gezegenler',         'Planets');
  String get retrograde        => _s('Retrograd',          'Retrograde');

  // ── Kehanet Characters ────────────────────────────────────────────────
  String get askOracles        => _s('Kahinlere Sor',      'Ask the Oracles');
  String get prophecyOfYana    => _s('Yana\'nın Kehaneti', 'Yana\'s Prophecy');
  String get aboutMe           => _s('Bana Dair',          'About Me');
  String get aboutLife         => _s('Yaşama Dair',        'About Life');
  String get prepare           => _s('Hazırlanıyorum...',  'Preparing...');
  String get readProphecy      => _s('Kehaneti Oku',       'Read Prophecy');

  // ── Tamua ────────────────────────────────────────────────────────────────
  String get tamuaReady        => _s('Geçirdim, hazırım...', "I'm ready...");

  // ── Niyet ─────────────────────────────────────────────────────────────
  String get intentionTitle    => _s('NİYET',              'INTENTION');
  String get scratchToReveal   => _s('Kazımaya Başla',     'Start Scratching');
  String get intentionReady    => _s('Niyet hazır',        'Intention ready');

  // ── Parmak Surtme ────────────────────────────────────────────────────
  String get concentrating     => _s('Odaklanıyorum...', 'Concentrating...');
  String get connectingOracle  => _s('Kahinle bağlantı kuruluyor...', 'Connecting with oracle...');
  String get almostReady       => _s('Neredeyse hazır...', 'Almost ready...');
  String get oracleReady       => _s('Kahin hazır, parmağını çek!', 'Oracle ready, lift your finger!');
  String get touchFinger       => _s('Parmağını dokundur, kaderini okuyacağım', 'Touch your finger, I will read your fate');
  String get done              => _s('Tamamlandı. Başlıyoruz!...', 'Done. Let\'s start!...');

  // ── Onboarding ───────────────────────────────────────────────────────
  String get welcomeToMagnus   => _s('Magnus\'a hoş geldin!', 'Welcome to Magnus!');
  String get typeHere          => _s('Buraya yaz...', 'Type here...');
  String get continueBtn       => _s('Devam', 'Continue');
  String get skip              => _s('Atla', 'Skip');

  // ── Inbox Detail ──────────────────────────────────────────────────────
  String get fortuneDetail     => _s('Fal Detayı', 'Reading Detail');
  String get fortuneDate       => _s('Tarih', 'Date');

  // ── Daily Credit System ───────────────────────────────────────────────
  String get dailyLimitUsed    => _s('Bugünlük hakkın doldu.', 'Your daily limit is used.');
  String get usedToday         => _s('Bugün kullanıldı', 'Used today');
  String get available         => _s('Kullanılabilir', 'Available');

  // ── Admin ─────────────────────────────────────────────────────────────
  String get adminPanel        => _s('Yönetici Paneli', 'Admin Panel');
  String get resetDailyLimits  => _s('Günlük Hakları Sıfırla', 'Reset Daily Limits');
  String get resetDone         => _s('Sıfırlandı!', 'Reset!');

  // ── Tarot Screen ─────────────────────────────────────────────────────
  String get tarotSelectCards  => _s('Kartı yukarı sürükleyerek seç', 'Drag a card up to select');
  String get tarotAllSelected  => _s('Harika! Kartların seçildi ✦', 'Great! Your cards are selected ✦');
  String get tarotSendReading  => _s('Yoruma Gönder ✨', 'Send for Reading ✨');
  String get tarotPickCards    => _s('3 Kart Seç', 'Pick 3 Cards');
  String get tarotSlotPast     => _s('Geçmiş', 'Past');
  String get tarotSlotPresent  => _s('Şimdi', 'Present');
  String get tarotSlotFuture   => _s('Gelecek', 'Future');
  String get errorLabel        => _s('Hata', 'Error');

  // ── Faloya / Maganda / Character Screens ──────────────────────────────
  String get faloyaFocusing    => _s('Faloya geleceğine odaklanıyor...', 'Faloya is focusing on your future...');
  String get magandaFocusing   => _s('Maganda odaklanıyor...', 'Maganda is focusing...');
  String get selectQuestion    => _s('Bir soru seç:', 'Choose a question:');

  // ── Astrology Legacy Screen ──────────────────────────────────────────
  String get zodiacReading     => _s('Burç Yorumu', 'Zodiac Reading');
  String get dailyAstrologyReading => _s('Günlük Astroloji Yorumu', 'Daily Astrology Reading');
  String get howItWorks        => _s('NASIL ÇALIŞIR?', 'HOW IT WORKS');
  String get getMyReading      => _s('Yorumumu Al ✨', 'Get My Reading ✨');
  String get needBirthDateInfo => _s('Burç yorumu için profilinde doğum tarihin olmalı.', 'You need a birth date in your profile for a zodiac reading.');
  String get astroInfo1        => _s('Burç enerjine göre kişiselleştirilmiş günlük yorum alırsın.', 'Get a personalized daily reading based on your zodiac energy.');
  String get astroInfo2        => _s('Yorum gelen kutuna düşer, istediğin zaman okuyabilirsin.', 'Your reading goes to your inbox, read it whenever you want.');
  String get astroInfo3        => _s('Her yorumun farklı: aşk, kariyer, enerji ve daha fazlası.', 'Every reading is different: love, career, energy and more.');

  // ── Inbox Item Card ────────────────────────────────────────────────────
  String get beingInterpreted  => _s('Falın yorumlanıyor…', 'Your reading is being interpreted…');
  String get todayLabel        => _s('Bugün', 'Today');
  String get yesterdayLabel    => _s('Dün', 'Yesterday');
  String get daysAgo           => _s('gün önce', 'days ago');
  String get deleteSwipe       => _s('Sil', 'Delete');

  // ── Chat Widgets ───────────────────────────────────────────────────────
  String get magnusWakingUp    => _s('Magnus canlanıyor...', 'Magnus is waking up...');

  // ── Ana Menü bildirim balonları (fal gönderildi) ────────────────────────
  String _withName(String trBody, String enBody, String name) {
    final n = name.isNotEmpty ? ' $name' : '';
    return _s('$trBody$n.', '$enBody$n.');
  }
  String tarotSentBubble(String name)    => _withName('Tarot falını yorumlamaya başladım', 'I have started interpreting your tarot reading', name);
  String kahveSentBubble(String name)    => _withName('Kahve falını yorumluyorum', 'I am interpreting your coffee reading', name);
  String durugoruSentBubble(String name) => _withName('Durugörün hazırlanıyor', 'Your clairvoyance is being prepared', name);
  String ruyaSentBubble(String name)     => _withName('Rüyanı değerlendirmeye başladım', 'I have started evaluating your dream', name);
  String ichingSentBubble(String name)   => _withName('I-Ching falın hazırlanıyor', 'Your I-Ching reading is being prepared', name);
  String japonSentBubble(String name)    => _withName('Japon Falın değerlendiriliyor', 'Your Japanese Fortune is being evaluated', name);
  String elFaliSentBubble(String name)   => _withName('El falın analiz ediliyor', 'Your palm reading is being analyzed', name);
  String yuzFaliSentBubble(String name)  => _withName('Yüz falın analiz ediliyor', 'Your face reading is being analyzed', name);
  String dailyLimitBubble(String fortuneName, String name) {
    final n = name.isNotEmpty ? ' $name' : '';
    return _s('Günlük $fortuneName hakkın doldu$n.', 'Your daily $fortuneName limit is used$n.');
  }

  /// Fal türü anahtarına göre ekran dilinde görünen ad.
  String fortuneDisplayName(String type) {
    switch (type) {
      case 'motivasyon':  return motivation;
      case 'olumlama':    return affirmation;
      case 'ozlusoz':     return quotes;
      case 'tarot':       return tarot;
      case 'kahve':       return coffeeFortune;
      case 'astroloji':   return astrology;
      case 'kaderkitabi': return fatebook;
      case 'dertortagi':  return companion;
      case 'acigercekler':return bitterTruths;
      case 'numeroloji':  return numerology;
      case 'iching':      return iching;
      case 'japonfali':   return japaneseFortune;
      case 'tavsanfali':  return rabbitFortune;
      case 'kismetim':    return whoIsMyDestiny;
      case 'arabam':      return whatIsMyCar;
      case 'evim':        return whereIsMyHome;
      case 'kadercarki':  return wheelOfFate;
      case 'askuyumu':    return loveCompatibility;
      default:            return type;
    }
  }

  /// Ekrandan 'hazırlanıyor' sinyali gelince gösterilecek mesaj.
  String hazirlaniyorMessage(String type) {
    switch (type) {
      case 'numeroloji': return _s('Numeroloji raporun hazırlanıyor...', 'Your numerology report is being prepared...');
      default:           return _s('Raporun hazırlanıyor...', 'Your report is being prepared...');
    }
  }

  /// Bazı fal türleri için özel günlük-limit mesajı (yoksa null → genel mesaj).
  String? fortuneLimitMessage(String type) {
    switch (type) {
      case 'kaderkitabi': return _s('Kader kitabının bugünkü sayfasını okudun. Yarın yeni bir sayfa açılacak.', "You've read today's page of the book of fate. A new page will open tomorrow.");
      case 'dertortagi':  return _s('Bugün yeterince dertleştik.', "We've shared enough troubles today.");
      case 'acigercekler':return _s('Bugün gerçeklerle yüzleştin.', "You've faced the truths today.");
      case 'kadercarki':  return _s('Günlük Kader Çarkı hakkın doldu.', 'Your daily Wheel of Fate limit is used.');
      case 'askuyumu':    return _s('Günlük Aşk Uyumu hakkın doldu.', 'Your daily Love Compatibility limit is used.');
      case 'tavsanfali':  return _s('Tavşan bugünkü kâğıdını seçti. Yarın tekrar dene.', "The rabbit has picked today's paper. Try again tomorrow.");
      default:            return null;
    }
  }

  // ── Gece Grimuarı l10n borcu (2026-11) ──
  String get exit => _s('Çıkış', 'Exit');

  // Acı Gerçekler
  String get bitterTruthsPreparing => _s('Sana acı ama gerçek bir şeyler anlatmaya hazırlanıyorum...',
      'I am preparing to tell you something bitter but true...');
  String get bitterTruthsLimitTitle => _s('Bugün gerçeklerle yüzleştin.', 'You have faced the truth today.');
  String get bitterTruthsLimitSub => _s('Yarın daha fazlası için tekrar gel.', 'Come back tomorrow for more.');

  // Aşk Uyumu
  String get askUyumuTitle => _s('Aşk Uyumu', 'Love Compatibility');
  String get askUyumuPrompt => _s('Uyumunu merak ettiğin kişinin burcunu seç!',
      'Choose the sign of the person you are curious about!');
  String get askUyumuHold => _s('Basılı tut', 'Press and hold');
  String get askUyumuCalculating => _s('Uyumun hesaplanıyor...', 'Calculating your compatibility...');
  String get askUyumuLoadFail => _s('Sonuçlar yüklenemedi.', 'Results could not be loaded.');
  String get askUyumuOverall => _s('Genel Uyum', 'Overall');
  String askUyumuCategory(String key) => switch (key) {
        'ask' => _s('Aşk', 'Love'),
        'aile' => _s('Aile', 'Family'),
        'maddi' => _s('Maddi', 'Money'),
        'ten' => _s('Ten', 'Intimacy'),
        'vizyon' => _s('Vizyon', 'Vision'),
        'iletisim' => _s('İletişim', 'Communication'),
        _ => key,
      };

  // Astroloji bölüm başlıkları
  String astroSectionLabel(String key) => switch (key) {
        'giris' => _s('Giriş', 'Introduction'),
        'astroyorum' => _s('Astro Yorum', 'Astro Reading'),
        'astrogununsozu' => _s('Günün Sözü', 'Quote of the Day'),
        'astrogununayeti' => _s('Günün Ayeti', 'Verse of the Day'),
        'astrogununhadisi' => _s('Günün Hadisi', 'Hadith of the Day'),
        'astroeglencelibilgi' => _s('Eğlenceli Bilgi', 'Fun Fact'),
        'astrokesif' => _s('Astro Keşif', 'Astro Discovery'),
        'astrogununismi' => _s('Günün İsmi', 'Name of the Day'),
        'astrogununyemegi' => _s('Günün Yemeği', 'Dish of the Day'),
        'astroveda' => _s('Astro Veda', 'Astro Farewell'),
        _ => key,
      };

  // Durugörü
  String get durugoruLimitTitle => _s('Bugünkü durugörü\nhakkın doldu.', "Today's clairvoyance\nlimit is used up.");
  String get durugoruLimitSub => _s('Yarın yeni bir görü açılacak.', 'A new vision opens tomorrow.');
  String get durugoruHowProceed => _s('Nasıl ilerleyelim?', 'How shall we proceed?');
  String get durugoruFocusing => _s('Geleceğine odaklanıyorum...', 'I am focusing on your future...');
  /// [key]: bno | yno | gno
  String durugoruQuestion(String key) => switch (key) {
        'bno' => _s('Bugün neler olacak?', 'What will happen today?'),
        'yno' => _s('Yarın neler olacak?', 'What will happen tomorrow?'),
        'gno' => _s('Gelecekte neler olacak?', 'What will happen in the future?'),
        _ => key,
      };

  // I-Ching / Japon Falı
  String get ichingRolling1 => _s('Zarlar atılıyor,', 'Casting the coins,');
  String get ichingRolling2 => _s('lütfen bekle...', 'please wait...');
  String get japonFaliWorking => _s('Japon Falı çalışılıyor...', 'Reading your Japanese omikuji...');

  // Kader Çarkı
  String get kaderCarkiTitle => _s('Kader Çarkı', 'Wheel of Fate');
  String get kaderCarkiSpinHint => _s('Çarkı parmağınla çevir', 'Spin the wheel with your finger');
  String get kaderCarkiError => _s('Fal hazırlanırken bir sorun oluştu. Lütfen tekrar deneyin.',
      'Something went wrong while preparing your reading. Please try again.');
  /// [key]: alev | hayvan | kure | renk | tas | zar
  String kaderBolmeName(String key) => switch (key) {
        'alev' => _s('Alev', 'Flame'),
        'hayvan' => _s('Hayvan', 'Animal'),
        'kure' => _s('Küre', 'Orb'),
        'renk' => _s('Renkler', 'Colors'),
        'tas' => _s('Taş', 'Stone'),
        'zar' => _s('Zar', 'Dice'),
        _ => key,
      };
  String kaderFalTitle(String name) => _s('$name Falı', '$name Reading');
  String kaderFalComing(String name) => _s('$name Falın geliyor...', 'Your $name reading is coming...');

  // Kader Kitabı
  String get fatebookPageRead => _s('Kader kitabının bugünkü\nsayfasını okudun.',
      "You have read today's page\nof the book of fate.");
  String get fatebookTomorrow => _s('Yarın yeni bir sayfa açılacak.', 'A new page will open tomorrow.');

  // Numeroloji
  String numLabel(int i) => [
        _s('Genel Rapor', 'General Report'),
        _s('Bugüne Dair', 'About Today'),
        _s('Bu Yıla Dair', 'About This Year'),
      ][i];
  String numDesc(int i) => [
        _s('Kalıcı sayılarınla oluşturulan kişilik raporu', 'A personality report built from your lasting numbers'),
        _s('Bugünün enerjisini şekillendiren sayılar', "The numbers shaping today's energy"),
        _s('Bu yıl seni bekleyen döngüler ve fırsatlar', 'The cycles and opportunities awaiting you this year'),
      ][i];
  String get numReportPrompt => _s('Numeroloji raporunu hangisi için istersin?',
      'Which numerology report would you like?');
  String get numPreparing => _s('Hazırlanıyor, biraz bekle...', 'Preparing, wait a moment...');
  String get numCalculating => _s('Hesaplamalar başladı, lütfen bekle...', 'The calculations have begun, please wait...');
  String get numReadAgain => _s('Raporuna tekrar bak →', 'View your report again →');

  // Olumlama / Özlü Söz
  String get affirmationNotFound => _s('Olumlama bulunamadı.', 'No affirmation found.');
  String get quoteNotFound => _s('Özlü söz bulunamadı.', 'No quote found.');
  String get quotesLimitReached => _s('Günlük özlü söz\nhakkın doldu.', 'Your daily quote\nlimit is used up.');
  String get quotesRestarting => _s('Baştan başlıyoruz...', 'Starting over...');

  // ── Astroloji terim çevirileri (kayıtlı Türkçe değer → ekran dili) ───────
  // Profilde burç/gezegen/element vb. Türkçe saklanır; ekranda dile göre çevrilir.
  static const Map<String, String> _zodiacEn = {
    'Koç': 'Aries', 'Boğa': 'Taurus', 'İkizler': 'Gemini',
    'Yengeç': 'Cancer', 'Aslan': 'Leo', 'Başak': 'Virgo',
    'Terazi': 'Libra', 'Akrep': 'Scorpio', 'Yay': 'Sagittarius',
    'Oğlak': 'Capricorn', 'Kova': 'Aquarius', 'Balık': 'Pisces',
  };
  static const Map<String, String> _planetEn = {
    'Güneş': 'Sun', 'Ay': 'Moon', 'Merkür': 'Mercury', 'Venüs': 'Venus',
    'Mars': 'Mars', 'Jüpiter': 'Jupiter', 'Satürn': 'Saturn',
    'Uranüs': 'Uranus', 'Neptün': 'Neptune', 'Plüton': 'Pluto',
  };
  static const Map<String, String> _elementEn = {
    'Ateş': 'Fire', 'Toprak': 'Earth', 'Hava': 'Air', 'Su': 'Water',
  };
  static const Map<String, String> _modalityEn = {
    'Kardinal': 'Cardinal', 'Sabit': 'Fixed', 'Değişken': 'Mutable',
  };
  static const Map<String, String> _polarityEn = {
    'Maskülen': 'Masculine', 'Feminen': 'Feminine',
  };

  /// Türkçe burç adını ekran diline çevirir (örn. 'Terazi' → 'Libra').
  String zodiacName(String? tr) {
    if (tr == null || tr.isEmpty) return '—';
    final clean = tr.replaceAll(RegExp(r'[\s♈♉♊♋♌♍♎♏♐♑♒♓]'), '').trim();
    if (!isEn) return tr;
    return _zodiacEn[clean] ?? _zodiacEn[tr] ?? tr;
  }

  String planetName(String? tr) {
    if (tr == null || tr.isEmpty) return '—';
    if (!isEn) return tr;
    return _planetEn[tr.trim()] ?? tr;
  }

  String elementName(String tr)  => isEn ? (_elementEn[tr]  ?? tr) : tr;
  String modalityName(String tr) => isEn ? (_modalityEn[tr] ?? tr) : tr;
  String polarityName(String tr) => isEn ? (_polarityEn[tr] ?? tr) : tr;

  // ── Profil alan etiketleri (anahtar → ekran dili) ───────────────────────
  // Not: UserProfile.*Label getter'ları Türkçe döner ve VariableReplacer'da
  // kullanıldığı için değiştirilemez. Ekran gösterimi için bu metotları kullan.
  String jobLabelOf(String key) => _label(isEn ? _jobEn : _jobTr, key);
  String maritalLabelOf(String key) => _label(isEn ? _maritalEn : _maritalTr, key);
  String genderLabelOf(String key) => _label(isEn ? _genderEn : _genderTr, key);

  /// Eski / elle yazılmış kayıtlara toleranslı arama: önce birebir, sonra Türkçe
  /// karakterleri sadeleştirilmiş anahtar ('kadın' → 'kadin'), sonra sonek 'u'
  /// ('ozelsektor' → 'ozelsektoru'). Hiçbiri yoksa ham değer (veri kaybolmaz).
  static String _label(Map<String, String> map, String key) {
    final direct = map[key];
    if (direct != null) return direct;
    const tr = {'ı': 'i', 'İ': 'i', 'ş': 's', 'Ş': 's', 'ç': 'c', 'Ç': 'c',
                'ğ': 'g', 'Ğ': 'g', 'ö': 'o', 'Ö': 'o', 'ü': 'u', 'Ü': 'u'};
    final n = key.trim().split('').map((c) => tr[c] ?? c).join().toLowerCase()
        .replaceAll(' ', '');
    return map[n] ?? map['${n}u'] ?? map[n.replaceAll('_', '')] ?? key;
  }

  static const Map<String, String> _jobTr = {
    'evhanimi': 'Ev Hanımı', 'calismiyor': 'Çalışmıyor', 'isariyor': 'İş Arıyor',
    'ogrenci': 'Öğrenci', 'akademisyen': 'Akademisyen', 'kendiisi': 'Kendi İşini Yapıyor',
    'kamusektoru': 'Kamu Sektörü', 'ozelsektoru': 'Özel Sektör', 'emekli': 'Emekli',
    'serbest': 'Serbest Meslek', 'issiz': 'İşsiz',
  };
  static const Map<String, String> _jobEn = {
    'evhanimi': 'Homemaker', 'calismiyor': 'Not Working', 'isariyor': 'Job Seeking',
    'ogrenci': 'Student', 'akademisyen': 'Academic', 'kendiisi': 'Self-Employed',
    'kamusektoru': 'Public Sector', 'ozelsektoru': 'Private Sector', 'emekli': 'Retired',
    'serbest': 'Freelance', 'issiz': 'Unemployed',
  };
  static const Map<String, String> _maritalTr = {
    'iliskisi_yok': 'Bekar', 'platonik': 'Platonik', 'iliski_var': 'İlişkisi Var',
    'flort': 'Flört', 'karisik': 'Karmaşık', 'yeni_ayrilmis': 'Yeni Ayrılmış',
    'nisanli': 'Nişanlı', 'evli': 'Evli', 'ayri_yasiyor': 'Ayrı Yaşıyor',
    'bosanmis': 'Boşanmış', 'dul': 'Dul', 'bekar': 'Bekar',
  };
  static const Map<String, String> _maritalEn = {
    'iliskisi_yok': 'Single', 'platonik': 'Platonic', 'iliski_var': 'In a Relationship',
    'flort': 'Dating', 'karisik': 'Complicated', 'yeni_ayrilmis': 'Recently Separated',
    'nisanli': 'Engaged', 'evli': 'Married', 'ayri_yasiyor': 'Living Apart',
    'bosanmis': 'Divorced', 'dul': 'Widowed', 'bekar': 'Single',
  };
  static const Map<String, String> _genderTr = {
    'kadin': 'Kadın', 'erkek': 'Erkek', 'belirtmek_istemiyorum': 'Belirtilmiyor',
    'lgbt': 'LGBT+',
  };
  static const Map<String, String> _genderEn = {
    'kadin': 'Female', 'erkek': 'Male', 'belirtmek_istemiyorum': 'Not Specified',
    'lgbt': 'LGBTQ+',
  };
}
