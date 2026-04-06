import 'package:hive_flutter/hive_flutter.dart';

part 'inbox_item.g.dart';

enum FortuneType { coffee, tarot, astrology, dream, motivation, general }

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
  });

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
      default:
        return FortuneType.general;
    }
  }

  String get previewText {
    final cleaned = text.replaceAll('\n', ' ').trim();
    return cleaned.length > 120 ? '${cleaned.substring(0, 120)}…' : cleaned;
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
      );
}
