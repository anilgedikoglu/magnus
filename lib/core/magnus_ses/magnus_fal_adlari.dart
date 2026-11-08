// lib/core/magnus_ses/magnus_fal_adlari.dart
//
// Fal türlerinin Magnus'un cümlelerinde kullanılan çekimli adları ve rota/gelen kutusu eşlemeleri.

class FalAdi {
  const FalAdi(this.yalin, this.belirtme, this.yonelme, this.ayrilma, this.tamlayan, this.en);
  final String yalin; // Kahve Falı
  final String belirtme; // Kahve Falını
  final String yonelme; // Kahve Falına
  final String ayrilma; // Kahve Falından
  final String tamlayan; // Kahve Falının
  final String en;
}

const Map<String, FalAdi> kFalAdlari = {
  'kahve': FalAdi('Kahve Falı', 'Kahve Falını', 'Kahve Falına', 'Kahve Falından', 'Kahve Falının', 'Coffee Reading'),
  'tarot': FalAdi('Tarot', 'Tarotu', 'Tarota', 'Tarottan', 'Tarotun', 'Tarot'),
  'astroloji': FalAdi('Astroloji', 'Astrolojiyi', 'Astrolojiye', 'Astrolojiden', 'Astrolojinin', 'Astrology'),
  'numeroloji': FalAdi('Numeroloji', 'Numerolojiyi', 'Numerolojiye', 'Numerolojiden', 'Numerolojinin', 'Numerology'),
  'durugoru': FalAdi('Durugörü', 'Durugörüyü', 'Durugörüye', 'Durugörüden', 'Durugörünün', 'Clairvoyance'),
  'yuzfali': FalAdi('Yüz Falı', 'Yüz Falını', 'Yüz Falına', 'Yüz Falından', 'Yüz Falının', 'Face Reading'),
  'elfali': FalAdi('El Falı', 'El Falını', 'El Falına', 'El Falından', 'El Falının', 'Palm Reading'),
  'astrotakvim': FalAdi('AstroTakvim', "AstroTakvim'i", "AstroTakvim'e", "AstroTakvim'den", "AstroTakvim'in", 'AstroCalendar'),
  'biyoritim': FalAdi('Biyoritim', 'Biyoritimi', 'Biyoritime', 'Biyoritimden', 'Biyoritimin', 'Biorhythm'),
  'motivasyon': FalAdi('Motivasyon', 'Motivasyonu', 'Motivasyona', 'Motivasyondan', 'Motivasyonun', 'Motivation'),
  'dertortagi': FalAdi('Dert Ortağı', 'Dert Ortağını', 'Dert Ortağına', 'Dert Ortağından', 'Dert Ortağının', 'Companion'),
  'olumlama': FalAdi('Olumlama', 'Olumlamayı', 'Olumlamaya', 'Olumlamadan', 'Olumlamanın', 'Affirmation'),
  'ozlusoz': FalAdi('Özlü Sözler', 'Özlü Sözleri', 'Özlü Sözlere', 'Özlü Sözlerden', 'Özlü Sözlerin', 'Wise Words'),
  'acigercekler': FalAdi('Acı Gerçekler', 'Acı Gerçekleri', 'Acı Gerçeklere', 'Acı Gerçeklerden', 'Acı Gerçeklerin', 'Bitter Truths'),
  'kaderkitabi': FalAdi('Kader Kitabı', 'Kader Kitabını', 'Kader Kitabına', 'Kader Kitabından', 'Kader Kitabının', 'Book of Fate'),
  'kehanet': FalAdi('Kehanet', 'Kehaneti', 'Kehanete', 'Kehanetten', 'Kehanetin', 'Prophecy'),
  'niyet': FalAdi('Niyet', 'Niyeti', 'Niyete', 'Niyetten', 'Niyetin', 'Intention'),
  'japonfali': FalAdi('Japon Falı', 'Japon Falını', 'Japon Falına', 'Japon Falından', 'Japon Falının', 'Japanese Fortune'),
  'iching': FalAdi('I-Ching', "I-Ching'i", "I-Ching'e", "I-Ching'den", "I-Ching'in", 'I-Ching'),
  'askuyumu': FalAdi('Aşk Uyumu', 'Aşk Uyumunu', 'Aşk Uyumuna', 'Aşk Uyumundan', 'Aşk Uyumunun', 'Love Compatibility'),
  'kadercarki': FalAdi('Kader Çarkı', 'Kader Çarkını', 'Kader Çarkına', 'Kader Çarkından', 'Kader Çarkının', 'Wheel of Fate'),
  'ruya': FalAdi('Rüya Yorumu', 'Rüya Yorumunu', 'Rüya Yorumuna', 'Rüya Yorumundan', 'Rüya Yorumunun', 'Dream Reading'),
  'tavsanfali': FalAdi('Tavşan Falı', 'Tavşan Falını', 'Tavşan Falına', 'Tavşan Falından', 'Tavşan Falının', 'Rabbit Fortune'),
  'dogumharitasi': FalAdi('Doğum Haritası', 'Doğum Haritasını', 'Doğum Haritasına', 'Doğum Haritasından', 'Doğum Haritasının', 'Birth Chart'),
  'kismetim': FalAdi('Kısmet Falı', 'Kısmet Falını', 'Kısmet Falına', 'Kısmet Falından', 'Kısmet Falının', 'Destiny Reading'),
  'arabam': FalAdi('Araba Falı', 'Araba Falını', 'Araba Falına', 'Araba Falından', 'Araba Falının', 'Car Reading'),
  'evim': FalAdi('Ev Falı', 'Ev Falını', 'Ev Falına', 'Ev Falından', 'Ev Falının', 'Home Reading'),
};

/// Rota yolu → fal türü.
const Map<String, String> kRotaFal = {
  '/coffee': 'kahve',
  '/tarot': 'tarot',
  '/astroloji': 'astroloji',
  '/numeroloji': 'numeroloji',
  '/durugoru': 'durugoru',
  '/yuz_fali_kimin': 'yuzfali',
  '/el_fali': 'elfali',
  '/astrotakvim': 'astrotakvim',
  '/biyoritim': 'biyoritim',
  '/motivation': 'motivasyon',
  '/dertortagi': 'dertortagi',
  '/olumlama': 'olumlama',
  '/ozlusoz': 'ozlusoz',
  '/acigercekler': 'acigercekler',
  '/kaderkitabi': 'kaderkitabi',
  '/kehanet': 'kehanet',
  '/niyet': 'niyet',
  '/japonfali': 'japonfali',
  '/iching': 'iching',
  '/ask_uyumu': 'askuyumu',
  '/kadercarki': 'kadercarki',
  '/ruya_yorumu': 'ruya',
  '/tavsanfali': 'tavsanfali',
  '/dogumharitasi': 'dogumharitasi',
  '/kismetim': 'kismetim',
  '/arabam': 'arabam',
  '/evim': 'evim',
};

/// Gelen kutusu `fortuneTypeKey` → fal türü (bilinmeyen tür adıyla anılmaz).
String? falTuruGelenKutusu(String anahtar) => switch (anahtar) {
      'coffee' => 'kahve',
      'astrology' => 'astroloji',
      'dream' => 'ruya',
      'motivation' => 'motivasyon',
      'birthChart' => 'dogumharitasi',
      _ => kFalAdlari.containsKey(anahtar) ? anahtar : null,
    };

/// Sonucu ekranda gösteren türler (gelen kutusuna fal düşürmez).
const Set<String> kAnlikFallar = {
  'astroloji', 'biyoritim', 'astrotakvim', 'dogumharitasi', 'motivasyon', 'olumlama', 'ozlusoz',
  'acigercekler', 'kaderkitabi', 'kismetim', 'arabam', 'evim', 'tavsanfali', 'kadercarki',
  'dertortagi', 'askuyumu', 'niyet', 'kehanet',
};
