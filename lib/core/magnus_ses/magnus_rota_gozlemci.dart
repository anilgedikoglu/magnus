// lib/core/magnus_ses/magnus_rota_gozlemci.dart
//
// Fal ekranlarına giriş ve çıkışları Magnus'a bildirir. Kök navigatöre takılır.

import 'package:flutter/widgets.dart';

import 'magnus_fal_adlari.dart';

class MagnusRotaGozlemci extends NavigatorObserver {
  static void Function(String tur)? girdi;
  static void Function(String tur, Duration sure)? cikti;

  Route<dynamic>? _aktif;
  String? _tur;
  DateTime? _baslangic;

  void _kapa(Route<dynamic>? route) {
    if (route == null || !identical(route, _aktif)) return;
    final tur = _tur!;
    final sure = DateTime.now().difference(_baslangic!);
    _aktif = null;
    _tur = null;
    _baslangic = null;
    cikti?.call(tur, sure);
  }

  void _ac(Route<dynamic> route) {
    if (_aktif != null) return; // falın içindeki alt ekranlar sayılmaz
    final tur = kRotaFal[route.settings.name];
    if (tur == null) return;
    _aktif = route;
    _tur = tur;
    _baslangic = DateTime.now();
    girdi?.call(tur);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _ac(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _kapa(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _kapa(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _kapa(oldRoute);
}
