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
import '../../core/constants/app_colors.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/grimoire_backdrop.dart';
import '../../core/widgets/occult_cards.dart';
import '../../core/utils/rich_text_parser.dart';
import '../../core/utils/variable_replacer.dart';
import '../../data/providers.dart';

// Typewriter renders complete color tags through the shared parser.
class _Seg {
  final String text;
  final String? color;
  const _Seg(this.text, [this.color]);
}

List<_Seg> _parseText(String raw) {
  final clean = raw.replaceAll(
    RegExp(r'<sprite=[^>]*>|</?[bi]>', caseSensitive: false),
    '',
  );
  final pattern = RegExp(
    r'<color=([^>]+)>(.*?)</color>',
    dotAll: true,
    caseSensitive: false,
  );
  final segs = <_Seg>[];
  var cursor = 0;
  for (final m in pattern.allMatches(clean)) {
    if (m.start > cursor) segs.add(_Seg(clean.substring(cursor, m.start)));
    segs.add(_Seg(m.group(2)!, m.group(1)));
    cursor = m.end;
  }
  if (cursor < clean.length) segs.add(_Seg(clean.substring(cursor)));
  return segs;
}

int _totalChars(List<_Seg> segs) =>
    segs.fold(0, (s, seg) => s + seg.text.length);
Widget _buildRichText(List<_Seg> segs, int shownChars, TextStyle baseStyle) {
  final visible = StringBuffer();
  var remaining = shownChars;
  for (final seg in segs) {
    if (remaining <= 0) break;
    final text = seg.text.substring(0, remaining.clamp(0, seg.text.length));
    remaining -= text.length;
    visible.write(
      seg.color == null ? text : '<color=${seg.color}>$text</color>',
    );
  }
  return RichTextParser.build(visible.toString(), style: baseStyle);
}

class _AstroEntry {
  final int? gun;
  final int? ay;
  final int? yil;
  final String metin;
  final String metinEn;
  const _AstroEntry({
    this.gun,
    this.ay,
    this.yil,
    required this.metin,
    this.metinEn = '',
  });
  String metinFor(bool isEn) => (isEn && metinEn.isNotEmpty) ? metinEn : metin;
}

// ─── Sekme konfigürasyonu ─────────────────────────────────────────────────────

class _TabConfig {
  final IconData icon;
  final String dataKey; // JSON anahtarı (genel havuz)
  final String? extraKey; // transit_tarihli gibi ek anahtar
  final String bgImage;
  const _TabConfig({
    required this.icon,
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
    icon: Icons.public,
    dataKey: 'transit',
    extraKey: 'transit_tarihli',
    bgImage: 'assets/images/astrotakvim/transit_bg.jpg',
  ),
  _TabConfig(
    icon: Icons.nightlight_outlined, // ay
    dataKey: 'maneviyat',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg1.png', // ay fotoğrafı
  ),
  _TabConfig(
    icon: Icons.content_cut,
    dataKey: 'guzellik',
    bgImage: 'assets/images/astrotakvim/guzellik_bg.png', // falcı kadın
  ),
  _TabConfig(
    icon: Icons.favorite_border,
    dataKey: 'saglik',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg3.png', // yılan
  ),
  _TabConfig(
    icon: Icons.directions_run,
    dataKey: 'aktivite',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg2.png', // gece koşucu
  ),
];

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
    _selectedDay = now.day;
    _currentMonth = now.month;
    _currentYear = now.year;

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
      final list =
          (json[key] as List).map((e) {
            final m = e as Map<String, dynamic>;
            return _AstroEntry(
              gun: m['gun'] as int?,
              ay: m['ay'] as int?,
              yil: m['yil'] as int?,
              metin: m['metin'] as String,
              metinEn: (m['metin_en'] as String?) ?? '',
            );
          }).toList();
      parsed[key] = list;
    }

    if (mounted) {
      setState(() {
        _data = parsed;
        _dataLoaded = true;
      });
      _updateContent();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // İçerik seçimi
  // ─────────────────────────────────────────────────────────────────────────

  String _findRawText() {
    if (!_dataLoaded) return '';
    final tab = _tabs[_activeTab];

    final isEn = ref.read(localeProvider) == 'en';

    // Transit: önce tarihli havuza bak
    if (tab.extraKey != null) {
      final dated = _data[tab.extraKey] ?? [];
      for (final e in dated) {
        if (e.gun == _selectedDay && e.ay == _currentMonth) {
          return _applyVars(e.metinFor(isEn));
        }
      }
    }

    // Genel havuz: (day-1) % count ile deterministik seçim
    final pool = _data[tab.dataKey] ?? [];
    if (pool.isEmpty) {
      return isEn
          ? 'Content for this category is coming soon.'
          : 'Bu kategori için içerik yakında ekleniyor.';
    }
    final idx = (_selectedDay - 1) % pool.length;
    return _applyVars(pool[idx].metinFor(isEn));
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
    final total = _totalChars(newSegs);

    if (!mounted) return;

    if (!animate) {
      setState(() {
        _segs = newSegs;
        _shownChars = total;
      });
      return;
    }

    setState(() {
      _segs = newSegs;
      _shownChars = 0;
    });

    int shown = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
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
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    final prevMonth =
        _currentMonth == 1
            ? DateTime(_currentYear - 1, 12, 1)
            : DateTime(_currentYear, _currentMonth - 1, 1);
    final daysInPrev = DateUtils.getDaysInMonth(
      prevMonth.year,
      prevMonth.month,
    );

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

  String _tabLabel(int i) =>
      (ref.watch(localeProvider) == 'en'
          ? ['Transit', 'Spirituality', 'Beauty', 'Health', 'Activity']
          : ['Transit', 'Maneviyat', 'Güzellik', 'Sağlık', 'Aktivite'])[i];
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCurMonth =
        today.month == _currentMonth && today.year == _currentYear;
    final isEn = ref.watch(localeProvider) == 'en';
    return Scaffold(
      backgroundColor: AppColors.ink,
      extendBody: true,
      body: GrimoireBackdrop(
        asset: _tabs[_activeTab].bgImage,
        imageSaturation: 0.18,
        imageBrightness: 0.55,
        child: NoEdgeSwipeBack(edgeOnly: true, child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final vx = details.primaryVelocity ?? 0;
            if (vx.abs() < 300) return;
            if (vx < 0 && _activeTab < _tabs.length - 1) {
              _switchTab(_activeTab + 1);
            } else if (vx > 0 && _activeTab > 0) {
              _switchTab(_activeTab - 1);
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isEn ? 'Astro Calendar' : 'AstroTakvim',
                    style: AppTextStyles.screenTitle,
                  ),
                ),
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassPanel(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Text(
                                '$_currentYear · ${_currentMonth.toString().padLeft(2, '0')}',
                                style: AppTextStyles.meta.copyWith(
                                  fontFeatures: AppTextStyles.tabular,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDayHeaders(isEn),
                              _buildCalendarGrid(isCurMonth, today),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        OccultSectionLabel(_tabLabel(_activeTab)),
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: GlassPanel(
                            variant: GlassVariant.reading,
                            padding: const EdgeInsets.all(18),
                            child:
                                !_dataLoaded
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.gold,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : _buildRichText(
                                      _segs,
                                      _shownChars,
                                      AppTextStyles.reading,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBackButton(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GlassPanel(
      shadow: false,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == _activeTab;
          final label = _tabLabel(i);
          return Expanded(
            child: Semantics(
              button: true,
              selected: active,
              label: label,
              child: Tooltip(
                message: label,
                child: GestureDetector(
                  onTap: () => _switchTab(i),
                  child: GlassPanel(
                    variant: GlassVariant.button,
                    selected: active,
                    shadow: false,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Icon(
                        _tabs[i].icon,
                        size: 22,
                        color: active ? AppColors.gold : AppColors.ash,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
  Widget _buildDayHeaders(bool isEn) {
    final labels =
        isEn
            ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
            : ['Pt', 'Sa', 'Çr', 'Pe', 'Cu', 'Ct', 'Pa'];
    return Row(
      children:
          labels
              .map(
                (label) => Expanded(
                  child: Center(child: Text(label, style: AppTextStyles.meta)),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCalendarGrid(bool isCurMonth, DateTime today) {
    final cells = _buildCalendarDays();
    return Column(
      children: List.generate(
        cells.length ~/ 7,
        (r) => Row(
          children:
              cells.sublist(r * 7, r * 7 + 7).map((cell) {
                final selected = cell.cur && cell.day == _selectedDay;
                final isToday = cell.cur && isCurMonth && cell.day == today.day;
                final dated = cell.cur && _hasDateEntry(cell.day);
                return Expanded(
                  child: Semantics(
                    selected: selected,
                    button: cell.cur,
                    child: GestureDetector(
                      onTap: cell.cur ? () => _selectDay(cell.day) : null,
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? AppColors.glassTintSelected
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selected ? AppColors.gold : Colors.transparent,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${cell.day}',
                              style: AppTextStyles.meta.copyWith(
                                color:
                                    cell.cur ? AppColors.bone : AppColors.ash,
                                fontFeatures: AppTextStyles.tabular,
                                fontWeight:
                                    selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                            if (isToday)
                              Positioned(
                                bottom: 3,
                                child: _dot(AppColors.gold),
                              ),
                            if (dated)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: _dot(AppColors.silver),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 3,
    height: 3,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: AppColors.bone.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.bone,
              size: 20,
            ),
            const SizedBox(width: 2),
            Text(
              ref.read(l10nProvider).backButton,
              style: const TextStyle(
                color: AppColors.bone,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
