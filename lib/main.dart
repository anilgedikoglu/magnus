import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'data/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
