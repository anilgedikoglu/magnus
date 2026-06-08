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
  // JSON dosyasındaki kök anahtar adları (dosya adıyla eşleşmiyor)
  static const _kahveJsonKeys = {
    'kahve_akarsilama': 'karsilamalar',
    'kahve_giris':      'girisler',
    'kahve_baglama':    'baglamalar',
    'kahve_gelisme':    'gelismeler',
    'kahve_sonuc':      'sonuclar',
    'kahve_ugurlama':   'ugurlamalar',
  };
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

  // ─── Koşul filtresi ─────────────────────────────────────────────────────────
  // Aynı değişken adına ait koşullar → OR (herhangi biri eşleşirse yeter)
  // Farklı değişken adları → AND (hepsinin kendi grubunda eşleşme olmalı)
  // yasmax / yasmin → sayısal karşılaştırma
  static bool _matchesKosullar(List kosullar, Map<String, String> vars) {
    if (kosullar.isEmpty) return true;

    // Değişken adına göre grupla
    final Map<String, List<String>> groups = {};
    for (final k in kosullar) {
      final degisken = (k as Map)['degisken'] as String;
      final deger = k['deger'] as String;
      groups.putIfAbsent(degisken, () => []).add(deger);
    }

    for (final entry in groups.entries) {
      final degisken = entry.key;
      final degerler = entry.value;

      // yasmax / yasmin → sayısal karşılaştırma
      if (degisken == 'yasmax' || degisken == 'yasmin') {
        final userAge = int.tryParse(vars['yas'] ?? '') ?? 0;
        final matched = degerler.any((d) {
          final limit = int.tryParse(d) ?? 0;
          return degisken == 'yasmax' ? userAge <= limit : userAge >= limit;
        });
        if (!matched) return false;
        continue;
      }

      // Diğer değişkenler → string eşleştirme (OR within group)
      final userVal = (vars[degisken] ?? '').toLowerCase();
      if (userVal.isEmpty) return false; // bilinmeyen değişken → metni gösterme
      final matched = degerler.any((d) => userVal == d.toLowerCase());
      if (!matched) return false;
    }
    return true;
  }

  Future<void> _initKahve() async {
    if (_kahveLoaded) return;
    for (final bolum in _kahveBolumler) {
      final json = await rootBundle.loadString('assets/data/$bolum.json');
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _kahveData[bolum] = decoded[_kahveJsonKeys[bolum]!] as List;
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

  /// fal_konusu eşleşmesi — tek bölüm, tek konu
  static bool _matchesFalKonusu(Map t, String konu) {
    final konular = (t['fal_konusu'] as List?)
        ?.map((e) => e.toString().toLowerCase())
        .toList() ?? [];
    if (konular.isEmpty) return true;
    return konular.contains(konu.toLowerCase());
  }

  /// fal_konusu eşleşmesi — birden fazla konudan herhangi biri
  static bool _matchesAnyKonu(Map t, List<String> konular) {
    final tags = (t['fal_konusu'] as List?)
        ?.map((e) => e.toString().toLowerCase())
        .toList() ?? [];
    if (tags.isEmpty) return true;
    return konular.any((k) => tags.contains(k));
  }

  /// Genel dışı konular için konu filtreli havuz:
  /// L1: konu eşleşmesi → L2: genel → L3: filtresiz
  List _eligibleByKonu(List eligible, String konu) {
    var filtered = eligible.where((t) => _matchesFalKonusu(t as Map, konu)).toList();
    if (filtered.isNotEmpty) return filtered;
    filtered = eligible.where((t) => _matchesFalKonusu(t as Map, 'genel')).toList();
    if (filtered.isNotEmpty) return filtered;
    return eligible;
  }

  /// Genel konu için kademeli genişleme basamakları.
  /// Her basamak bir öncekinden daha geniş bir konu kümesi.
  static const _genelExpansions = [
    ['genel'],
    ['genel', 'ask'],
    ['genel', 'saglik'],
    ['genel', 'kariyer'],
    ['genel', 'ask', 'saglik'],
    ['genel', 'ask', 'kariyer'],
    ['genel', 'saglik', 'kariyer'],
    ['ask', 'saglik', 'kariyer'],
    ['genel', 'ask', 'saglik', 'kariyer'], // tam mix
  ];

  /// "genel" seçildiğinde kademeli genişleme ile no-repeat havuz döner.
  /// Gösterilmemiş metin olan ilk basamak kullanılır.
  List _availableForGenel(List eligible, List<String> shownIds) {
    for (final topics in _genelExpansions) {
      final pool = eligible
          .where((t) => _matchesAnyKonu(t as Map, topics))
          .where((t) => !shownIds.contains('${(t as Map)['id']}'))
          .toList();
      if (pool.isNotEmpty) return pool;
    }
    return []; // tüm basamaklar tükendi → sıfırlama gerekli
  }

  Future<InboxItem> generateCoffeeFortune({
    required UserProfile profile,
    String? photoPath1,
    String? photoPath2,
    String? photoPath3,
    String falKonusu = 'genel', // 'ask' | 'kariyer' | 'saglik' | 'genel'
  }) async {
    await _initKahve();
    final vars = profile.toVariableMap();
    final prefs = await SharedPreferences.getInstance();

    final buffer = StringBuffer();

    for (final bolum in _kahveBolumler) {
      final allTexts = _kahveData[bolum] ?? [];
      if (allTexts.isEmpty) continue;

      // Demografik filtre
      final eligible = allTexts
          .where((t) => _matchesKosullar(
              (t as Map<String, dynamic>)['kosullar'] as List, vars))
          .toList();

      if (eligible.isEmpty) continue;

      // Konu filtresi (kademeleli)
      final konuFiltered = _eligibleByKonu(eligible, falKonusu);

      // Tekrar gösterilmeme (konu + bölüm bazında ayrı key)
      // Kural: tüm uygun metinler gösterilene kadar aynı metin tekrar seçilemez.
      // Sıfırlamada son gösterilen ID korunur → üst üste aynı metin gelmez.
      final shownKey = 'kahve_${bolum}_${falKonusu}_shown_ids';
      var shownIds = prefs.getStringList(shownKey) ?? [];
      List available;

      if (falKonusu == 'genel') {
        // Genel: kademeli genişleme — genel → genel+1 → genel+2 → tam mix
        available = _availableForGenel(eligible, shownIds);
        if (available.isEmpty) {
          // Tüm basamaklar tükendi → son ID koruyarak sıfırla
          final lastId = shownIds.isNotEmpty ? shownIds.last : null;
          final resetShown = lastId != null ? [lastId] : <String>[];
          await prefs.setStringList(shownKey, resetShown);
          shownIds = resetShown;
          available = eligible
              .where((t) => '${(t as Map)['id']}' != lastId)
              .toList();
          if (available.isEmpty) available = List.from(eligible);
        }
      } else {
        // Diğer konular (ask/kariyer/saglik): konu havuzunda no-repeat
        available = konuFiltered
            .where((t) => !shownIds.contains('${(t as Map)['id']}'))
            .toList();
        if (available.isEmpty) {
          final lastId = shownIds.isNotEmpty ? shownIds.last : null;
          final resetShown = lastId != null ? [lastId] : <String>[];
          await prefs.setStringList(shownKey, resetShown);
          shownIds = resetShown;
          available = konuFiltered
              .where((t) => '${(t as Map)['id']}' != lastId)
              .toList();
          if (available.isEmpty) available = List.from(konuFiltered);
        }
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
      final eligible = matching
          .where((t) => _matchesKosullar(
              (t as Map<String, dynamic>)['kosullar'] as List, vars))
          .toList();

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
    final eligible = matching
        .where((t) => _matchesKosullar(
            (t as Map<String, dynamic>)['kosullar'] as List, vars))
        .toList();

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

  // ─── El Falı ─────────────────────────────────────────────────────────────
  //
  // SEÇİM MOTORU (assets/data/elfali.json)
  // ──────────────────────────────────────
  // 1. Genel Değerlendirme: profile koşullarına uyan metinlerden biri
  // 2. Her hat için: koşula uyan metinlerden rastgele yüzde aralığı seç,
  //    o aralıktaki metinlerden biri seç, aralık içinde rastgele yüzde üret
  // Sonuç InboxItem.text'e JSON olarak kaydedilir.

  Map<String, dynamic>? _elfaliData;

  Future<void> _initElfali() async {
    if (_elfaliData != null) return;
    final raw = await rootBundle.loadString('assets/data/elfali.json');
    _elfaliData = (jsonDecode(raw) as Map<String, dynamic>)['elfali'] as Map<String, dynamic>;
  }

  Future<InboxItem> generateElFali({required UserProfile profile}) async {
    await _initElfali();
    final vars = profile.toVariableMap();
    final data = _elfaliData!;

    // ── Genel Değerlendirme ──
    final genelList = (data['genel_degerlendirme'] as List)
        .where((t) => _matchesKosullar((t as Map)['kosullar'] as List, vars))
        .toList();
    genelList.shuffle(_rng);
    final genelMetin = genelList.isNotEmpty
        ? VariableReplacer.replace((genelList.first as Map)['metin'] as String, vars)
        : '';

    // ── Hatlar ──
    final hatlarJson = <Map<String, dynamic>>[];
    for (final hat in (data['hatlar'] as List)) {
      final hatMap = hat as Map<String, dynamic>;
      final hatId  = hatMap['id'] as String;
      final hatAd  = hatMap['ad'] as String;
      final renk   = hatMap['renk'] as String;
      final metinler = (hatMap['metinler'] as List)
          .where((t) => _matchesKosullar((t as Map)['kosullar'] as List, vars))
          .toList();

      if (metinler.isEmpty) continue;

      // Rastgele yüzde aralığı seç
      final ranges = <String>{};
      for (final m in metinler) {
        ranges.add('${(m as Map)['yuzde_min']}-${m['yuzde_max']}');
      }
      final seciliAralik = (ranges.toList())[_rng.nextInt(ranges.length)];
      final parts = seciliAralik.split('-');
      final yuzdeMin = int.parse(parts[0]);
      final yuzdeMax = int.parse(parts[1]);
      final aralikMetinler = metinler
          .where((m) => (m as Map)['yuzde_min'] == yuzdeMin)
          .toList();
      aralikMetinler.shuffle(_rng);
      final secilen = aralikMetinler.isNotEmpty ? aralikMetinler.first : metinler.first;

      final metin = VariableReplacer.replace(
          (secilen as Map)['metin'] as String, vars);
      // Rastgele yüzde: aralık içinde
      final yuzde = yuzdeMin + _rng.nextInt(yuzdeMax - yuzdeMin + 1);

      hatlarJson.add({
        'id': hatId,
        'ad': hatAd,
        'renk': renk,
        'yuzde': yuzde,
        'metin': metin,
      });
    }

    final payload = jsonEncode({
      'tip': 'elfali',
      'genel': genelMetin,
      'hatlar': hatlarJson,
    });

    final now = DateTime.now();
    final unlockAt = now.add(const Duration(minutes: 6)).toIso8601String();

    return InboxItem(
      id: _uuid.v4(),
      title: 'El Falın Hazır',
      text: payload,
      date: now.toIso8601String(),
      fortuneTypeKey: 'elfali',
      unlockAt: unlockAt,
    );
  }
}
