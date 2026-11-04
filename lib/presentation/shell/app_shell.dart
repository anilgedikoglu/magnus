import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ana iskelet — alt navigasyon çubuğu kaldırıldı.
/// Inbox'a ana ekrandaki zarf butonundan, geri dönüş AppBar'daki back ile yapılıyor.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Klavye açılınca kabuk gövdeyi küçültmesin: aksi hâlde MainTabsScreen'deki cam
      // alt bar klavyenin üstüne çıkıp havada kalır (Instagram'daki gibi arkada kalmalı).
      // Klavyeye yer açma iç ekranların kendi Scaffold'larında (viewInsets tüketilmediği
      // için onlar görmeye devam eder).
      resizeToAvoidBottomInset: false,
      body: navigationShell,
    );
  }
}
