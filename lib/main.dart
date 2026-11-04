import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'data/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gömülü OFL yazı tiplerinin lisansları (Jost, Cinzel, EB Garamond) — lisans sayfasında görünür.
  LicenseRegistry.addLicense(() async* {
    for (final (fam, file) in const [
      ('Jost', 'OFL-Jost.txt'),
      ('Cinzel', 'OFL-Cinzel.txt'),
      ('EB Garamond', 'OFL-EBGaramond.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/google_fonts/$file');
      yield LicenseEntryWithLineBreaks(['google_fonts', fam], text);
    }
  });

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge mod: sistem UI (status bar + nav bar) şeffaf, uygulama tam ekran.
  // SafeArea widget'ları içerikleri doğru konumlandırır.
  // Her ekranda icon rengi için SystemUiOverlayStyle kullanılabilir.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // AdMob başlat
  await AdService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();

  // Admin modu: godag bypass ile girildiyse reklamlar kapalıdır
  final adsDisabled = prefs.getBool('admin_ads_disabled') ?? false;
  AdService.instance.setAdsDisabled(adsDisabled);

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MagnusApp(),
    ),
  );
}
