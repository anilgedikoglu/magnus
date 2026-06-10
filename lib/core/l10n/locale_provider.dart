import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const _key = 'app_locale';

  LocaleNotifier(this._prefs) : super(_prefs.getString(_key) ?? 'tr');

  Future<void> setLocale(String locale) async {
    await _prefs.setString(_key, locale);
    state = locale;
  }

  bool get isEn => state == 'en';
}

final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, String>((ref) {
  throw UnimplementedError('Override in ProviderScope with SharedPreferences');
});
