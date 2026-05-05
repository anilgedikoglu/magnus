import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

part 'inbox_item.g.dart';

enum FortuneType { coffee, tarot, astrology, dream, motivation, general, birthChart, numeroloji, durugoru, elfali, iching, japonfali, yuzfali }

@HiveType(typeId: 1)
class InboxItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String text;

  @HiveField(3)
  String date; // ISO8601

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  String fortuneTypeKey; // 'coffee' | 'tarot' | etc.

  @HiveField(6)
  String? photoPath1; // for coffee — path to first photo

  @HiveField(7)
  String? photoPath2;

  @HiveField(8)
  String? photoPath3;

  @HiveField(9)
  String? iconAsset; // asset path for icon shown in list

  @HiveField(10)
  String? unlockAt; // ISO8601 — null = immediately readable; future = locked

  InboxItem({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
    this.isRead = false,
    required this.fortuneTypeKey,
    this.photoPath1,
    this.photoPath2,
    this.photoPath3,
    this.iconAsset,
    this.unlockAt,
  });

  /// true ise kart henüz açılmamış (kilitli)
  bool get isLocked {
    if (unlockAt == null) return false;
    try {
      return DateTime.now().isBefore(DateTime.parse(unlockAt!));
    } catch (_) {
      return false;
    }
  }

  /// 0.0 = tam kilitli, 1.0 = açıldı
  double get unlockProgress {
    if (unlockAt == null) return 1.0;
    try {
      final created = DateTime.parse(date);
      final unlock = DateTime.parse(unlockAt!);
      final total = unlock.difference(created).inMilliseconds;
      if (total <= 0) return 1.0;
      final elapsed = DateTime.now().difference(created).inMilliseconds;
      return (elapsed / total).clamp(0.0, 1.0);
    } catch (_) {
      return 1.0;
    }
  }

  FortuneType get fortuneType {
    switch (fortuneTypeKey) {
      case 'coffee':
        return FortuneType.coffee;
      case 'tarot':
        return FortuneType.tarot;
      case 'astrology':
        return FortuneType.astrology;
      case 'dream':
        return FortuneType.dream;
      case 'motivation':
        return FortuneType.motivation;
      case 'birthChart':
        return FortuneType.birthChart;
      case 'numeroloji':
        return FortuneType.numeroloji;
      case 'durugoru':
        return FortuneType.durugoru;
      case 'elfali':
        return FortuneType.elfali;
      case 'iching':
        return FortuneType.iching;
      case 'japonfali':
        return FortuneType.japonfali;
      case 'yuzfali':
        return FortuneType.yuzfali;
      default:
        return FortuneType.general;
    }
  }

  String get previewText {
    // El Falı: JSON formatında saklanır, genel_degerlendirme metnini çıkar
    if (fortuneType == FortuneType.elfali) {
      try {
        final data = (jsonDecode(text) as Map<String, dynamic>);
        final genel = data['genel'] as String? ?? '';
        final cleaned = genel.replaceAll('\n', ' ').trim();
        return cleaned.length > 120 ? '${cleaned.substring(0, 120)}…' : cleaned;
      } catch (_) {}
    }
    // Unity <color=...>...</color> tag'larını kaldır, aralarındaki yazıyı koru
    final stripped = text.replaceAll(RegExp(r'<color=[^>]+>|<\/color>', caseSensitive: false), '');
    final cleaned = stripped.replaceAll('\n', ' ').trim();
    return cleaned.length > 120 ? '${cleaned.substring(0, 120)}…' : cleaned;
  }

  /// Gelen kutusunda başlık olarak gösterilen metin.
  /// Format: "Kahve Falı - 08.04.2026 14:32"
  String get displayTitle {
    try {
      final dt = DateTime.parse(date);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$fortuneTypeLabel - $d.$m.$y $h:$min';
    } catch (_) {
      return fortuneTypeLabel;
    }
  }

  String get fortuneTypeLabel {
    switch (fortuneType) {
      case FortuneType.coffee:
        return 'Kahve Falı';
      case FortuneType.tarot:
        return 'Tarot';
      case FortuneType.astrology:
        return 'Astroloji';
      case FortuneType.dream:
        return 'Rüya Yorumu';
      case FortuneType.motivation:
        return 'Motivasyon';
      case FortuneType.general:
        return 'Magnus';
      case FortuneType.birthChart:
        return 'Doğum Haritası';
      case FortuneType.numeroloji:
        return 'Numeroloji';
      case FortuneType.durugoru:
        return 'Durugörü';
      case FortuneType.elfali:
        return 'El Falı';
      case FortuneType.iching:
        return 'I-Ching';
      case FortuneType.japonfali:
        return 'Japon Falı';
      case FortuneType.yuzfali:
        return 'Yüz Falı';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'date': date,
        'isRead': isRead,
        'fortuneTypeKey': fortuneTypeKey,
        'photoPath1': photoPath1,
        'photoPath2': photoPath2,
        'photoPath3': photoPath3,
        'iconAsset': iconAsset,
        'unlockAt': unlockAt,
      };

  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
        id: json['id'],
        title: json['title'],
        text: json['text'],
        date: json['date'],
        isRead: json['isRead'] ?? false,
        fortuneTypeKey: json['fortuneTypeKey'] ?? 'general',
        photoPath1: json['photoPath1'],
        photoPath2: json['photoPath2'],
        photoPath3: json['photoPath3'],
        iconAsset: json['iconAsset'],
        unlockAt: json['unlockAt'],
      );
}
