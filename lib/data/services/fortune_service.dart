import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/inbox_item.dart';
import '../../core/utils/variable_replacer.dart';

/// Generates fortune texts locally from pre-written JSON data.
/// No API calls — pure local generation based on user profile.
class FortuneService {
  static const _uuid = Uuid();
  final Random _rng = Random();

  List<dynamic>? _tarotTexts;       // tarot_texts.json → tarot_metinleri listesi
  List<dynamic>? _singleTarotTexts; // tarot_single_texts.json → tarot_single_metinleri listesi
  bool _loaded = false;

  // ─── Kahve Falı bölüm verileri (lazy) ────────────────────────────────────
  // Her bölüm ayrı JSON dosyasından yüklenir:
  //   kahve_akarsilama / kahve_giris / kahve_baglama /
  //   kahve_gelisme   / kahve_sonuc / kahve_ugurlama
  static const _kahveBolumler = [
    'kahve_akarsilama',
    'kahve_giris',
    'kahve_baglama',
    'kahve_gelisme',
    'kahve_sonuc',
    'kahve_ugurlama',
  ];
  final Map<String, List<dynamic>> _kahveData = {};
  bool _kahveLoaded = false;

  Future<void> init() async {
    if (_loaded) return;
    final tarotJson = await rootBundle.loadString('assets/data/tarot_texts.json');
    final singleJson = await rootBundle.loadString('assets/data/tarot_single_texts.json');
    _tarotTexts = (jsonDecode(tarotJson) as Map<String, dynamic>)['tarot_metinleri'] as List;
    // Sadece uzun metinleri yükle (kart adında ' 1' olanlar)
    final allSingle = (jsonDecode(singleJson) as Map<String, dynamic>)['tarot_single_metinleri'] as List;
    _singleTarotTexts = allSingle.where((t) => ((t as Map)['kart'] as String).endsWith(' 1')).toList();
    _loaded = true;
  }

  Future<void> _initKahve() async {
    if (_kahveLoaded) return;
    for (final bolum in _kahveBolumler) {
      final json = await rootBundle.loadString('assets/data/$bolum.json');
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _kahveData[bolum] = decoded[bolum] as List;
    }
    _kahveLoaded = true;
  }

  // ─── Coffee Fortune ───────────────────────────────────────────────────────
  //
  // SEÇİM MOTORU KURALLARI (assets/data/kahve_*.json)
  // ──────────────────────────────────────────────────
  // 6 bölüm sırayla seçilir: akarsilama, giris, baglama, gelisme, sonuc, ugurlama
  // Her bölüm için:
  //   1. Demografik filtre → kosullar[] kullanıcı profiline uymalı
  //   2. Tekrar gösterilmeme → SharedPreferences'ta kahve_{bolum}_shown_ids
  //   3. Uygun metinler bitince sıfırlanır ve baştan başlanır
  // Bölümler arasına boş satır eklenir.

  Future<InboxItem> generateCoffeeFortune({
    required UserProfile profile,
    String? photoPath1,
    String? photoPath2,
    String? photoPath3,
  }) async {
    await _initKahve();
    final vars = profile.toVariableMap();
    final prefs = await SharedPreferences.getInstance();

    final buffer = StringBuffer();

    for (final bolum in _kahveBolumler) {
      final allTexts = _kahveData[bolum] ?? [];
      if (allTexts.isEmpty) continue;

      // Demografik filtre
      final eligible = allTexts.where((t) {
        final kosullar = (t as Map<String, dynamic>)['kosullar'] as List;
        if (kosullar.isEmpty) return true;
        return kosullar.every((k) {
          final degisken = (k as Map)['degisken'] as String;
          final deger = k['deger'] as String;
          final userVal = (vars[degisken] ?? '').toLowerCase();
          return userVal == deger.toLowerCase() ||
              userVal.contains(deger.toLowerCase()) ||
              deger.toLowerCase().contains(userVal);
        });
      }).toList();

      if (eligible.isEmpty) continue;

      // Tekrar gösterilmeme
      final shownKey = 'kahve_${bolum}_shown_ids';
      var shownIds = prefs.getStringList(shownKey) ?? [];
      var available = eligible
          .where((t) => !shownIds.contains('${(t as Map)['id']}'))
          .toList();

      if (available.isEmpty) {
        await prefs.remove(shownKey);
        shownIds = [];
        available = List.from(eligible);
      }

      available.shuffle(_rng);
      final chosen = available.first as Map<String, dynamic>;
      await prefs.setStringList(shownKey, [...shownIds, '${chosen['id']}']);

      final metin = VariableReplacer.replace(chosen['metin'] as String, vars);
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(metin);
    }

    // 3-6 dakika arası kilit süresi
    final unlockMinutes = 3 + _rng.nextInt(4);
    final now = DateTime.now();
    final unlockAt = now.add(Duration(minutes: unlockMinutes)).toIso8601String();

    return InboxItem(
      id: _uuid.v4(),
      title: 'Kahve Falın Hazır',
      text: buffer.toString().trim(),
      date: now.toIso8601String(),
      fortuneTypeKey: 'coffee',
      unlockAt: unlockAt,
      photoPath1: photoPath1,
      photoPath2: photoPath2,
      photoPath3: photoPath3,
    );
  }

  // ─── Tarot ────────────────────────────────────────────────────────────────
  //
  // SEÇİM MOTORU KURALLARI (assets/data/tarot_texts.json)
  // ─────────────────────────────────────────────────────
  // 1. JSON'daki her giriş: id, pozisyon (gecmis/simdi/gelecek), kart, ters, metin, kosullar
  // 2. Pozisyon sırası: 1. kart → gecmis, 2. kart → simdi, 3. kart → gelecek
  // 3. Kart adı eşleştirmesi: Flutter kart adı → JSON kart adı (_flutterToJsonKart haritası)
  // 4. Ters eşleştirmesi: kartın isReversed değeri → JSON'daki ters alanı
  // 5. Demografik filtre: kosullar[] içindeki her koşul kullanıcı profiline uymalı
  //    - Uygun metin bulunamazsa kart adına bakmaksızın pozisyon+ters havuzundan seç
  // 6. Tekrar gösterilmeme: SharedPreferences'a her pozisyon+kart+ters için gösterilen ID'ler kaydedilir
  //    - Tüm uygun metinler gösterilince liste sıfırlanır, baştan başlanır
  // 7. Havuz boşsa: o pozisyon atlanır (metin üretilmez)
  // 8. Metinler arasında sadece tek boş satır (\n\n) olur
  // 9. {{isim}} ve diğer değişkenler VariableReplacer ile çözülür

  Future<InboxItem> generateTarotFortune({
    required UserProfile profile,
    required List<({String name, bool isReversed})> cards,
  }) async {
    await init();
    final vars = profile.toVariableMap();
    final prefs = await SharedPreferences.getInstance();
    final allTexts = _tarotTexts!;

    final positions = ['gecmis', 'simdi', 'gelecek'];
    final buffer = StringBuffer();
    final titleParts = <String>[];

    for (int i = 0; i < 3 && i < cards.length; i++) {
      final card = cards[i];
      final pozisyon = positions[i];
      final jsonKart = _flutterToJsonKart[card.name] ?? card.name;

      // Karta özgü eşleşen metinler
      var matching = allTexts.where((t) {
        final m = t as Map<String, dynamic>;
        return m['pozisyon'] == pozisyon &&
            m['kart'] == jsonKart &&
            m['ters'] == card.isReversed;
      }).toList();

      // Bulunamazsa: pozisyon + ters eşleşen herhangi bir metinden seç
      if (matching.isEmpty) {
        matching = allTexts.where((t) {
          final m = t as Map<String, dynamic>;
          return m['pozisyon'] == pozisyon && m['ters'] == card.isReversed;
        }).toList();
      }

      // Demografik filtre
      final eligible = matching.where((t) {
        final kosullar = (t as Map<String, dynamic>)['kosullar'] as List;
        if (kosullar.isEmpty) return true;
        return kosullar.every((k) {
          final degisken = (k as Map)['degisken'] as String;
          final deger = k['deger'] as String;
          final userVal = (vars[degisken] ?? '').toLowerCase();
          return userVal == deger.toLowerCase() ||
              userVal.contains(deger.toLowerCase()) ||
              deger.toLowerCase().contains(userVal);
        });
      }).toList();

      if (eligible.isEmpty) continue;

      // Tekrar gösterilmeme
      final shownKey = 'tarot_shown_${pozisyon}_${jsonKart}_${card.isReversed}';
      var shownIds = prefs.getStringList(shownKey) ?? [];
      var available = eligible.where((t) => !shownIds.contains('${(t as Map)['id']}')).toList();

      if (available.isEmpty) {
        // Tüm metinler gösterildi → sıfırla
        await prefs.remove(shownKey);
        shownIds = [];
        available = eligible;
      }

      available.shuffle(_rng);
      final chosen = available.first as Map<String, dynamic>;
      await prefs.setStringList(shownKey, [...shownIds, '${chosen['id']}']);

      final metin = VariableReplacer.replace(chosen['metin'] as String, vars);
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(metin);

      titleParts.add(card.isReversed ? 'Ters ${card.name}' : card.name);
    }

    // 3-6 dakika arasında rastgele kilit süresi
    final unlockMinutes = 3 + _rng.nextInt(4);
    final now = DateTime.now();
    final unlockAt = now.add(Duration(minutes: unlockMinutes)).toIso8601String();

    return InboxItem(
      id: _uuid.v4(),
      title: 'Tarot Falın: ${titleParts.join(', ')}',
      text: buffer.toString().trim(),
      date: now.toIso8601String(),
      fortuneTypeKey: 'tarot',
      unlockAt: unlockAt,
    );
  }

  // ─── Tek Kart Tarot (Aşk / Dilek / Şans) ────────────────────────────────────
  //
  // tarot_single_texts.json: id, tur ('ask'|'dilek'|'sans'), kart ('X 1'), metin, kosullar
  // Kart adı: JSON'da '<jsonName> 1' formatında saklanıyor

  Future<InboxItem> generateSingleTarotFortune({
    required UserProfile profile,
    required String type,          // 'ask' | 'dilek' | 'sans'
    required String cardJsonName,  // Örn: 'Adalet', 'Kilicaltilisi'
    required String cardDisplayName,
  }) async {
    await init();
    final vars = profile.toVariableMap();
    final prefs = await SharedPreferences.getInstance();
    final allTexts = _singleTarotTexts!;

    // JSON'da kart adı '<jsonName> 1' formatında
    final jsonKart = '$cardJsonName 1';

    // Karta ve türe özgü metinler
    var matching = allTexts.where((t) {
      final m = t as Map<String, dynamic>;
      return m['tur'] == type && m['kart'] == jsonKart;
    }).toList();

    // Bulunamazsa: sadece tür eşleşen herhangi bir metin
    if (matching.isEmpty) {
      matching = allTexts.where((t) => (t as Map)['tur'] == type).toList();
    }

    // Demografik filtre
    final eligible = matching.where((t) {
      final kosullar = (t as Map<String, dynamic>)['kosullar'] as List;
      if (kosullar.isEmpty) return true;
      return kosullar.every((k) {
        final degisken = (k as Map)['degisken'] as String;
        final deger = k['deger'] as String;
        final userVal = (vars[degisken] ?? '').toLowerCase();
        return userVal == deger.toLowerCase() ||
            userVal.contains(deger.toLowerCase()) ||
            deger.toLowerCase().contains(userVal);
      });
    }).toList();

    String metin;
    if (eligible.isEmpty) {
      metin = '$cardDisplayName kartın seçildi. Magnus yakında yorumlayacak...';
    } else {
      // Tekrar gösterilmeme
      final shownKey = 'single_tarot_shown_${type}_$cardJsonName';
      var shownIds = prefs.getStringList(shownKey) ?? [];
      var available = eligible.where((t) => !shownIds.contains('${(t as Map)['id']}')).toList();

      if (available.isEmpty) {
        await prefs.remove(shownKey);
        shownIds = [];
        available = eligible;
      }

      available.shuffle(_rng);
      final chosen = available.first as Map<String, dynamic>;
      await prefs.setStringList(shownKey, [...shownIds, '${chosen['id']}']);
      metin = VariableReplacer.replace(chosen['metin'] as String, vars);
    }

    final typeLabel = switch (type) {
      'ask' => 'Aşk Kartı',
      'dilek' => 'Dilek Kartı',
      'sans' => 'Şans Kartı',
      _ => 'Tarot',
    };

    final unlockMinutes = 3 + _rng.nextInt(4);
    final now = DateTime.now();
    final unlockAt = now.add(Duration(minutes: unlockMinutes)).toIso8601String();

    return InboxItem(
      id: _uuid.v4(),
      // Başlık formatı: "<TypeLabel> Falın: <jsonName>" — detail screen'de image yolu türetmek için jsonName kullanılır
      title: '$typeLabel Falın: $cardJsonName',
      text: metin,
      date: now.toIso8601String(),
      fortuneTypeKey: 'tarot',
      unlockAt: unlockAt,
    );
  }

  // Flutter kart adı → tarot_texts.json kart adı eşleştirmesi
  static const _flutterToJsonKart = <String, String>{
    'Azize': 'Azize',
    'Budala (Deli)': 'Deli',
    'Büyücü': 'Buyucu',
    'Adalet': 'Adalet',
    'Araba': 'Savasarabasi',
    'Asa Altılısı': 'Degnekaltilisi',
    'Asa Ası': 'Degnekasi',
    'Asa Beşlisi': 'Degnekbeslisi',
    'Asa Dokuzlusu': 'Degnekdokuzlusu',
    'Asa Dörtlüsü': 'Degnekdortlusu',
    'Asa İkilisi': 'Degnekikilisi',
    'Asa Kralı': 'Degnekkrali',
    'Asa Kraliçesi': 'Degnekkralicesi',
    'Asa Onlusu': 'Degnekonlusu',
    'Asa Prensi': 'Degnekprensi',
    'Asa Sekizlisi': 'Degneksekizlisi',
    'Asa Şövalyesi': 'Degneksovalyesi',
    'Asa Üçlüsü': 'Degnekuclusu',
    'Asa Yedilisi': 'Degnekyedilisi',
    'Aşıklar': 'Asiklar',
    'Asılan Adam': 'Asilanadam',
    'Ay': 'Ay',
    'Aziz': 'Aziz',
    'Denge': 'Denge',
    'Dünya': 'Dunya',
    'Güç': 'Guc',
    'Güneş': 'Gunes',
    'İmparator': 'imparator',
    'İmparatoriçe': 'imparatorice',
    'Kader Çarkı': 'Kadercarki',
    'Kılıç Altılısı': 'Kilicaltilisi',
    'Kılıç Ası': 'Kilicasi',
    'Kılıç Beşlisi': 'Kilicbeslisi',
    'Kılıç Dokuzlusu': 'Kilicdokuzlusu',
    'Kılıç Dörtlüsü': 'Kilicdortlusu',
    'Kılıç İkilisi': 'Kilicikilisi',
    'Kılıç Kralı': 'Kilickrali',
    'Kılıç Kraliçesi': 'Kilickralicesi',
    'Kılıç Onlusu': 'Kiliconlusu',
    'Kılıç Prensi': 'Kilicprensi',
    'Kılıç Sekizlisi': 'Kilicsekizlisi',
    'Kılıç Şövalyesi': 'Kilicsovalyesi',
    'Kılıç Üçlüsü': 'Kilicuclusu',
    'Kılıç Yedilisi': 'Kilicyedilisi',
    'Kupa Altılısı': 'Kupaaltilisi',
    'Kupa Ası': 'Kupaasi',
    'Kupa Beşlisi': 'Kupabeslisi',
    'Kupa Dokuzlusu': 'Kupadokuzlusu',
    'Kupa Dörtlüsü': 'Kupadortlusu',
    'Kupa İkilisi': 'Kupaikilisi',
    'Kupa Kralı': 'Kupakrali',
    'Kupa Kraliçesi': 'Kupakralicesi',
    'Kupa Onlusu': 'Kupaonlusu',
    'Kupa Prensi': 'Kupaprensi',
    'Kupa Sekizlisi': 'Kupasekizlisi',
    'Kupa Şövalyesi': 'Kupasovalyesi',
    'Kupa Üçlüsü': 'Kupauclusu',
    'Kupa Yedilisi': 'Kupayedilisi',
    'Mahkeme': 'Mahkeme',
    'Münzevi': 'Ermis',
    'Ölüm': 'Olum',
    'Şeytan': 'Seytan',
    'Tılsım Altılısı': 'Tilsimaltilisi',
    'Tılsım Ası': 'Tilsimasi',
    'Tılsım Beşlisi': 'Tilsimbeslisi',
    'Tılsım Dokuzlusu': 'Tilsimdokuzlusu',
    'Tılsım Dörtlüsü': 'Tilsimdortlusu',
    'Tılsım İkilisi': 'Tilsimikilisi',
    'Tılsım Kralı': 'Tilsimkrali',
    'Tılsım Kraliçesi': 'Tilsimkralicesi',
    'Tılsım Onlusu': 'Tilsimonlusu',
    'Tılsım Prensi': 'Tilsimprensi',
    'Tılsım Sekizlisi': 'Tilsimsekizlisi',
    'Tılsım Şövalyesi': 'Tilsimsovalyesi',
    'Tılsım Üçlüsü': 'Tilsimuclusu',
    'Tılsım Yedilisi': 'Tilsimyedilisi',
    'Yıkılan Kule': 'Yikilankule',
    'Yıldız': 'Yildiz',
  };

  // ─── Daily astrology (simple, based on zodiac) ────────────────────────────

  Future<InboxItem> generateDailyAstrology({required UserProfile profile}) async {
    final vars = profile.toVariableMap();
    final zodiac = profile.zodiacSign ?? 'Koç';
    final text = _buildDailyAstrology(zodiac, vars);

    return InboxItem(
      id: _uuid.v4(),
      title: '$zodiac Günlük Yorumu',
      text: text,
      date: DateTime.now().toIso8601String(),
      fortuneTypeKey: 'astrology',
    );
  }

  String _buildDailyAstrology(String zodiac, Map<String, String> vars) {
    final texts = _dailyAstrologyTexts[zodiac] ?? _dailyAstrologyTexts['default']!;
    final raw = _pick(texts);
    return VariableReplacer.replace(raw, vars);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _pick(List list) {
    return list[_rng.nextInt(list.length)] as String;
  }

  // ─── Daily astrology texts ────────────────────────────────────────────────

  static const Map<String, List<String>> _dailyAstrologyTexts = {
    'default': [
      '{{isim}}, bugün yıldızlar seninle. İçgüdülerine güven ve önüne çıkan fırsatları kaçırma.',
      '{{isim}}, bugün dikkatli ve sabırlı ol. Aceleci kararlar istemediğin sonuçlar doğurabilir.',
      '{{isim}}, bugün sosyal enerjin yüksek. Sevdiklerinle vakit geçirmek sana iyi gelecek.',
    ],
    'Koç': [
      '{{isim}}, Koç olarak bugün ateş enerjin dorukta. Uzun süredir ertelediğin o projeye başlamak için mükemmel bir gün.',
      'Mars\'ın etkisiyle bugün liderlik vasfın ön plana çıkıyor {{isim}}. Ekibini veya çevrendeki insanları motive et.',
      'Bugün sabırsızlığına dikkat et {{isim}}. Ama o enerjiyi doğru kanale yönlendirirsen harika işler çıkarabilirsin.',
    ],
    'Boğa': [
      '{{isim}}, Venüs\'ün rehberliğinde bugün güzellik ve konfor arayışındasın. Kendine küçük bir ödül ver.',
      'Mali konularda bugün dikkatli ol {{isim}}. Venüs sana zevk düşkünlüğünü hatırlatıyor; bütçeni aşma.',
      'Bugün doğayla vakit geçirmek sana inanılmaz bir huzur verecek {{isim}}. Topraklanma vakti.',
    ],
    'İkizler': [
      '{{isim}}, Merkür etkisiyle bugün iletişim yeteneğin tavan yapıyor. Söylemek istediğini bugün söyle.',
      'Merakın ve zeka parıltın bugün çevrendeki herkesi etkiliyor {{isim}}. Yeni bilgiler keşfetmek için harika bir gün.',
      'Bugün çift taraflı düşünce yapın sana avantaj sağlıyor {{isim}}. Farklı perspektiflerden bak.',
    ],
    'Yengeç': [
      '{{isim}}, Ay\'ın etkisiyle bugün duygusal hassasiyetin artmış. Sevdiklerinle derin bir bağ kurabilirsin.',
      'Ev ve aile bugün önceliğin olsun {{isim}}. Yuva sıcaklığı şu an tam ihtiyacın olan şey.',
      'Sezgilerin bugün çok güçlü {{isim}}. İçinden gelen o sesi duyumsayabiliyorsan, ona kulak ver.',
    ],
    'Aslan': [
      '{{isim}}, Güneş\'in çocuğu olarak bugün sahnelerin en parlak yıldızısın. Var ol!',
      'Yaratıcılığın bugün sınır tanımıyor {{isim}}. Bir sanat eseri yarat, dans et, gülümse.',
      'Bugün liderlik vasıfların takdir görüyor {{isim}}. Ama dinlemeyi de unutma; en iyi liderler iyi dinleyicilerdir.',
    ],
    'Başak': [
      '{{isim}}, Merkür\'ün yönlendirmesiyle bugün detaylara olan dikkatiniz mükemmel sonuçlar doğuruyor.',
      'Sağlık ve düzen bugün gündeminde {{isim}}. Küçük ama önemli bir alışkanlık başlatmak için ideal gün.',
      'Analitik zekânın bugün parlıyor {{isim}}. Karmaşık bir sorunu çözmek için doğru zamanda.',
    ],
    'Terazi': [
      '{{isim}}, Venüs\'ün etkisiyle bugün uyum ve güzellik arıyorsun her şeyde. Bu farkındalık seni mutlu kılacak.',
      'Adaletli yaklaşımın bugün takdir görüyor {{isim}}. Çevrendeki bir anlaşmazlıkta arabulucu rolü üstlenebilirsin.',
      'İlişkiler bugün ön planda {{isim}}. Önemli biri sana yaklaşmak istiyor olabilir.',
    ],
    'Akrep': [
      '{{isim}}, Plüton\'un derinleştirici etkisiyle bugün yüzeyin altına inmek istiyorsun. Gerçeği bulacaksın.',
      'Dönüşüm enerjisi bugün çok güçlü {{isim}}. Eskiyi bırakıp yeniyi kucaklamak için mükemmel bir an.',
      'Sezgilerin bugün X-ray gibi çalışıyor {{isim}}. İnsanların söylemediği şeyleri hissediyorsun.',
    ],
    'Yay': [
      '{{isim}}, Jüpiter\'in şansıyla bugün ufkunu genişlet. Yeni bir fikir, yeni bir hedef, yeni bir macera seni çağırıyor.',
      'Özgürlük ve keşif bugün ruhunun ihtiyacı {{isim}}. Rutin dışına çık, farklı bir şey dene.',
      'İyimserliğin bugün bulaşıcı {{isim}}. Etrafındaki insanlara umut ve neşe yayıyorsun.',
    ],
    'Oğlak': [
      '{{isim}}, Satürn\'ün disipliniyle bugün uzun vadeli hedeflerine odaklanma zamanı.',
      'Sabır ve azminle bugün önemli bir adım atıyorsun {{isim}}. Küçük ilerlemeler büyük başarıların temelidir.',
      'Kariyer ve sorumluluklar bugün gündeminde {{isim}}. Emeklerin yakında karşılığını bulacak.',
    ],
    'Kova': [
      '{{isim}}, Uranüs\'ün yenilikçi enerjisiyle bugün alışılmışın dışında düşünüyorsun.',
      'İnsancıl değerlerin bugün ön plana çıkıyor {{isim}}. Bir topluluğa veya projeye katkı sunmak sana anlam katacak.',
      'Özgün fikirlerini bugün paylaş {{isim}}. Dünya farklı bir bakış açısına ihtiyaç duyuyor.',
    ],
    'Balık': [
      '{{isim}}, Neptün\'ün mistik etkisiyle bugün sezgilerin olağanüstü güçlü. Her şeyi hissediyorsun.',
      'Yaratıcılık ve ruhsallık bugün iç içe {{isim}}. Meditasyon, müzik veya sanat sana kapılar açabilir.',
      'Empatin bugün hem gücün hem de zayıflığın {{isim}}. Sınırlarını koru ama kalbini açık tut.',
    ],
  };
}
