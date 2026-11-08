// lib/presentation/shell/notification_sync.dart
//
// Gelen kutusu ya da bildirim ayarı değişince bekleyen "falın hazır" bildirimlerini yeniden
// kurar; bildirime dokunulunca Gelen Kutusu sekmesini açar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import 'main_tabs.dart';

class NotificationSync extends ConsumerStatefulWidget {
  const NotificationSync({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<NotificationSync> createState() => _NotificationSyncState();
}

class _NotificationSyncState extends ConsumerState<NotificationSync> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onOpened = _openInbox;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sync();
      if (await NotificationService.instance.launchedFromNotification()) _openInbox();
    });
  }

  void _openInbox() {
    if (!mounted) return;
    ref.read(mainTabProvider.notifier).state = MainTab.inbox;
    widget.router.go('/home');
  }

  Future<void> _sync() async {
    if (!mounted) return;
    if (pendingForNotification(ref.read(inboxProvider), DateTime.now()).isNotEmpty) {
      await ref.read(notificationsEnabledProvider.notifier).askOnce();
      if (!mounted) return;
    }
    final s = ref.read(l10nProvider);
    NotificationService.instance.sync(
      enabled: ref.read(notificationsEnabledProvider),
      items: ref.read(inboxProvider),
      title: s.fortuneReadyTitle,
      channelName: s.notificationsChannel,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<InboxItem>>(inboxProvider, (_, __) => _sync());
    ref.listen<bool>(notificationsEnabledProvider, (_, __) => _sync());
    return widget.child;
  }
}
