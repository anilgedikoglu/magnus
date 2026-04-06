import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/inbox_item.dart';
import '../../core/utils/variable_replacer.dart';

/// Generates fortune texts locally from pre-written JSON data.
/// No API calls — pure local generation based on user profile.
class FortuneService {
  static const _uuid = Uuid();
  final Random _rng = Random();

  Map<String, dynamic>? _coffeeData;
  Map<String, dynamic>? _tarotData;
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    final coffeeJson = await rootBundle.loadString('assets/data/coffee_fortune.json');
    final tarotJson = await rootBundle.loadString('assets/data/tarot.json');
    _coffeeData = jsonDecode(coffeeJson) as Map<String, dynamic>;
    _tarotData = jsonDecode(tarotJson) as Map<String, dynamic>;
    _loaded = true;
  }

  // ─── Coffee Fortune ───────────────────────────────────────────────────────

  Future<InboxItem> generateCoffeeFortune({
    required UserProfile profile,
    String? photoPath1,
    String? photoPath2,
    String? photoPath3,
  }) async {
    await init();
    final vars = profile.toVariableMap();
    final text = _buildCoffeeText(profile, vars);

    return InboxItem(
      id: _uuid.v4(),
      title: 'Kahve Falın Hazır',
      text: text,
      date: DateTime.now().toIso8601String(),
      fortuneTypeKey: 'coffee',
      photoPath1: photoPath1,
      photoPath2: photoPath2,
      photoPath3: photoPath3,
    );
  }

  String _buildCoffeeText(UserProfile profile, Map<String, String> vars) {
    final data = _coffeeData!;
    final greetings = data['greetings'] as Map<String, dynamic>;
    final bodies = data['bodies'] as Map<String, dynamic>;
    final closings = data['closings'] as List;

    // 1. Greeting — personalized by job
    final greetingList = (greetings[profile.job] as List?) ??
        (greetings['default'] as List);
    final greeting = _pick(greetingList);

    // 2. Love section — personalized by marital status
    final loveSections = bodies['love'] as Map<String, dynamic>;
    final loveList = (loveSections[profile.maritalStatus] as List?) ??
        (loveSections['default'] as List);
    final love = _pick(loveList);

    // 3. Career section — personalized by job
    final careerSections = bodies['career'] as Map<String, dynamic>;
    final careerList = (careerSections[profile.job] as List?) ??
        (careerSections['default'] as List);
    final career = _pick(careerList);

    // 4. Money
    final money = _pick(bodies['money'] as List);

    // 5. Health
    final health = _pick(bodies['health'] as List);

    // 6. General
    final general = _pick(bodies['general'] as List);

    // 7. Closing
    final closing = _pick(closings);

    // Combine all sections into one flowing text
    final raw = [greeting, '', love, '', career, '', money, health, '', general, '', closing]
        .join('\n');

    return VariableReplacer.replace(raw, vars);
  }

  // ─── Tarot ────────────────────────────────────────────────────────────────

  Future<InboxItem> generateTarotFortune({required UserProfile profile}) async {
    await init();
    final vars = profile.toVariableMap();
    final cards = _tarotData!['cards'] as List;
    final closings = _tarotData!['closing'] as List;
    final intros = _tarotData!['intro'] as List;

    // Pick 3 distinct random cards
    final shuffled = List.from(cards)..shuffle(_rng);
    final picked = shuffled.take(3).toList();

    final positions = ['past', 'present', 'future'];
    final positionLabels = _tarotData!['positionLabels'] as Map<String, dynamic>;

    final intro = VariableReplacer.replace(_pick(intros), vars);
    final closing = VariableReplacer.replace(_pick(closings), vars);

    final buffer = StringBuffer();
    buffer.writeln(intro);
    buffer.writeln();

    for (int i = 0; i < 3; i++) {
      final card = picked[i] as Map<String, dynamic>;
      final pos = positions[i];
      final posLabel = positionLabels[pos] as String;
      final cardName = card['name'] as String;
      final isReversed = _rng.nextBool();
      final orientation = isReversed ? 'reversed' : 'normal';
      final reading = (card[orientation] as Map<String, dynamic>)[pos] as String;
      final resolvedReading = VariableReplacer.replace(reading, vars);

      buffer.writeln('── $posLabel: $cardName ${isReversed ? '(Ters)' : ''} ──');
      buffer.writeln(resolvedReading);
      buffer.writeln();
    }

    buffer.writeln(closing);

    final cardNames = picked
        .map((c) => (c as Map<String, dynamic>)['name'] as String)
        .join(', ');

    return InboxItem(
      id: _uuid.v4(),
      title: 'Tarot Falın: $cardNames',
      text: buffer.toString().trim(),
      date: DateTime.now().toIso8601String(),
      fortuneTypeKey: 'tarot',
    );
  }

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
