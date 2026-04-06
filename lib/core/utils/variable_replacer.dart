import 'package:intl/intl.dart';

/// Replaces {{variable}} placeholders in text with actual values.
/// Direct equivalent of Unity's ChatVariables.OrtakButonlar().
class VariableReplacer {
  VariableReplacer._();

  /// Main replacement function. Takes template text and a variable map,
  /// returns the fully resolved string.
  static String replace(String template, Map<String, String> variables) {
    final now = DateTime.now();
    final allVars = {
      ...variables,
      ..._timeVariables(now),
    };

    String result = template;

    // Replace all {{key}} patterns
    allVars.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });

    // Handle {{sayi,min,max}} — random number in range
    result = _replaceRandomNumbers(result);

    // Handle {{saniye}} — current second
    result = result.replaceAll('{{saniye}}', now.second.toString());

    return result;
  }

  static Map<String, String> _timeVariables(DateTime now) {
    return {
      'gun': _dayOfWeekTr(now.weekday),
      'ay': _monthTr(now.month),
      'mevsim': _seasonTr(now.month),
      'tam_saat': DateFormat('HH:mm').format(now),
      'saat': now.hour.toString(),
      'dakika': now.minute.toString(),
    };
  }

  static String _replaceRandomNumbers(String text) {
    final pattern = RegExp(r'\{\{sayi,(\d+),(\d+)\}\}');
    return text.replaceAllMapped(pattern, (match) {
      final min = int.tryParse(match.group(1) ?? '0') ?? 0;
      final max = int.tryParse(match.group(2) ?? '100') ?? 100;
      // Deterministic "random" based on min+max so same user sees consistent values
      final value = min + ((max - min) ~/ 2);
      return value.toString();
    });
  }

  static String _dayOfWeekTr(int weekday) {
    const days = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday];
  }

  static String _monthTr(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return months[month];
  }

  static String _seasonTr(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  /// Pick one variation from a list. Uses a stable index derived from
  /// the user's name so the same user always gets the same variation
  /// for the same node (deterministic, not random).
  static String pickVariation(List<String> variations, {String seed = ''}) {
    if (variations.isEmpty) return '';
    if (variations.length == 1) return variations.first;
    final index = seed.isEmpty ? 0 : seed.codeUnits.first % variations.length;
    return variations[index];
  }
}
