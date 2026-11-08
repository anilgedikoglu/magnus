// Ana menü karşılama metinlerinin koşulları: gün/vakit/ay ve kullanıcı profili.
// Aynı değişkenin değerleri VEYA, farklı değişkenler VE ile birleşir.

import '../../core/text_engine/text_engine.dart';
import '../../data/models/user_profile.dart';

/// sabah 05–11 · ogle 12–16 · aksam 17–21 · gece 22–04.
String vakitOf(int hour) {
  if (hour >= 5 && hour < 12) return 'sabah';
  if (hour >= 12 && hour < 17) return 'ogle';
  if (hour >= 17 && hour < 22) return 'aksam';
  return 'gece';
}

bool greetingMatches(List<dynamic>? kosullar, UserProfile profile, DateTime now) {
  if (kosullar == null || kosullar.isEmpty) return true;
  final groups = <String, List<String>>{};
  for (final k in kosullar) {
    final m = k as Map<String, dynamic>;
    groups.putIfAbsent('${m['degisken']}', () => []).add('${m['deger']}');
  }
  return groups.entries.every((g) => g.value.any((v) => switch (g.key) {
        'hafta_gunu' => now.weekday.toString() == v,
        'ay' => now.month.toString() == v,
        'vakit' => vakitOf(now.hour) == v,
        _ => TextEngine.matches([
            {'degisken': g.key, 'deger': v}
          ], profile),
      }));
}
