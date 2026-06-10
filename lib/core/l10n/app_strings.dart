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

  // ── Home Screen ─────────────────────────────────────────────────────────
  String get mainMenu       => _s('Ana Menü',    'Main Menu');
  String get magnusMainMenu => _s("Magnus'un ana menüsü karşında!", "Magnus's main menu is before you!");
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
  String get sendFortune    => _s('Falımı Gönder ✨', 'Send My Reading ✨');
  String get sending        => _s('Falın gönderiliyor...', 'Your reading is being sent...');
  String get checkingPhotos => _s('Kontrol ediliyor...', 'Checking...');
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
  String get dreamHint         => _s('Rüyanda ne gördün?', 'What did you dream?');
  String get interpret         => _s('Yorumla',            'Interpret');
  String get dreamSending      => _s('Rüyan yorumlanıyor...', 'Your dream is being interpreted...');

  // ── Kehanet Menu ─────────────────────────────────────────────────────────
  String get prophecyTitle     => _s('KEHANET',            'PROPHECY');
  String get selectProphecy    => _s('Bir kehanet seç',    'Choose a prophecy');

  // ── Dert Ortağı ──────────────────────────────────────────────────────────
  String get companionTitle    => _s('DERT ORTAĞI',        'COMPANION');
  String get companionDesc     => _s('Derdini anlat...', 'Tell me what troubles you...');
  String get companionSending  => _s('Dert Ortağın düşünüyor...', 'Your companion is thinking...');

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
  String get legalDisclosure   => _s('Yasal Bilgilendirme', 'Legal Disclosure');
  String get magnusWakingUp    => _s('Magnus canlanıyor...', 'Magnus is waking up...');
}
