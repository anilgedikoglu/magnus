// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\AstroTakvim
// JSON:   assets/data/astrotakvim.json
// Görseller: assets/images/astrotakvim/
//
// ⚠️ METIN MOTORU NOTU: Bu klasörde birden fazla madde içeren .asset dosyası tespit edildi.
// Unity `aciklama:` alanı YAML listesidir; her `- "..."` maddesi ayrı JSON girdisi olmalı.
// JSON yeniden üretilirken extract_all_aciklama() tipi parser kullan. Bkz. CLAUDE.md.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// ─── Sprite → Emoji eşlemesi ──────────────────────────────────────────────────

const _spriteMap = <int, String>{
  0: '🙂', 5: '😄', 7: '😉', 10: '☺️', 23: '😎', 73: '👊', 79: '🙏',
  // AstroTakvim kategorileri
  40: '🪙', 86: '🌊', 93: '🔥', 100: '⭐',
};

String _spriteToEmoji(int n) => _spriteMap[n] ?? '✦';

// ─── Rich-text segmenti ───────────────────────────────────────────────────────

class _Seg {
  final String text;
  final Color? color;
  const _Seg(this.text, [this.color]);
}

// ─── Rich-text parser ─────────────────────────────────────────────────────────
// Girdi: Unity metin formatı — <sprite=N>, <color=#RRGGBB>...</color>, \n
// Çıktı: Render edilebilir segment listesi

List<_Seg> _parseText(String raw) {
  // 1) <sprite=N> → emoji
  final spriteSub = raw.replaceAllMapped(
    RegExp(r'<sprite=(\d+)>'),
    (m) => _spriteToEmoji(int.tryParse(m.group(1)!) ?? -1),
  );

  final segs = <_Seg>[];
  final colorRe = RegExp(r'<color=(#[0-9A-Fa-f]{6,8})>(.*?)</color>',
      dotAll: true);

  int cursor = 0;
  for (final m in colorRe.allMatches(spriteSub)) {
    // Öncesindeki düz metin
    if (m.start > cursor) {
      segs.add(_Seg(spriteSub.substring(cursor, m.start)));
    }
    // Renkli metin
    final hexStr = m.group(1)!.replaceFirst('#', '');
    final colorVal = int.tryParse(
          hexStr.length == 6 ? 'FF$hexStr' : hexStr,
          radix: 16,
        ) ??
        0xFFFFFFFF;
    segs.add(_Seg(m.group(2)!, Color(colorVal)));
    cursor = m.end;
  }
  if (cursor < spriteSub.length) {
    segs.add(_Seg(spriteSub.substring(cursor)));
  }

  return segs;
}

// ─── Typewriter: kaç karakter gösterilecek (tag'ler hariç gerçek karakter) ───

int _totalChars(List<_Seg> segs) =>
    segs.fold(0, (s, seg) => s + seg.text.length);

// ─── RichText widget (partial render — typewriter için) ───────────────────────

Widget _buildRichText(
    List<_Seg> segs, int shownChars, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  int remaining = shownChars;

  for (final seg in segs) {
    if (remaining <= 0) break;
    final visible = seg.text.length <= remaining
        ? seg.text
        : seg.text.substring(0, remaining);
    remaining -= visible.length;

    spans.add(TextSpan(
      text: visible,
      style: seg.color != null
          ? baseStyle.copyWith(
              color: seg.color,
              fontWeight: FontWeight.w600,
            )
          : baseStyle,
    ));
  }

  return RichText(text: TextSpan(children: spans));
}

// ─── Veri modeli ──────────────────────────────────────────────────────────────

class _AstroEntry {
  final int? gun;
  final int? ay;
  final int? yil;
  final String metin;
  const _AstroEntry({this.gun, this.ay, this.yil, required this.metin});
}

// ─── Sekme konfigürasyonu ─────────────────────────────────────────────────────

class _TabConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String dataKey;   // JSON anahtarı (genel havuz)
  final String? extraKey; // transit_tarihli gibi ek anahtar
  final String bgImage;
  const _TabConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.dataKey,
    this.extraKey,
    required this.bgImage,
  });
}

// Sıra: Transit · Maneviyat (ay) · Güzellik · Sağlık · Aktivite
// Arka planlar:
//   bg1 = Ay fotoğrafı      → Maneviyat
//   bg2 = Gece koşucu       → Aktivite
//   bg3 = Yılan             → Sağlık
//   bg4 = Güneş sistemi     → Transit
//   guzellik_bg = Falcı kadın → Güzellik
const _tabs = [
  _TabConfig(
    label: 'TRANSİT',
    icon: Icons.public,
    color: Color(0xFF00E5FF),
    dataKey: 'transit',
    extraKey: 'transit_tarihli',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg4.png', // güneş sistemi
  ),
  _TabConfig(
    label: 'MANEVİYAT',
    icon: Icons.nightlight_round, // ay
    color: Color(0xFFBB44FF),
    dataKey: 'maneviyat',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg1.png', // ay fotoğrafı
  ),
  _TabConfig(
    label: 'GÜZELLİK',
    icon: Icons.content_cut,
    color: Color(0xFFFFCC00),
    dataKey: 'guzellik',
    bgImage: 'assets/images/astrotakvim/guzellik_bg.png', // falcı kadın
  ),
  _TabConfig(
    label: 'SAĞLIK',
    icon: Icons.favorite,
    color: Color(0xFFFF4444),
    dataKey: 'saglik',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg3.png', // yılan
  ),
  _TabConfig(
    label: 'AKTİVİTE',
    icon: Icons.directions_run,
    color: Color(0xFFFF9900),
    dataKey: 'aktivite',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg2.png', // gece koşucu
  ),
];

const _gunKisaltmalari = ['PT', 'SA', 'ÇR', 'PE', 'CU', 'CT', 'PA'];

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class AstroTakvimScreen extends ConsumerStatefulWidget {
  const AstroTakvimScreen({super.key});

  @override
  ConsumerState<AstroTakvimScreen> createState() => _AstroTakvimScreenState();
}

class _AstroTakvimScreenState extends ConsumerState<AstroTakvimScreen>
    with TickerProviderStateMixin {
  // ── Veri ──────────────────────────────────────────────────────────────────
  Map<String, List<_AstroEntry>> _data = {};
  bool _dataLoaded = false;

  // ── Durum ─────────────────────────────────────────────────────────────────
  int _activeTab = 0;
  late int _selectedDay;
  late int _currentMonth;
  late int _currentYear;

  // ── Typewriter ────────────────────────────────────────────────────────────
  List<_Seg> _segs = [];
  int _shownChars = 0;
  Timer? _typeTimer;

  // ── Tab geçiş animasyonu ──────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay  = now.day;
    _currentMonth = now.month;
    _currentYear  = now.year;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.value = 1.0;

    _loadData();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Veri yükleme
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/data/astrotakvim.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final parsed = <String, List<_AstroEntry>>{};
    for (final key in json.keys) {
      final list = (json[key] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return _AstroEntry(
          gun:   m['gun']  as int?,
          ay:    m['ay']   as int?,
          yil:   m['yil']  as int?,
          metin: m['metin'] as String,
        );
      }).toList();
      parsed[key] = list;
    }

    if (mounted) {
      setState(() {
        _data = parsed;
        _dataLoaded = true;
      });
      _updateContent(animate: false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // İçerik seçimi
  // ─────────────────────────────────────────────────────────────────────────

  String _findRawText() {
    if (!_dataLoaded) return '';
    final tab = _tabs[_activeTab];

    // Transit: önce tarihli havuza bak
    if (tab.extraKey != null) {
      final dated = _data[tab.extraKey] ?? [];
      for (final e in dated) {
        if (e.gun == _selectedDay && e.ay == _currentMonth) {
          return _applyVars(e.metin);
        }
      }
    }

    // Genel havuz: (day-1) % count ile deterministik seçim
    final pool = _data[tab.dataKey] ?? [];
    if (pool.isEmpty) return 'Bu kategori için içerik yakında ekleniyor.';
    final idx = (_selectedDay - 1) % pool.length;
    return _applyVars(pool[idx].metin);
  }

  String _applyVars(String text) {
    final profile = ref.read(userProfileProvider);
    return VariableReplacer.replace(text, profile.toVariableMap());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Typewriter
  // ─────────────────────────────────────────────────────────────────────────

  void _updateContent({bool animate = true}) {
    _typeTimer?.cancel();
    final rawText = _findRawText();
    final newSegs = _parseText(rawText);
    final total   = _totalChars(newSegs);

    if (!mounted) return;

    if (!animate) {
      setState(() {
        _segs       = newSegs;
        _shownChars = total;
      });
      return;
    }

    setState(() {
      _segs       = newSegs;
      _shownChars = 0;
    });

    int shown = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) { t.cancel(); return; }
      shown += 2; // 2 karakter/tick → daha akıcı
      if (shown >= total) {
        t.cancel();
        shown = total;
      }
      setState(() => _shownChars = shown);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sekme & gün değiştirme
  // ─────────────────────────────────────────────────────────────────────────

  void _switchTab(int tab) {
    if (tab == _activeTab) return;
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _activeTab = tab);
      _updateContent();
      _fadeCtrl.forward();
    });
  }

  void _selectDay(int day) {
    if (day == _selectedDay) return;
    setState(() => _selectedDay = day);
    _updateContent();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Takvim günleri
  // ─────────────────────────────────────────────────────────────────────────

  List<({int day, bool cur})> _buildCalendarDays() {
    final firstDay    = DateTime(_currentYear, _currentMonth, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    final prevMonth   = _currentMonth == 1
        ? DateTime(_currentYear - 1, 12, 1)
        : DateTime(_currentYear, _currentMonth - 1, 1);
    final daysInPrev  =
        DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    final cells = <({int day, bool cur})>[];
    for (int i = startOffset - 1; i >= 0; i--) {
      cells.add((day: daysInPrev - i, cur: false));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add((day: d, cur: true));
    }
    final remaining = (7 - cells.length % 7) % 7;
    for (int d = 1; d <= remaining; d++) {
      cells.add((day: d, cur: false));
    }
    return cells;
  }

  // Transit tarihli havuzda bu gün+ay var mı?
  bool _hasDateEntry(int day) {
    if (!_dataLoaded) return false;
    final tab = _tabs[_activeTab];
    if (tab.extraKey == null) return false;
    final dated = _data[tab.extraKey] ?? [];
    return dated.any((e) => e.gun == day && e.ay == _currentMonth);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tab    = _tabs[_activeTab];
    final accent = tab.color;
    final today  = DateTime.now();
    final isCurMonth =
        today.month == _currentMonth && today.year == _currentYear;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Arka plan ─────────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox.expand(
              child: Image.asset(
                tab.bgImage,
                fit: BoxFit.cover,
                // Transit: sol kenara hizala — sağ taraf kırpılır, ekranı doldurur
                alignment: tab.dataKey == 'transit'
                    ? Alignment.centerLeft
                    : Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0A0A1A)),
              ),
            ),
          ),
          // ── Temel karartma katmanı (tüm sekmeler) ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // ── Ekstra karartma — transit ve maneviyat (yazı okunurluğu) ──────
          if (tab.dataKey == 'transit' || tab.dataKey == 'maneviyat')
            Container(color: Colors.black.withValues(alpha: 0.28)),
          // ── Sayfa içeriği ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTabBar(accent),
                const SizedBox(height: 4),
                // Takvim paneli — AnimatedContainer YOK (titreme önleme)
                // Sadece border rengi TweenAnimationBuilder ile değişir
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: accent),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, color, child) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: color ?? accent, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: child,
                    ),
                    child: Column(
                      children: [
                        _buildDayHeaders(accent),
                        _buildCalendarGrid(accent, isCurMonth, today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // İçerik alanı
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sekme başlığı
                        Center(
                          child: Text(
                            tab.label,
                            style: GoogleFonts.cinzel(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 5,
                              shadows: [
                                Shadow(
                                  color: accent.withValues(alpha: 0.85),
                                  blurRadius: 14,
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Metin (typewriter + renkli)
                        Expanded(
                          child: SingleChildScrollView(
                            child: _dataLoaded
                                ? _buildRichText(
                                    _segs,
                                    _shownChars,
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      height: 1.65,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black87,
                                            blurRadius: 4)
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Geri Dön
                _buildBackButton(accent),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sekme bar  (ev tuşu YOK — geri dön altta)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_tabs.length, (i) => _iconBtn(
          icon: _tabs[i].icon,
          bg: _tabs[i].color.withValues(alpha: _activeTab == i ? 1.0 : 0.45),
          active: _activeTab == i,
          activeColor: _tabs[i].color,
          onTap: () => _switchTab(i),
        )),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color bg,
    required bool active,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: active ? 50 : 44,
        height: active ? 40 : 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: active && activeColor != null
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.65), width: 1.5)
              : null,
          boxShadow: active && activeColor != null
              ? [BoxShadow(
                  color: activeColor.withValues(alpha: 0.55), blurRadius: 8)]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: active ? 21 : 19),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Gün başlıkları
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDayHeaders(Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: _gunKisaltmalari.map((g) => Expanded(
              child: Center(
                child: Text(
                  g,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Takvim grid
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(
      Color accent, bool isCurMonth, DateTime today) {
    final cells = _buildCalendarDays();
    final rows  = <Widget>[];

    for (int r = 0; r < cells.length ~/ 7; r++) {
      rows.add(Row(
        children: cells.sublist(r * 7, r * 7 + 7).map((cell) {
          if (!cell.cur) {
            return Expanded(
              child: SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    '${cell.day}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }

          final day        = cell.day;
          final isToday    = isCurMonth && day == today.day;
          final isSelected = day == _selectedDay;
          final hasDated   = _hasDateEntry(day);

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDay(day),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: accent, width: 2)
                        : isSelected
                            ? Border.all(
                                color: accent.withValues(alpha: 0.65),
                                width: 1.5)
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 0.5),
                    boxShadow: isToday
                        ? [BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 6)]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isToday
                              ? accent
                              : isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: (isToday || isSelected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      // Transit tarihli içeriği olan günlerde parlayan nokta
                      if (hasDated)
                        Positioned(
                          bottom: 3,
                          right: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withValues(alpha: 0.7),
                                    blurRadius: 4)
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
      child: Column(children: rows),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Geri Dön butonu
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBackButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.25), width: 1.2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 2),
              Text('Geri Git',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
