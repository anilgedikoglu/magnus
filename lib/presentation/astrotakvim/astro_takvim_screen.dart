// Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\AstroTakvim
// JSON:   assets/data/astrotakvim.json
// Görseller: assets/images/astrotakvim/

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';

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
  final String dataKey;
  final String bgImage;
  const _TabConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.dataKey,
    required this.bgImage,
  });
}

const _tabs = [
  _TabConfig(
    label: 'TRANSİT',
    icon: Icons.nightlight_round,
    color: Color(0xFF00E5FF),
    dataKey: 'transit',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg1.png',
  ),
  _TabConfig(
    label: 'AKTİVİTE',
    icon: Icons.content_cut,
    color: Color(0xFFFFCC00),
    dataKey: 'aktivite',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg3.png',
  ),
  _TabConfig(
    label: 'SAĞLIK',
    icon: Icons.favorite,
    color: Color(0xFFFF3333),
    dataKey: 'saglik',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg4.png',
  ),
  _TabConfig(
    label: 'GÜZELLİK',
    icon: Icons.auto_awesome,
    color: Color(0xFFFF66CC),
    dataKey: 'guzellik',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg2.png',
  ),
  _TabConfig(
    label: 'MANEVİYAT',
    icon: Icons.blur_circular,
    color: Color(0xFFBB44FF),
    dataKey: 'maneviyat',
    bgImage: 'assets/images/astrotakvim/astrotakvim_bg2.png',
  ),
];

// ─── Türkçe gün kısaltmaları (Pazartesi başlangıçlı) ─────────────────────────
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
  int _activeTab = 0; // 0=transit, 1=aktivite, 2=saglik, 3=guzellik, 4=maneviyat
  late int _selectedDay;
  late int _currentMonth;
  late int _currentYear;

  // ── Typewriter ────────────────────────────────────────────────────────────
  String _fullText = '';
  String _shownText = '';
  Timer? _typeTimer;

  // ── Animasyon (tab geçişi) ─────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 300),
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

  // ── Veri yükleme ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/data/astrotakvim.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final parsed = <String, List<_AstroEntry>>{};
    for (final key in json.keys) {
      final list = (json[key] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return _AstroEntry(
          gun: m['gun'] as int?,
          ay: m['ay'] as int?,
          yil: m['yil'] as int?,
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

  // ── İçerik bulma ──────────────────────────────────────────────────────────

  /// Seçili gün + aktif sekme için en uygun metni bul.
  /// Önce gün+ay eşleşmesi arar, bulamazsa önceki en yakın gün+ay'ı döner.
  String _findContent() {
    if (!_dataLoaded) return '';
    final entries = _data[_tabs[_activeTab].dataKey] ?? [];
    if (entries.isEmpty) return 'Bu kategori için içerik yakında ekleniyor.';

    // Tam eşleşme: aynı gün ve ay
    for (final e in entries) {
      if (e.gun == _selectedDay && e.ay == _currentMonth) {
        return _applyVars(e.metin);
      }
    }

    // En yakın önceki gün+ay (yılı görmezden gel)
    // Seçili günü sayısal sırayla bul: ay*100 + gun
    final selVal = _currentMonth * 100 + _selectedDay;
    _AstroEntry? best;
    int bestDiff = 99999;
    for (final e in entries) {
      if (e.gun == null || e.ay == null) continue;
      final eVal = e.ay! * 100 + e.gun!;
      // Dairesel mesafe: önceki en yakın
      int diff = selVal - eVal;
      if (diff < 0) diff += 1200; // 12 ay döngüsü
      if (diff < bestDiff) {
        bestDiff = diff;
        best = e;
      }
    }
    if (best != null) return _applyVars(best.metin);

    return 'Bu tarih için içerik bulunmuyor.';
  }

  String _applyVars(String text) {
    final profile = ref.read(userProfileProvider);
    final name = profile.name.isNotEmpty ? profile.name : 'Sevgili';
    return text.replaceAll('{{isim}}', name).replaceAll('{{burc}}', profile.zodiacSign ?? 'Koç');
  }

  // ── Typewriter ────────────────────────────────────────────────────────────

  void _updateContent({bool animate = true}) {
    _typeTimer?.cancel();
    final newText = _findContent();
    if (!mounted) return;

    if (!animate) {
      setState(() {
        _fullText = newText;
        _shownText = newText;
      });
      return;
    }

    setState(() {
      _fullText = newText;
      _shownText = '';
    });

    int idx = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (idx >= _fullText.length) {
        timer.cancel();
        return;
      }
      setState(() => _shownText = _fullText.substring(0, idx + 1));
      idx++;
    });
  }

  // ── Sekme değiştirme ──────────────────────────────────────────────────────

  void _switchTab(int tab) {
    if (tab == _activeTab) return;
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _activeTab = tab);
      _updateContent();
      _fadeCtrl.forward();
    });
  }

  // ── Gün seçme ─────────────────────────────────────────────────────────────

  void _selectDay(int day) {
    if (day == _selectedDay) return;
    setState(() => _selectedDay = day);
    _updateContent();
  }

  // ── Takvim günleri hesapla ────────────────────────────────────────────────

  /// Geçerli ayın tüm günlerini (önceki aydan dolgu dahil) döndür.
  /// Her eleman: (gün numarası, geçerli ay mı)
  List<({int day, bool currentMonth})> _buildCalendarDays() {
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    // Pazartesi = 1 → offset = weekday - 1
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    final prevMonth = _currentMonth == 1
        ? DateTime(_currentYear - 1, 12, 1)
        : DateTime(_currentYear, _currentMonth - 1, 1);
    final daysInPrev = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    final cells = <({int day, bool currentMonth})>[];

    // Önceki aydan doldur
    for (int i = startOffset - 1; i >= 0; i--) {
      cells.add((day: daysInPrev - i, currentMonth: false));
    }
    // Mevcut ay
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add((day: d, currentMonth: true));
    }
    // Sonraki aydan dolgu (satırı tamamla)
    final remaining = (7 - cells.length % 7) % 7;
    for (int d = 1; d <= remaining; d++) {
      cells.add((day: d, currentMonth: false));
    }

    return cells;
  }

  // ─── Takvim günü rengi (veri olan günler) ─────────────────────────────────

  bool _hasData(int day) {
    if (!_dataLoaded) return false;
    final entries = _data[_tabs[_activeTab].dataKey] ?? [];
    return entries.any((e) => e.gun == day && e.ay == _currentMonth);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_activeTab];
    final accent = tab.color;
    final today = DateTime.now();
    final isCurrentMonth =
        today.month == _currentMonth && today.year == _currentYear;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Arka plan görseli ──────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox.expand(
              child: Image.asset(
                tab.bgImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),
          ),
          // ── Üst siyah sis overlay ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
          // ── Ana içerik ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Üst sekme butonları ──────────────────────────────────────
                _buildTabBar(accent),
                const SizedBox(height: 6),
                // ── Takvim paneli (kenarlıklı) ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Column(
                      children: [
                        _buildDayHeaders(accent),
                        _buildCalendarGrid(accent, isCurrentMonth, today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── İçerik alanı ─────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sekme başlığı
                        Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontFamily: 'ChixaDemiBold',
                              fontSize: 18,
                              color: accent,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                    color: accent.withOpacity(0.8),
                                    blurRadius: 10)
                              ],
                            ),
                            child: Text(tab.label),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Metin (typewriter)
                        Expanded(
                          child: SingleChildScrollView(
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Text(
                                _shownText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  height: 1.6,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black87, blurRadius: 4)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Geri Dön butonu ──────────────────────────────────────────
                _buildBackButton(accent),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sekme bar ─────────────────────────────────────────────────────────────

  Widget _buildTabBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Ev butonu (geri dön)
          _buildIconBtn(
            icon: Icons.home_rounded,
            bgColor: const Color(0xFF00BCD4),
            isActive: false,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 4),
          // Kategori sekmeleri
          ...List.generate(_tabs.length, (i) {
            final t = _tabs[i];
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _buildIconBtn(
                icon: t.icon,
                bgColor: t.color.withOpacity(_activeTab == i ? 1.0 : 0.5),
                isActive: _activeTab == i,
                activeColor: t.color,
                onTap: () => _switchTab(i),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required Color bgColor,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 52 : 46,
        height: isActive ? 42 : 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isActive && activeColor != null
              ? Border.all(color: Colors.white.withOpacity(0.7), width: 1.5)
              : null,
          boxShadow: isActive && activeColor != null
              ? [BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 8)]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isActive ? 22 : 20,
        ),
      ),
    );
  }

  // ── Gün başlıkları ────────────────────────────────────────────────────────

  Widget _buildDayHeaders(Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: _gunKisaltmalari.map((g) {
          return Expanded(
            child: Center(
              child: Text(
                g,
                style: TextStyle(
                  color: accent.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Takvim grid ───────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(
      Color accent, bool isCurrentMonth, DateTime today) {
    final cells = _buildCalendarDays();
    final rows = <Widget>[];

    for (int row = 0; row < cells.length / 7; row++) {
      final rowCells = cells.sublist(row * 7, row * 7 + 7);
      rows.add(
        Row(
          children: rowCells.map((cell) {
            if (!cell.currentMonth) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        '${cell.day}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final day = cell.day;
            final isToday = isCurrentMonth && day == today.day;
            final isSelected = day == _selectedDay;
            final hasData = _hasData(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => _selectDay(day),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: accent, width: 2)
                          : isSelected
                              ? Border.all(
                                  color: accent.withOpacity(0.7), width: 1.5)
                              : Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 0.5),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                  color: accent.withOpacity(0.5),
                                  blurRadius: 6)
                            ]
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
                                    : Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        // Veri noktası (sağ alt)
                        if (hasData)
                          Positioned(
                            bottom: 3,
                            right: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
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
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
      child: Column(children: rows),
    );
  }

  // ── Geri Dön butonu ───────────────────────────────────────────────────────

  Widget _buildBackButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.18),
            border: Border.all(color: accent.withOpacity(0.7), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'Geri Dön',
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
