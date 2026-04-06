import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─── Yardımcı: burç bilgileri ─────────────────────────────────────────────────

class _ZodiacInfo {
  static String planet(String? s) {
    const m = {
      'Koç': 'Mars', 'Boğa': 'Venüs', 'İkizler': 'Merkür',
      'Yengeç': 'Ay', 'Aslan': 'Güneş', 'Başak': 'Merkür',
      'Terazi': 'Venüs', 'Akrep': 'Plüton', 'Yay': 'Jüpiter',
      'Oğlak': 'Satürn', 'Kova': 'Uranüs', 'Balık': 'Neptün',
    };
    return m[s] ?? '—';
  }

  // [Kardinal, Değişken, Sabit]
  static List<double> modality(String? s) {
    if ({'Koç', 'Yengeç', 'Terazi', 'Oğlak'}.contains(s)) return [.58, .25, .17];
    if ({'İkizler', 'Başak', 'Yay', 'Balık'}.contains(s)) return [.17, .58, .25];
    if ({'Boğa', 'Aslan', 'Akrep', 'Kova'}.contains(s)) return [.25, .17, .58];
    return [.34, .33, .33];
  }

  // [Feminen, Maskülen]
  static List<double> polarity(String? s) {
    const masc = {'Koç', 'İkizler', 'Aslan', 'Terazi', 'Yay', 'Kova'};
    return masc.contains(s) ? [.35, .65] : [.65, .35];
  }

  // [Ateş, Toprak, Hava, Su]
  static List<double> element(String? s) {
    if ({'Koç', 'Aslan', 'Yay'}.contains(s))     return [.55, .15, .2, .1];
    if ({'Boğa', 'Başak', 'Oğlak'}.contains(s))  return [.1, .55, .2, .15];
    if ({'İkizler', 'Terazi', 'Kova'}.contains(s)) return [.15, .1, .55, .2];
    return [.2, .15, .1, .55];
  }
}

// ─── Donut grafik segmenti ────────────────────────────────────────────────────

class _Seg {
  final Color color;
  final double fraction;
  final String label;
  const _Seg(this.color, this.fraction, this.label);
}

// ─── Donut CustomPainter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  final double strokeWidth;
  const _DonutPainter(this.segments, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const gap = 0.07;
    var start = -pi / 2;

    for (final seg in segments) {
      final sweep = 2 * pi * seg.fraction;
      final glow = Paint()
        ..color = seg.color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, glow);

      final fill = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, fill);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ─── Donut grafik widget ──────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final String title;
  final List<_Seg> segments;
  final double size;

  const _DonutChart({
    required this.title,
    required this.segments,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    final sw = size * 0.17;
    final r = (size - sw) / 2;
    final cx = size / 2;
    final cy = size / 2;

    final labelWidgets = <Widget>[];
    var startAngle = -pi / 2;
    for (final seg in segments) {
      final sweep = 2 * pi * seg.fraction;
      final mid = startAngle + sweep / 2;
      final lr = r + sw * 0.6 + 10;
      final lx = cx + lr * cos(mid);
      final ly = cy + lr * sin(mid);
      labelWidgets.add(
        Positioned(
          left: lx - 28,
          top: ly - 9,
          width: 56,
          child: Text(
            seg.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: seg.color,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ),
      );
      startAngle += sweep;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments, sw),
          ),
          ...labelWidgets,
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bilgi kartı ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDD00BB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFDD00BB), size: 11),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFDD88CC),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final sign = profile.zodiacSign;
    final modSegs = _ZodiacInfo.modality(sign);
    final polSegs = _ZodiacInfo.polarity(sign);
    final elSegs = _ZodiacInfo.element(sign);

    return Scaffold(
      body: Stack(
        children: [
          // ── Uzay arkaplanı
          Positioned.fill(
            child: Image.asset(
              'assets/images/space_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A0A3C)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.38)),
          ),

          // ── İçerik
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, ref, profile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        _buildTitle(),
                        const SizedBox(height: 14),
                        _buildGridSection(profile),
                        const SizedBox(height: 16),
                        _buildDonutRow(modSegs, polSegs, elSegs),
                        const SizedBox(height: 22),
                        _buildMenuButton(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Üst bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white70, size: 26),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Colors.white70, size: 26),
            onPressed: () => _showOptions(context, ref),
          ),
        ],
      ),
    );
  }

  // ── Başlık ───────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'Kullanıcı Bilgileri',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.transparent, Color(0xFF00DDFF), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  // ── Bilgi grid'i ─────────────────────────────────────────────────────────

  Widget _buildGridSection(UserProfile profile) {
    final birth = _formatDate(profile.birthDate);
    final planet = _ZodiacInfo.planet(profile.zodiacSign);

    return Column(
      children: [
        // Üst blok: sol/sağ bilgi kartları + ortada avatar
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol sütun
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Doğum Tarihi',
                        value: birth,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.favorite_rounded,
                        label: 'Medeni Hal',
                        value: profile.maritalStatusLabel.isNotEmpty
                            ? profile.maritalStatusLabel
                            : '—',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Orta: avatar + isim
              SizedBox(
                width: 110,
                child: _buildAvatarCenter(profile),
              ),

              const SizedBox(width: 8),
              // Sağ sütun
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.person_rounded,
                        label: 'Cinsiyet',
                        value: profile.genderLabel.isNotEmpty
                            ? profile.genderLabel
                            : '—',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.work_rounded,
                        label: 'Meslek',
                        value: profile.jobLabel.isNotEmpty
                            ? profile.jobLabel
                            : '—',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Alı 3'lü satırlar
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.access_time_rounded,
                label: 'Doğum Saati',
                value: '—',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.location_on_rounded,
                label: 'Doğum Yeri',
                value: profile.birthCity?.isNotEmpty == true
                    ? profile.birthCity!
                    : '—',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Burç',
                value: profile.zodiacSign?.isNotEmpty == true
                    ? profile.zodiacSign!
                    : '—',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.public_rounded,
                label: 'Gezegen',
                value: planet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.trending_up_rounded,
                label: 'Yükselen',
                value: '—',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.nightlight_rounded,
                label: 'Ay Burcu',
                value: '—',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarCenter(UserProfile profile) {
    final initials = profile.name.isNotEmpty
        ? profile.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : 'M';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00CCFF), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00CCFF).withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ],
            color: const Color(0xFF1A0A3C),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/magnusicon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.name.isNotEmpty ? profile.name : 'Kullanıcı',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Donut grafikler ───────────────────────────────────────────────────────

  Widget _buildDonutRow(
    List<double> mod,
    List<double> pol,
    List<double> el,
  ) {
    return Column(
      children: [
        // Modalite
        _DonutChart(
          title: 'Modalite',
          size: 120,
          segments: [
            _Seg(const Color(0xFFFFDD00), mod[0], 'Kardinal'),
            _Seg(const Color(0xFF00EE88), mod[1], 'Değişken'),
            _Seg(const Color(0xFF00CCFF), mod[2], 'Sabit'),
          ],
        ),
        const SizedBox(height: 12),
        // Polarite + Element - yan yana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DonutChart(
              title: 'Polarite',
              size: 120,
              segments: [
                _Seg(const Color(0xFFAA44FF), pol[0], 'Feminen'),
                _Seg(const Color(0xFF00CCAA), pol[1], 'Maskülen'),
              ],
            ),
            _DonutChart(
              title: 'Element',
              size: 120,
              segments: [
                _Seg(const Color(0xFFFF6622), el[0], 'Ateş'),
                _Seg(const Color(0xFF88DD00), el[1], 'Toprak'),
                _Seg(const Color(0xFF00AAFF), el[2], 'Hava'),
                _Seg(const Color(0xFF0066FF), el[3], 'Su'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Ana Menü butonu ───────────────────────────────────────────────────────

  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCC00AA), Color(0xFF8800CC)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCC00AA).withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Ana Menü',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Ayarlar dialog ────────────────────────────────────────────────────────

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A3C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFDD00BB), width: 1),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded,
                  color: Color(0xFFFF8800)),
              title: const Text('Profili Sıfırla',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmReset(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF3333)),
              title: const Text('Tüm Falları Sil',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteInbox(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(String? bd) {
    if (bd == null || bd.isEmpty) return '—';
    final p = bd.split('-');
    if (p.length != 3) return bd;
    return '${p[2]}.${p[1]}.${p[0]}';
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A3C),
        title: const Text('Profili sıfırla?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm bilgilerin silinir ve yeniden tanışma ekranına gidersin.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sıfırla',
                style: TextStyle(color: Color(0xFFFF3333))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(userProfileProvider.notifier).save(UserProfile.empty());
      if (context.mounted) context.go('/onboarding');
    }
  }

  Future<void> _confirmDeleteInbox(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A3C),
        title: const Text('Tüm falları sil?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Bu işlem geri alınamaz.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: Color(0xFFFF3333))),
          ),
        ],
      ),
    );
    if (ok == true) {
      final items = ref.read(inboxProvider);
      for (final item in items) {
        await ref.read(inboxProvider.notifier).deleteItem(item.id);
      }
    }
  }
}
