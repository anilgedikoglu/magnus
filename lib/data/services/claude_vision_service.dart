// lib/data/services/claude_vision_service.dart
// Claude Vision API ile yüz fotoğrafı analizi.
// Model: claude-3-5-haiku → en ucuz vision modeli.
// Fotoğraf image_picker'dan maxWidth/maxHeight:512, quality:75 ile küçültülmüş gelir.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_secrets.dart';

// ── Analiz sonucu veri sınıfı ─────────────────────────────────────────────────
class YuzAnalizi {
  final bool isHuman;
  final String cinsiyet;   // 'erkek' | 'kadin'
  final String gozluk;     // 'Gozluklu' | 'Gozluksuz'
  final String gozRengi;   // 'kahve' | 'mavi' | 'yesil'
  final String kupe;       // 'Kupeli' | 'Kupesiz'
  final String moral;      // 'Moraliiyi' | 'Moralikotu' | 'Moralinormal'
  final String sacBoyu;    // 'Kel' | 'KisaSac' | 'UzunSac' | 'Kapali'
  final String sacRengi;   // 'Beyaz'|'Esmer'|'Kapali'|'Kumral'|'Mavi'|'Pembe'|'Sarisin'|'Kizil'
  final String sakal;      // 'SakalKisa' | 'SakalUzun' | 'SakalYok'
  final String sapka;      // 'Bereli' | 'Kapali' | 'Sapkali' | 'Sapkasiz'

  const YuzAnalizi({
    required this.isHuman,
    this.cinsiyet  = 'kadin',
    this.gozluk    = 'Gozluksuz',
    this.gozRengi  = 'kahve',
    this.kupe      = 'Kupesiz',
    this.moral     = 'Moralinormal',
    this.sacBoyu   = 'UzunSac',
    this.sacRengi  = 'Kumral',
    this.sakal     = 'SakalYok',
    this.sapka     = 'Sapkasiz',
  });

  static const YuzAnalizi insanDegil = YuzAnalizi(isHuman: false);
}

// ── Servis ────────────────────────────────────────────────────────────────────
class ClaudeVisionService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model    = 'claude-3-5-haiku-20241022';

  static Future<YuzAnalizi> analiz(String imagePath) async {
    final bytes       = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Görüntü tipi — image_picker JPEG üretir
    const mediaType = 'image/jpeg';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 400,
      'system':
          'Sen bir yüz analizi asistanısın. '
          'Sadece geçerli JSON formatında cevap ver, '
          'başka hiçbir şey yazma, açıklama ekleme.',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type':       'base64',
                'media_type': mediaType,
                'data':       base64Image,
              },
            },
            {
              'type': 'text',
              'text': _prompt,
            },
          ],
        },
      ],
    });

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type':      'application/json',
            'x-api-key':         kAnthropicApiKey,
            'anthropic-version': '2023-06-01',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API hatası: ${response.statusCode} — ${response.body}');
    }

    final resData = jsonDecode(utf8.decode(response.bodyBytes));
    final rawText = (resData['content'] as List).first['text'] as String;

    // Bazen Claude ```json ... ``` bloku içinde döndürür — temizle
    final jsonStr = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> parsed = jsonDecode(jsonStr);

    if (parsed['insan'] == false) return YuzAnalizi.insanDegil;

    return YuzAnalizi(
      isHuman:  true,
      cinsiyet: _str(parsed['cinsiyet']) == 'erkek' ? 'erkek' : 'kadin',
      gozluk:   _mapGozluk(parsed['gozluk']),
      gozRengi: _mapGozRengi(parsed['goz_rengi']),
      kupe:     _str(parsed['kupe']) == 'kupeli' ? 'Kupeli' : 'Kupesiz',
      moral:    _mapMoral(parsed['moral']),
      sacBoyu:  _mapSacBoyu(parsed['sac_boyu']),
      sacRengi: _mapSacRengi(parsed['sac_rengi']),
      sakal:    _mapSakal(parsed['sakal']),
      sapka:    _mapSapka(parsed['sapka']),
    );
  }

  // ── Haritalama yardımcıları ──────────────────────────────────────────────
  static String _str(dynamic v) => (v ?? '').toString().toLowerCase().trim();

  static String _mapGozluk(dynamic v) =>
      _str(v) == 'gozluklu' ? 'Gozluklu' : 'Gozluksuz';

  static String _mapGozRengi(dynamic v) {
    final s = _str(v);
    if (s == 'mavi')  return 'mavi';
    if (s == 'yesil') return 'yesil';
    return 'kahve';
  }

  static String _mapMoral(dynamic v) {
    final s = _str(v);
    if (s == 'iyi')  return 'Moraliiyi';
    if (s == 'kotu') return 'Moralikotu';
    return 'Moralinormal';
  }

  static String _mapSacBoyu(dynamic v) {
    final s = _str(v);
    if (s == 'kel')    return 'Kel';
    if (s == 'kisa')   return 'KisaSac';
    if (s == 'kapali') return 'Kapali';
    return 'UzunSac';
  }

  static String _mapSacRengi(dynamic v) {
    const m = {
      'beyaz':  'Beyaz',
      'esmer':  'Esmer',
      'kapali': 'Kapali',
      'kizil':  'Kizil',
      'kumral': 'Kumral',
      'mavi':   'Mavi',
      'pembe':  'Pembe',
      'sarisin':'Sarisin',
    };
    return m[_str(v)] ?? 'Kumral';
  }

  static String _mapSakal(dynamic v) {
    final s = _str(v);
    if (s == 'kisa') return 'SakalKisa';
    if (s == 'uzun') return 'SakalUzun';
    return 'SakalYok';
  }

  static String _mapSapka(dynamic v) {
    final s = _str(v);
    if (s == 'bereli')  return 'Bereli';
    if (s == 'kapali')  return 'Kapali';
    if (s == 'sapkali') return 'Sapkali';
    return 'Sapkasiz';
  }

  // ── Türk kahvesi fincanı kontrolu ─────────────────────────────────────────
  /// Fotoğrafta Türk kahvesi fincanı var mı?
  /// Hata durumunda [true] döner (kullanıcıyı engelleme).
  static Future<bool> isTurkishCoffeeCup(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final b64   = base64Encode(bytes);

      final body = jsonEncode({
        'model': _model,
        'max_tokens': 10,
        'system': 'Sadece "evet" veya "hayır" yaz. Başka hiçbir şey yazma.',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type':       'base64',
                  'media_type': 'image/jpeg',
                  'data':       b64,
                },
              },
              {
                'type': 'text',
                'text':
                    'Bu fotoğrafta Türk kahvesi fincanı görünüyor mu? '
                    'Sadece "evet" veya "hayır" yaz.',
              },
            ],
          },
        ],
      });

      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type':      'application/json',
          'x-api-key':         kAnthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return true; // Hata → geçir
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final text = (data['content'] as List).first['text'] as String;
      return text.toLowerCase().contains('evet');
    } catch (_) {
      return true; // Ağ hatası → engelleme
    }
  }

  // ── Analiz prompt ──────────────────────────────────────────────────────────
  static const _prompt = '''
Bu fotoğrafı analiz et ve şu JSON'u doldur. SADECE JSON döndür:

{
  "insan": true,
  "cinsiyet": "erkek veya kadin",
  "gozluk": "gozluklu veya gozluksuz",
  "goz_rengi": "kahve veya mavi veya yesil",
  "kupe": "kupeli veya kupesiz",
  "moral": "iyi veya kotu veya normal",
  "sac_boyu": "kel veya kisa veya uzun veya kapali",
  "sac_rengi": "beyaz veya esmer veya kapali veya kumral veya mavi veya pembe veya sarisin veya kizil",
  "sakal": "kisa veya uzun veya yok",
  "sapka": "bereli veya kapali veya sapkali veya sapkasiz"
}

Kurallar:
- Eğer fotoğrafta gerçek bir insan yüzü yoksa sadece {"insan": false} döndür.
- moral: yüz ifadesinden anlaşılan ruh hali. iyi=mutlu/gülümsüyor, kotu=üzgün/gergin, normal=nötr
- sac_boyu: kel=saçsız, kisa=kısa saç, uzun=omzu geçen saç, kapali=başörtü/türban
- sac_rengi: başörtülüyse kapali; diğer renklerde en yakın seç
- sakal: kisa=stubble veya kısa sakal, uzun=uzun sakal, yok=sakal yok
- sapka: bereli=bere, kapali=başörtü, sapkali=şapka, sapkasiz=başı açık
- Bere ile başörtü farkını iyi ayırt et. Şeffaf değil, cinsiyetsiz bere → bereli.''';
}

// ── El Falı: el fotoğrafı doğrulama ──────────────────────────────────────────
class ElAnalizi {
  final bool isHand;
  const ElAnalizi({required this.isHand});
  static const ElAnalizi elDegil = ElAnalizi(isHand: false);
}

extension ClaudeVisionServiceElFali on ClaudeVisionService {
  static Future<ElAnalizi> elFaliAnaliz(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'model': 'claude-3-5-haiku-20241022',
      'max_tokens': 50,
      'system': 'Sen bir el fotoğrafı doğrulayıcısısın. Sadece JSON döndür.',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': 'Bu fotoğrafta bir insan eli var mı? Sadece JSON döndür: {"el": true} veya {"el": false}',
            },
          ],
        },
      ],
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': kAnthropicApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) return ElAnalizi.elDegil;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = (decoded['content'] as List).first as Map<String, dynamic>;
      final text    = (content['text'] as String).trim();

      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (jsonMatch == null) return ElAnalizi.elDegil;

      final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final isHand = result['el'] == true;
      return ElAnalizi(isHand: isHand);
    } catch (_) {
      return ElAnalizi.elDegil;
    }
  }
}
