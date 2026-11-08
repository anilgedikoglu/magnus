// lib/core/services/notification_service.dart
//
// "Falın hazır" bildirimleri (Anıl, 2026-11-08). Fallar cihazda üretildiği için sunucu yok:
// bildirim, kilidin açılacağı ana (InboxItem.unlockAt) yerel olarak zamanlanır; uygulama kapalıyken
// de gelir. Kapatılınca bekleyenlerin hepsi iptal edilir. Android'de tam-zaman izni istenmez
// (inexact): fal birkaç dakika sonra hazır olduğundan küçük gecikme önemsizdir.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/inbox_item.dart';

/// [id] için kararlı, pozitif 31 bit bildirim numarası (FNV-1a).
int notificationIdFor(String id) {
  var h = 0x811c9dc5;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// Zamanlanacak öğeler: kilidi ileride açılanlar.
List<InboxItem> pendingForNotification(List<InboxItem> items, DateTime now) => [
      for (final e in items)
        if ((DateTime.tryParse(e.unlockAt ?? '')?.isAfter(now)) ?? false) e,
    ];

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;
  VoidCallback? onOpened;

  Future<void> _ensureInit() => _init ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_magnus'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onOpened?.call(),
    );
  }

  /// Uygulama bildirime dokunularak mı açıldı?
  Future<bool> launchedFromNotification() async {
    try {
      await _ensureInit();
      final d = await _plugin.getNotificationAppLaunchDetails();
      return d?.didNotificationLaunchApp ?? false;
    } catch (e) {
      debugPrint('Bildirim başlatma bilgisi alınamadı: $e');
      return false;
    }
  }

  /// İzin ister; verilirse true.
  Future<bool> requestPermission() async {
    try {
      await _ensureInit();
      if (Platform.isAndroid) {
        final a = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await a?.requestNotificationsPermission() ?? false;
      }
      if (Platform.isIOS) {
        final i = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
    } catch (e) {
      debugPrint('Bildirim izni istenemedi: $e');
    }
    return false;
  }

  /// Bekleyenleri baştan kurar. [enabled] false ise yalnız iptal eder.
  Future<void> sync({
    required bool enabled,
    required List<InboxItem> items,
    required String title,
    required String channelName,
  }) async {
    try {
      await _ensureInit();
      await _plugin.cancelAllPendingNotifications();
      if (!enabled) return;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'fal_hazir',
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      final now = DateTime.now().add(const Duration(seconds: 2));
      for (final e in pendingForNotification(items, now)) {
        await _plugin.zonedSchedule(
          id: notificationIdFor(e.id),
          scheduledDate: tz.TZDateTime.from(DateTime.parse(e.unlockAt!).toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: e.title,
        );
      }
    } catch (e) {
      debugPrint('Bildirimler zamanlanamadı: $e');
    }
  }
}
