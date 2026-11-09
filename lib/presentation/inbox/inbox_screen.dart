import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/magnus_ses/magnus_fal_adlari.dart';
import '../../core/magnus_ses/magnus_hafiza.dart';
import '../../core/services/ad_pacing.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/odul_teklifi.dart';
import '../../core/widgets/glass_tab_bar.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';
import '../shell/main_tabs.dart';
import '../home/home_screen.dart' show kHomeBackground;
import 'widgets/inbox_item_card.dart';
import 'inbox_detail_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxProvider);
    final s = ref.watch(l10nProvider);

    // Başlık bandı sabit ve opak: liste altında kesilir, başlığın üstüne binmez (Anıl, 2026-11-08).
    return Scaffold(
      // Zemin ana menüyle aynı düz renk (Anıl, 2026-11-06).
      backgroundColor: kHomeBackground,
      appBar: AppBar(
        backgroundColor: kHomeBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(s.inboxTitle, style: AppTextStyles.screenTitle),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: Text(
                s.clearAll,
                style: AppTextStyles.uiLabel.copyWith(
                  fontSize: 13,
                  color: AppColors.ash,
                ),
              ),
            ),
        ],
      ),
      body: ColoredBox(color: kHomeBackground, child: GestureDetector(
        // Boş kutuda içerik yalnız ortadaki ikon/metin → opak, tüm alan kaydırmayı yakalar.
        behavior: HitTestBehavior.opaque,
        // Soldan sağa swipe → ana menü (barda solda); sağdan sola → Kullanıcı Bilgileri
        // (barda sağda). Tek başına rotadaysa soldan sağa = geri.
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          final inTabs = MainTabsScope.maybeOf(context) != null;
          if (v > 200) {
            if (inTabs) {
              // Ana menü SOLDAN gelip gelen kutusunun üstünü örter (Anıl 2026-11-05).
              selectMainTab(context, MainTab.home, entry: TabEntry.left);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (v < -200 && inTabs) {
            selectMainTab(context, MainTab.profile, entry: TabEntry.right);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty(s)
                  : _buildList(context, ref, items),
            ),
            // Sekme kapsayıcısında "Geri Git" yerine cam alt bar (MainTabsScreen) var;
            // tek başına açıldıysa (ör. /inbox-full) eski buton yedek olarak kalır.
            if (MainTabsScope.maybeOf(context) == null) _buildBackButton(context, s),
          ],
        ),
      )),
    );
  }

  Widget _buildBackButton(BuildContext context, AppStrings s) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 2),
                Text(
                  s.backButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Boş kutu: sessiz zarf glifi (kül) + Cinzel başlık + kül açıklama. Neon ✦ / renkli
  // gradyan YOK; zemin üstteki ortak atmosfer.
  Widget _buildEmpty(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drafts_outlined,
                size: 44, color: AppColors.ash.withValues(alpha: 0.55)),
            const SizedBox(height: 22),
            Text(
              s.inboxEmpty,
              style: AppTextStyles.screenTitle.copyWith(letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              s.inboxEmptyDesc,
              style: AppTextStyles.meta.copyWith(fontSize: 13.5, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<InboxItem> items) {
    // Liste camın ARKASINA uzanır (Codex: aksi hâlde cam düz zemin üstünde kalır);
    // son öğe barın üstüne kaydırılabilsin diye alta bar kadar pay.
    final inTabs = MainTabsScope.maybeOf(context) != null;
    final bottomPad = inTabs
        ? MediaQuery.paddingOf(context).bottom + kGlassBarReserve + 12
        : 12.0;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(0, 6, 0, bottomPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.6,
        color: AppColors.bone.withValues(alpha: 0.08),
        indent: 80,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InboxItemCard(
          item: item,
          onTap: () => _openDetail(context, ref, item),
          onLockedTap: () => _openLocked(context, ref, item),
          onDismissed: () => ref.read(inboxProvider.notifier).deleteItem(item.id),
        );
      },
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, InboxItem item) {
    _navigateToDetail(context, ref, item);
  }

  /// Hazırlanan (kilitli) karta dokunuş: kullanıcı isterse ödüllü reklamla fal hemen hazır olur.
  /// Reklam hazır değil / sınır dolu ise kart eski davranışında (dokunuş bir şey yapmaz).
  Future<void> _openLocked(BuildContext context, WidgetRef ref, InboxItem item) async {
    if (!item.isLocked) {
      _openDetail(context, ref, item); // liste geç yenilendiyse kilit çoktan bitmiştir
      return;
    }
    if (!item.hemenAcmayaDeger || !AdService.instance.odulMumkun(OdulTuru.hemenAc)) return;
    final notifier = ref.read(inboxProvider.notifier); // await'ten ÖNCE
    final kazandi = await ref.hemenAcTeklifi(context);
    if (kazandi) await notifier.unlockNow(item.id);
  }

  void _navigateToDetail(BuildContext context, WidgetRef ref, InboxItem item) {
    if (!item.isRead) {
      ref.read(inboxProvider.notifier).markRead(item.id);
      final tur = falTuruGelenKutusu(item.fortuneTypeKey);
      if (tur != null) MagnusHafiza.aktif?.okundu(tur, DateTime.now());
    }
    final basla = DateTime.now();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => InboxDetailScreen(item: item)))
        .then((_) {
      // Okunan faldan çıkış doğal ara: geçiş reklamı (sınırlar AdPacing'de, yeterince okunduysa).
      if (DateTime.now().difference(basla) >= AdPacing.gecisIcinMinSure) {
        AdService.instance.maybeShowInterstitial(
            tamamlananFal: MagnusHafiza.aktif?.tamamlananFal ?? 0);
      }
    });
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final s = ref.read(l10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.rim, width: 0.8),
        ),
        title: Text(s.deleteAllConfirm, style: AppTextStyles.inboxTitle),
        content: Text(
          s.deleteAllSubtitle,
          style: AppTextStyles.inboxDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: AppTextStyles.answerText.copyWith(
                  color: AppColors.textMuted,
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: AppTextStyles.answerText.copyWith(
                  color: AppColors.danger,
                )),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Hazırlanmakta olan (kilitli) falları silme, gerisini sil
      final items = ref.read(inboxProvider);
      for (final item in items) {
        if (!item.isLocked) {
          await ref.read(inboxProvider.notifier).deleteItem(item.id);
        }
      }
    }
  }
}
