import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
}

// ─── Dinamik burç skoru hesaplama ─────────────────────────────────────────────

class _ZodiacCalc {
  static const _elements = [
    'Ateş','Toprak','Hava','Su','Ateş','Toprak',
    'Hava','Su','Ateş','Toprak','Hava','Su',
  ];
  static const _modalities = [
    'Kardinal','Sabit','Değişken','Kardinal','Sabit','Değişken',
    'Kardinal','Sabit','Değişken','Kardinal','Sabit','Değişken',
  ];
  static const _polarities = [
    'Maskülen','Feminen','Maskülen','Feminen','Maskülen','Feminen',
    'Maskülen','Feminen','Maskülen','Feminen','Maskülen','Feminen',
  ];

  /// Burç indeksini ay+gün'e göre döndürür.
  static int signIndex(int month, int day) {
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 9;  // Oğlak
    if ((month == 1  && day >= 20) || (month == 2 && day <= 18)) return 10; // Kova
    if ((month == 2  && day >= 19) || (month == 3 && day <= 20)) return 11; // Balık
    if ((month == 3  && day >= 21) || (month == 4 && day <= 19)) return 0;  // Koç
    if ((month == 4  && day >= 20) || (month == 5 && day <= 20)) return 1;  // Boğa
    if ((month == 5  && day >= 21) || (month == 6 && day <= 20)) return 2;  // İkizler
    if ((month == 6  && day >= 21) || (month == 7 && day <= 22)) return 3;  // Yengeç
    if ((month == 7  && day >= 23) || (month == 8 && day <= 22)) return 4;  // Aslan
    if ((month == 8  && day >= 23) || (month == 9 && day <= 22)) return 5;  // Başak
    if ((month == 9  && day >= 23) || (month == 10 && day <= 22)) return 6; // Terazi
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 7; // Akrep
    return 8; // Yay
  }

  /// Burç içindeki ilerleme oranı 0.0–1.0
  static double _progress(DateTime d, int idx) {
    // Her burcun yaklaşık başlangıç günü (yıl günü bazında, sabit yıl)
    const starts = [79, 110, 141, 172, 204, 235, 266, 296, 326, 356, 20, 50];
    // (Oğlak 356 = 22 Ara, Kova 20 = 20 Oca, Balık 50 = 19 Şub; Koç 79 = 21 Mar ...)
    final doy = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
    int start = starts[idx];
    int end   = starts[(idx + 1) % 12];
    // Yıl sonu/başı geçişlerini düzelt
    if (end <= start) end += 365;
    int elapsed = doy - start;
    if (elapsed < 0) elapsed += 365;
    final total = end - start;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  static const _signNames = [
    'Koç','Boğa','İkizler','Yengeç','Aslan','Başak',
    'Terazi','Akrep','Yay','Oğlak','Kova','Balık',
  ];

  static int _nameIdx(String? name) =>
      name != null ? _signNames.indexOf(name) : -1;

  /// Güneş/yükselen/ay burcuna göre element/modalite/polarite oranlarını hesaplar.
  /// risingSign ve moonSign dahil → değişince donutlar güncellenir.
  static Map<String, double> compute(
      String? birthDateStr, {String? risingSign, String? moonSign}) {
    const equal = {
      'Ateş': 0.25, 'Toprak': 0.25, 'Hava': 0.25, 'Su': 0.25,
      'Kardinal': 0.34, 'Sabit': 0.33, 'Değişken': 0.33,
      'Maskülen': 0.50, 'Feminen': 0.50,
    };
    if (birthDateStr == null || birthDateStr.isEmpty) return equal;
    final parts = birthDateStr.split('-');
    if (parts.length != 3) return equal;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

    final mainIdx = signIndex(d.month, d.day);
    final prevIdx = (mainIdx - 1 + 12) % 12;
    final nextIdx = (mainIdx + 1) % 12;
    final p = _progress(d, mainIdx);

    // Aynı elementteki diğer 2 burç
    final mainEl = _elements[mainIdx];
    final sameEl = <int>[];
    for (int i = 0; i < 12; i++) {
      if (i != mainIdx && _elements[i] == mainEl) sameEl.add(i);
    }

    final scores = List<double>.filled(12, 0);
    // Güneş burcu ağırlıkları (toplam 100)
    scores[mainIdx] += 60.0;
    scores[prevIdx] += 15.0 - 10.0 * p;
    scores[nextIdx] += 5.0  + 10.0 * p;
    scores[sameEl[0]] += 10.0;
    scores[sameEl[1]] += 10.0;

    // Yükselen burç (25 puan ek)
    final rIdx = _nameIdx(risingSign);
    if (rIdx >= 0) scores[rIdx] += 25.0;

    // Ay burcu (15 puan ek)
    final mIdx = _nameIdx(moonSign);
    if (mIdx >= 0) scores[mIdx] += 15.0;

    // Toplam 100'e normalize et
    final total = scores.reduce((a, b) => a + b);

    final el  = <String, double>{'Ateş': 0,'Toprak': 0,'Hava': 0,'Su': 0};
    final mod = <String, double>{'Kardinal': 0,'Sabit': 0,'Değişken': 0};
    final pol = <String, double>{'Maskülen': 0,'Feminen': 0};

    for (int i = 0; i < 12; i++) {
      final s = scores[i] / total;
      el[_elements[i]]    = el[_elements[i]]!    + s;
      mod[_modalities[i]] = mod[_modalities[i]]! + s;
      pol[_polarities[i]] = pol[_polarities[i]]! + s;
    }

    return {
      for (final e in el.entries)  e.key: e.value,
      for (final e in mod.entries) e.key: e.value,
      for (final e in pol.entries) e.key: e.value,
    };
  }
}

// ─── Donut grafik segmenti ────────────────────────────────────────────────────

class _Seg {
  final Color color;
  final double fraction;
  final String label;
  final Offset offset;
  final double radialInset; // pozitif = merkeze yakın, negatif = uzak
  const _Seg(this.color, this.fraction, this.label,
      [this.offset = Offset.zero, this.radialInset = 0]);
}

// ─── Donut CustomPainter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  final double strokeWidth;
  final double progress; // 0.0 → 1.0 arası animasyon değeri
  const _DonutPainter(this.segments, this.strokeWidth, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const gap = 0.07;
    var start = -pi / 2;

    // Toplam açı progress ile ölçeklenir (saat yönünde dolma)
    double remaining = progress; // 0→1 toplam ilerleme

    for (final seg in segments) {
      if (remaining <= 0) break;
      final fullSweep = 2 * pi * seg.fraction;
      final segProgress = (remaining / seg.fraction).clamp(0.0, 1.0);
      final sweep = fullSweep * segProgress;

      if (sweep > gap) {
        // Katman 1: dış glow (daha hafif)
        canvas.drawArc(rect, start + gap / 2, sweep - gap, false, Paint()
          ..color = seg.color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

        // Katman 2: ana çizgi + hafif glow
        canvas.drawArc(rect, start + gap / 2, sweep - gap, false, Paint()
          ..color = seg.color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

        // Katman 3: beyaz özek
        canvas.drawArc(rect, start + gap / 2, sweep - gap, false, Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.28
          ..strokeCap = StrokeCap.butt);
      }

      remaining -= seg.fraction;
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─── Donut grafik widget ──────────────────────────────────────────────────────

class _DonutChart extends StatefulWidget {
  final String title;
  final List<_Seg> segments;
  final double size;
  final double extra;
  final double labelInset;
  final double labelDy;   // label grubunu dikey kaydır (piksel)
  final Duration delay;

  const _DonutChart({
    required this.title,
    required this.segments,
    this.size = 130,
    this.extra = 35,
    this.labelInset = 0,
    this.labelDy = 0,
    this.delay = Duration.zero,
  });

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with TickerProviderStateMixin {
  late AnimationController _arcCtrl;   // donut dolma animasyonu
  late AnimationController _tapCtrl;   // tap → label geçişi
  late Animation<double> _arcAnim;
  late Animation<double> _tapAnim;

  // _tapAnim: 0=donut görünür, 0.5=ikisi de yok, 1=labellar görünür
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut);
    _tapAnim = CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut);

    Future.delayed(widget.delay, () {
      if (mounted) _arcCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = oldWidget.segments.length != widget.segments.length;
    if (!changed) {
      for (int i = 0; i < widget.segments.length; i++) {
        if ((oldWidget.segments[i].fraction - widget.segments[i].fraction).abs() > 0.001) {
          changed = true;
          break;
        }
      }
    }
    if (changed) {
      // 500ms bekle: popup kapanma animasyonu (~300ms) bitmeden animasyon başlamasın
      Future.delayed(const Duration(milliseconds: 500) + widget.delay, () {
        if (mounted) {
          _arcCtrl.reset();
          _arcCtrl.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_tapped) return;
    _tapped = true;
    _tapCtrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _tapCtrl.reverse().then((_) {
        if (mounted) setState(() => _tapped = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sw = size * 0.17;
    final extra = widget.extra;
    final totalSize = size + extra * 2;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: _onTap,
        child: SizedBox(
          width: totalSize,
          height: totalSize,
          child: AnimatedBuilder(
          animation: Listenable.merge([_arcAnim, _tapAnim]),
          builder: (_, __) {
            // donut opacity: tam görünür → tap yarısında sıfır
            final arcOpacity = (1.0 - _tapAnim.value * 2).clamp(0.0, 1.0);
            // label opacity: tap yarısından sonra beliriyor
            final lblOpacity = ((_tapAnim.value - 0.5) * 2).clamp(0.0, 1.0);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Donut yayları — her zaman görünür (tap'te kaybolmaz)
                Positioned(
                  left: extra,
                  top: extra,
                  child: Opacity(
                    opacity: _arcAnim.value,
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _DonutPainter(widget.segments, sw, _arcAnim.value),
                    ),
                  ),
                ),

                // ── Merkez başlık (donutla birlikte kaybolur)
                Positioned(
                  left: extra,
                  top: extra,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: arcOpacity,
                    child: Center(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── İsimler — donut yerine gösterilir
                Positioned(
                  left: extra,
                  top: extra + widget.labelDy,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: lblOpacity,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final seg in widget.segments) ...[
                            Text(
                              seg.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: seg.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: seg.color.withValues(alpha: 0.9),
                                    blurRadius: 12,
                                  ),
                                  const Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

// ─── Bilgi kartı ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null ? const Color(0xFFDD00BB) : const Color(0xFF660044),
            width: 1.5,
          ),
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
                if (onTap != null)
                  const Icon(Icons.edit, color: Color(0xFFDD00BB), size: 9),
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
      ),
    );
  }
}

// ─── Edit popup ───────────────────────────────────────────────────────────────

Future<void> _showEditPopup(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required IconData icon,
  required String fieldType, // 'text' | 'date' | 'roller'
  required String currentValue,
  List<(String, String)>? options, // (key, label) roller için
  Future<void> Function(String value)? onSave,
}) async {
  // Roller için controller tek seferinde yaratılır, rebuild'de yeniden yaratılmaz
  FixedExtentScrollController? rollerCtrl;
  if (fieldType == 'roller' && options != null) {
    final initIdx = options.indexWhere((o) => o.$1 == currentValue);
    rollerCtrl = FixedExtentScrollController(
      initialItem: initIdx == -1 ? 0 : initIdx,
    );
  }

  String selected = currentValue;
  if (fieldType == 'roller' && options != null) {
    final idx = options.indexWhere((o) => o.$1 == selected);
    if (idx == -1) selected = options[0].$1;
  }

  final textCtrl = TextEditingController(
    text: (fieldType == 'text' && currentValue != '—') ? currentValue : '',
  );

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (ctx, setS) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF12082A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDD00BB), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDD00BB).withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Row(
                      children: [
                        Icon(icon, color: const Color(0xFFDD00BB), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // İçerik
                    if (fieldType == 'roller' && options != null)
                      SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            // Silindir tekerlek
                            ListWheelScrollView.useDelegate(
                              itemExtent: 44,
                              perspective: 0.005,
                              diameterRatio: 1.4,
                              physics: const FixedExtentScrollPhysics(),
                              controller: rollerCtrl,
                              onSelectedItemChanged: (i) => setS(() => selected = options[i].$1),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: options.length,
                                builder: (_, i) => Center(
                                  child: Text(
                                    options[i].$2,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Üst solma — silindir derinliği
                            IgnorePointer(child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF12082A),
                                    const Color(0xFF12082A).withValues(alpha: 0),
                                  ],
                                  stops: const [0, 0.38],
                                ),
                              ),
                            )),
                            // Alt solma
                            IgnorePointer(child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    const Color(0xFF12082A),
                                    const Color(0xFF12082A).withValues(alpha: 0),
                                  ],
                                  stops: const [0, 0.38],
                                ),
                              ),
                            )),
                            // Seçim bandı — ortadan kenara solarak
                            IgnorePointer(child: Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(height: 1, decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Color(0xCCDD00BB), Colors.transparent],
                                  ),
                                )),
                                Container(height: 44, decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.white.withValues(alpha: 0.07), Colors.transparent],
                                  ),
                                )),
                                Container(height: 1, decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Color(0xCCDD00BB), Colors.transparent],
                                  ),
                                )),
                              ],
                            ))),
                          ],
                        ),
                      )
                    else if (fieldType == 'time')
                      _TimeRollerPicker(
                        initial: currentValue,
                        onChanged: (v) => setS(() => selected = v),
                      )
                    else if (fieldType == 'date')
                      _DatePickerInline(
                        initial: currentValue,
                        onChanged: (v) => setS(() => selected = v),
                      )
                    else
                      TextField(
                        controller: textCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: title,
                          hintStyle: const TextStyle(color: Colors.white38),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFDD00BB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF44CC), width: 2),
                          ),
                        ),
                        onChanged: (v) => selected = v,
                      ),

                    const SizedBox(height: 24),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () { rollerCtrl?.dispose(); Navigator.pop(ctx); },
                            child: const Text('İptal', style: TextStyle(color: Colors.white38)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDD00BB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              String val;
                              if (fieldType == 'text') {
                                val = textCtrl.text;
                              } else if (fieldType == 'roller' && rollerCtrl != null && options != null) {
                                // Controller'dan direkt oku — rebuild'den etkilenmez
                                val = options[rollerCtrl.selectedItem.clamp(0, options.length - 1)].$1;
                              } else {
                                val = selected;
                              }
                              Navigator.pop(ctx);
                              rollerCtrl?.dispose();
                              if (onSave != null) await onSave(val);
                            },
                            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

// ─── Sprite avatar (profilepic.jpg 2×2 grid) ─────────────────────────────────

class _SpriteAvatar extends StatelessWidget {
  final int index; // 0=sol üst, 1=sağ üst, 2=sol alt, 3=sağ alt
  final double size;
  const _SpriteAvatar({required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    final col = index % 2;  // 0=sol, 1=sağ
    final row = index ~/ 2; // 0=üst, 1=alt
    // 4. avatar için ayrı zoom; diğerleri %5, 4. avatar %10
    final zoom = index == 3 ? 1.20 : 1.05;
    final imgSize = size * 2 * zoom;
    final baseLeft = -size * (zoom - 1) / 2 - col * size * zoom;
    final baseTop  = -size * (zoom - 1) / 2 - row * size * zoom;
    // 4. avatar: 5 px sola kaydır (sağından kırp)
    final leftAdjust = 0.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: baseLeft + leftAdjust,
            top: baseTop,
            child: Image.asset(
              'assets/images/profilepic.JPG',
              width: imgSize,
              height: imgSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: imgSize, height: imgSize,
                color: const Color(0xFF2A1A4C),
                child: const Icon(Icons.person_rounded, color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profil düzenleme bottom sheet ───────────────────────────────────────────

class _ProfileEditSheet extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(String name, int? picIndex, String? photoPath) onSave;
  const _ProfileEditSheet({required this.profile, required this.onSave});

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late TextEditingController _nameCtrl;
  int? _selectedIndex;
  String? _customPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _customPath = widget.profile.customPhotoPath;
    // Daha önce seçilmemişse cinsiyete göre default avatar
    if (widget.profile.profilePicIndex != null) {
      _selectedIndex = widget.profile.profilePicIndex;
    } else if (_customPath == null || _customPath!.isEmpty) {
      final g = widget.profile.gender;
      _selectedIndex = g == 'kadin' ? 0 : g == 'erkek' ? 1 : 3;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (photo != null && mounted) {
      setState(() {
        _customPath = photo.path;
        _selectedIndex = null;
      });
    }
  }

  Widget _avatarPreview(double size) {
    Widget content;
    if (_customPath?.isNotEmpty == true) {
      content = Image.file(File(_customPath!), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon());
    } else if (_selectedIndex != null) {
      content = _SpriteAvatar(index: _selectedIndex!, size: size);
    } else {
      content = Image.asset('assets/images/magnusicon.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon());
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00CCFF), width: 2.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00CCFF).withValues(alpha: 0.5),
              blurRadius: 16, spreadRadius: 2),
        ],
        color: const Color(0xFF0A0520),
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _defaultIcon() => const Center(
      child: Icon(Icons.person_rounded, color: Colors.white54, size: 36));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A3C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFFDD00BB), width: 1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Profili Düzenle',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Önizleme
              _avatarPreview(88),
              const SizedBox(height: 20),

              // 4 hazır avatar
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Avatar Seç',
                    style: TextStyle(color: Color(0xFFDD88CC), fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) {
                  final sel = _selectedIndex == i && _customPath == null;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIndex = i;
                      _customPath = null;
                    }),
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? const Color(0xFFDD00BB) : Colors.white24,
                          width: sel ? 2.5 : 1.5,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(
                            color: const Color(0xFFDD00BB).withValues(alpha: 0.5),
                            blurRadius: 10)]
                            : null,
                      ),
                      child: ClipOval(child: _SpriteAvatar(index: i, size: 64)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Kamera / Galeri
              Row(
                children: [
                  Expanded(child: _srcButton(
                      Icons.camera_alt_rounded, 'Kamera',
                      () => _pickImage(ImageSource.camera))),
                  const SizedBox(width: 10),
                  Expanded(child: _srcButton(
                      Icons.photo_library_rounded, 'Galeri',
                      () => _pickImage(ImageSource.gallery))),
                ],
              ),
              const SizedBox(height: 16),

              // İsim
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('İsim',
                    style: TextStyle(color: Color(0xFFDD88CC), fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Adınız',
                  hintStyle: const TextStyle(color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDD00BB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFFF44CC), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kaydet
              GestureDetector(
                onTap: _saving
                    ? null
                    : () async {
                  setState(() => _saving = true);
                  await widget.onSave(
                      _nameCtrl.text.trim(), _selectedIndex, _customPath);
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFCC00AA), Color(0xFF8800CC)]),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFCC00AA).withValues(alpha: 0.4),
                        blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text('Kaydet',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _srcButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFDD88CC), size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Silindir tekerlek widget'ı ──────────────────────────────────────────────

class _CylinderRoller extends StatefulWidget {
  final List<String> items;
  final int initialItem;
  final ValueChanged<int> onChanged;
  final double width;
  final double height;
  final double itemExtent;

  const _CylinderRoller({
    required this.items,
    required this.initialItem,
    required this.onChanged,
    this.width = 80,
    this.height = 160,
    this.itemExtent = 40,
  });

  @override
  State<_CylinderRoller> createState() => _CylinderRollerState();
}

class _CylinderRollerState extends State<_CylinderRoller> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
        initialItem: widget.initialItem.clamp(0, widget.items.length - 1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Silindir tekerlek — perspektif 3D görünüm
          ListWheelScrollView(
            controller: _ctrl,
            itemExtent: widget.itemExtent,
            diameterRatio: 1.3,
            perspective: 0.004,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: widget.onChanged,
            children: widget.items
                .map((item) => Center(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Üst solma
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A0A3C),
                    const Color(0xFF1A0A3C).withValues(alpha: 0),
                  ],
                  stops: const [0, 0.38],
                ),
              ),
            ),
          ),
          // Alt solma
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF1A0A3C),
                    const Color(0xFF1A0A3C).withValues(alpha: 0),
                  ],
                  stops: const [0, 0.38],
                ),
              ),
            ),
          ),
          // Seçim bandı — ortadan kenara solarak
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 1, decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xCCDD00BB), Colors.transparent],
                    ),
                  )),
                  Container(height: widget.itemExtent, decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.07), Colors.transparent],
                    ),
                  )),
                  Container(height: 1, decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xCCDD00BB), Colors.transparent],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarih seçici (inline) ────────────────────────────────────────────────────

class _DatePickerInline extends StatefulWidget {
  final String initial; // 'YYYY-MM-DD' veya boş
  final ValueChanged<String> onChanged;
  const _DatePickerInline({required this.initial, required this.onChanged});

  @override
  State<_DatePickerInline> createState() => _DatePickerInlineState();
}

class _DatePickerInlineState extends State<_DatePickerInline> {
  late int _year, _month, _day;

  @override
  void initState() {
    super.initState();
    final p = widget.initial.split('-');
    _year  = p.length == 3 ? (int.tryParse(p[0]) ?? 1990) : 1990;
    _month = p.length == 3 ? (int.tryParse(p[1]) ?? 1) : 1;
    _day   = p.length == 3 ? (int.tryParse(p[2]) ?? 1) : 1;
  }

  void _notify() {
    widget.onChanged('$_year-${_month.toString().padLeft(2,'0')}-${_day.toString().padLeft(2,'0')}');
  }

  Widget _roller(List<String> items, int selected, ValueChanged<int> onChanged) {
    return _CylinderRoller(
      items: items,
      initialItem: selected,
      onChanged: onChanged,
      width: 72,
      height: 140,
      itemExtent: 38,
    );
  }

  @override
  Widget build(BuildContext context) {
    final years  = List.generate(100, (i) => (DateTime.now().year - i).toString());
    final months = List.generate(12, (i) => (i+1).toString().padLeft(2,'0'));
    final days   = List.generate(31, (i) => (i+1).toString().padLeft(2,'0'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roller(days,   _day - 1,   (i) { setState(() => _day   = i+1); _notify(); }),
        const SizedBox(width: 8),
        _roller(months, _month - 1, (i) { setState(() => _month = i+1); _notify(); }),
        const SizedBox(width: 8),
        _roller(years,  years.indexWhere((y) => y == _year.toString()).clamp(0, 99),
            (i) { setState(() => _year = int.parse(years[i])); _notify(); }),
      ],
    );
  }
}

// ─── Saat seçici (inline, iki tekerlek + ":") ─────────────────────────────────

class _TimeRollerPicker extends StatefulWidget {
  final String initial; // "HH:MM" veya boş
  final ValueChanged<String> onChanged;
  const _TimeRollerPicker({required this.initial, required this.onChanged});

  @override
  State<_TimeRollerPicker> createState() => _TimeRollerPickerState();
}

class _TimeRollerPickerState extends State<_TimeRollerPicker> {
  late int _hour, _minute;

  @override
  void initState() {
    super.initState();
    final p = widget.initial.split(':');
    _hour   = p.length == 2 ? (int.tryParse(p[0]) ?? 12) : 12;
    _minute = p.length == 2 ? (int.tryParse(p[1]) ?? 0)  : 0;
  }

  void _notify() {
    widget.onChanged(
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours   = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    final minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Format ipucu
        const Text(
          'SS  :  DD   (örn. 13 : 30)',
          style: TextStyle(color: Color(0xFFDD88CC), fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CylinderRoller(
              items: hours,
              initialItem: _hour,
              onChanged: (i) { setState(() => _hour = i); _notify(); },
              width: 72,
              height: 140,
              itemExtent: 38,
            ),
            // ":" ayracı
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _CylinderRoller(
              items: minutes,
              initialItem: _minute,
              onChanged: (i) { setState(() => _minute = i); _notify(); },
              width: 72,
              height: 140,
              itemExtent: 38,
            ),
          ],
        ),
      ],
    );
  }
}

String _burcAdi(int idx) {
  const names = ['Koç','Boğa','İkizler','Yengeç','Aslan','Başak',
                  'Terazi','Akrep','Yay','Oğlak','Kova','Balık'];
  return names[idx % 12];
}

// ─── Ay Burcu + Yükselen hesabı ──────────────────────────────────────────────
// Kaynaklar: Jean Meeus "Astronomical Algorithms" yaklaşımı
// Hedef: %80-90 doğruluk (gerçek ephemeris olmadan lokal hesap)

class _AstroCalc {
  // J2000.0 referans noktası: 1 Ocak 2000, 12:00 UTC
  static final _j2000 = DateTime.utc(2000, 1, 1, 12);

  // Ekliptik eğimi (obliquity of ecliptic) — derece
  static const _epsilon = 23.4393;

  // Türkiye varsayılan enlem (Ankara civarı) — derece
  static const _latitude = 39.0;

  // Türkiye varsayılan boylam (Ankara civarı) — derece doğu
  static const _longitude = 33.0;

  /// Türkiye saat dilimi: 2016'dan önce yaz/kış değişikliği vardı.
  /// 1978-2016: Nisan-Ekim UTC+3 (yaz), Kasım-Mart UTC+2 (kış)
  /// 2016 ve sonrası: yıl boyu UTC+3
  static double _turkeyTimezone(int year, int month) {
    if (year >= 2016) return 3.0;
    if (month >= 4 && month <= 10) return 3.0;
    return 2.0;
  }

  /// Ay burcu: ortalama boylam + anomali düzeltmesi (Meeus Ch.47 basitleştirilmiş)
  static String? moonSign(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return null;
    final parts = birthDate.split('-');
    if (parts.length != 3) return null;

    final date = DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    // Ay burcu sadece tarihe bağlı (saate göre < 1 gün kayması kabul edilir)
    final d = date.difference(_j2000).inMicroseconds /
              Duration.microsecondsPerDay.toDouble();

    // Ortalama ay boylamı (derece)
    final L = (218.316 + 13.176396 * d) % 360;

    // Ay anomalisi (derece) — eliptik yörünge sapması
    final M = ((134.963 + 13.064993 * d) % 360 + 360) % 360;

    // Düzeltilmiş ay boylamı: anomali etkisi eklendi
    final moonLon = ((L + 6.289 * sin(M * pi / 180)) % 360 + 360) % 360;

    return _burcAdi((moonLon / 30).floor());
  }

  /// Yükselen burç: GST → LST → Ascendant formülü (atan2 ile ufuk kesişimi)
  static String? risingSign(String? birthDate, String? birthTime) {
    if (birthDate == null || birthDate.isEmpty) return null;
    final parts = birthDate.split('-');
    if (parts.length != 3) return null;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    // Doğum saatini UTC'ye çevir — Türkiye yaz/kış saati geçmişi dahil
    double localHour = 12.0;
    if (birthTime != null && birthTime.isNotEmpty) {
      final tp = birthTime.split(':');
      if (tp.length >= 2) {
        localHour = (double.tryParse(tp[0]) ?? 12) +
                    (double.tryParse(tp[1]) ?? 0) / 60;
      }
    }
    final utcHour = localHour - _turkeyTimezone(year, month);

    // J2000'den beri geçen gün (saat dahil)
    // NOT: .inDays sıfıra doğru keser (floor değil) — J2000 öğlen bazlı olduğu için
    // mikrosaniye hassasiyetiyle hesapla
    final date = DateTime.utc(year, month, day);
    final d = date.difference(_j2000).inMicroseconds /
              Duration.microsecondsPerDay.toDouble() +
              utcHour / 24.0;

    // Greenwich Yıldız Zamanı (Greenwich Sidereal Time) — derece
    double gst = (280.46061837 + 360.98564736629 * d) % 360;
    gst = (gst + 360) % 360;

    // Lokal Yıldız Zamanı (Local Sidereal Time) — derece
    final lst = (gst + _longitude) % 360;
    final lstRad = lst * pi / 180;
    final epsilonRad = _epsilon * pi / 180;
    final latRad = _latitude * pi / 180;

    // Ascendant: doğu ufkunun ekliptikle kesişim noktası
    // atan2(cos(LST), -sin(LST)*cos(ε) - tan(φ)*sin(ε))
    final y = cos(lstRad);
    final x = -sin(lstRad) * cos(epsilonRad) - tan(latRad) * sin(epsilonRad);
    double ascDeg = atan2(y, x) * 180 / pi;

    // Normalize (atan2 zaten doğu ufkunu verir, +180 YANLIŞ)
    ascDeg = (ascDeg + 360) % 360;

    return _burcAdi((ascDeg / 30).floor());
  }
}

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final scores = _ZodiacCalc.compute(
      profile.birthDate,
      risingSign: profile.risingSign,
      moonSign: profile.moonSign,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // ── Arka plan görseli
          Positioned.fill(
            child: Image.asset(
              'assets/images/signinbackground.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
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
                        _buildGridSection(context, ref, profile),
                        const SizedBox(height: 4),
                        _buildDonutRow(scores),
                        const SizedBox(height: 12),
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

  // ── Admin kontrolü ───────────────────────────────────────────────────────

  // Türkçe i/ı farkını görmezden gelen normalize: hepsini 'i'ye indirir.
  // 'Anıl', 'Anil', 'ANIL', 'ANıL' → 'anil'
  static String _trNorm(String s) => s
      .replaceAll('ı', 'i')
      .replaceAll('I', 'i')
      .replaceAll('İ', 'i')
      .toLowerCase();

  bool _isAdmin(UserProfile p) =>
      _trNorm(p.name) == 'anil' &&
      p.maritalStatus == 'evli' &&
      p.birthDate == '1983-10-14' &&
      p.job == 'kamusektoru' &&
      p.zodiacSign == 'Terazi' &&
      p.birthTime == '13:30' &&
      p.birthCity == 'Ankara';

  // ── Üst bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (_isAdmin(profile))
            IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: Color(0xFFFFCC00), size: 26),
              onPressed: () => _showAdminPanel(context),
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

  Widget _buildGridSection(BuildContext context, WidgetRef ref, UserProfile profile) {
    final birth = _formatDate(profile.birthDate);
    final planet = profile.planet?.isNotEmpty == true
        ? profile.planet!
        : _ZodiacInfo.planet(profile.zodiacSign);

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
                        onTap: () => _showEditPopup(context, ref,
                          title: 'Doğum Tarihi',
                          icon: Icons.calendar_month_rounded,
                          fieldType: 'date',
                          currentValue: profile.birthDate ?? '',
                          onSave: (v) async {
                            final p = ref.read(userProfileProvider);
                            final parts = v.split('-');
                            String? burc;
                            if (parts.length == 3) {
                              final m = int.tryParse(parts[1]) ?? 0;
                              final d = int.tryParse(parts[2]) ?? 0;
                              burc = _burcAdi(_ZodiacCalc.signIndex(m, d));
                            }
                            // Ay + Yükselen otomatik hesapla (kullanıcı override etmemişse)
                            final moon    = _AstroCalc.moonSign(v);
                            final rising  = _AstroCalc.risingSign(v, p.birthTime);
                            await ref.read(userProfileProvider.notifier).save(
                              UserProfile(name: p.name, age: p.age, gender: p.gender,
                                job: p.job, maritalStatus: p.maritalStatus,
                                birthDate: v, birthCity: p.birthCity,
                                zodiacSign: burc ?? p.zodiacSign,
                                onboardingComplete: p.onboardingComplete,
                                birthTime: p.birthTime,
                                risingSign: rising ?? p.risingSign,
                                moonSign: moon ?? p.moonSign,
                                planet: p.planet, profilePicIndex: p.profilePicIndex,
                                customPhotoPath: p.customPhotoPath));
                          }),
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
                        onTap: () => _showEditPopup(context, ref,
                          title: 'Medeni Hal',
                          icon: Icons.favorite_rounded,
                          fieldType: 'roller',
                          currentValue: profile.maritalStatus,
                          options: kMaritalOptions.map((o) => (o.key, o.label)).toList(),
                          onSave: (v) async {
                            final p = ref.read(userProfileProvider);
                            await ref.read(userProfileProvider.notifier).save(
                              UserProfile(name: p.name, age: p.age, gender: p.gender,
                                job: p.job, maritalStatus: v,
                                birthDate: p.birthDate, birthCity: p.birthCity,
                                zodiacSign: p.zodiacSign,
                                onboardingComplete: p.onboardingComplete,
                                birthTime: p.birthTime, risingSign: p.risingSign,
                                moonSign: p.moonSign, planet: p.planet,
                                profilePicIndex: p.profilePicIndex,
                                customPhotoPath: p.customPhotoPath));
                          }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Orta: avatar + isim
              SizedBox(
                width: 110,
                child: _buildAvatarCenter(context, ref, profile),
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
                        value: profile.genderLabel.isNotEmpty ? profile.genderLabel : '—',
                        onTap: () => _showEditPopup(context, ref,
                          title: 'Cinsiyet',
                          icon: Icons.person_rounded,
                          fieldType: 'roller',
                          currentValue: profile.gender,
                          options: kGenderOptions.map((o) => (o.$1, o.$2)).toList(),
                          onSave: (v) async {
                            final p = ref.read(userProfileProvider);
                            await ref.read(userProfileProvider.notifier).save(
                              UserProfile(name: p.name, age: p.age, gender: v,
                                job: p.job, maritalStatus: p.maritalStatus,
                                birthDate: p.birthDate, birthCity: p.birthCity,
                                zodiacSign: p.zodiacSign,
                                onboardingComplete: p.onboardingComplete,
                                birthTime: p.birthTime, risingSign: p.risingSign,
                                moonSign: p.moonSign, planet: p.planet,
                                profilePicIndex: p.profilePicIndex,
                                customPhotoPath: p.customPhotoPath));
                          }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.work_rounded,
                        label: 'Meslek',
                        value: profile.jobLabel.isNotEmpty ? profile.jobLabel : '—',
                        onTap: () => _showEditPopup(context, ref,
                          title: 'Meslek',
                          icon: Icons.work_rounded,
                          fieldType: 'roller',
                          currentValue: profile.job,
                          options: kJobOptions.map((o) => (o.key, o.label)).toList(),
                          onSave: (v) async {
                            final p = ref.read(userProfileProvider);
                            await ref.read(userProfileProvider.notifier).save(
                              UserProfile(name: p.name, age: p.age, gender: p.gender,
                                job: v, maritalStatus: p.maritalStatus,
                                birthDate: p.birthDate, birthCity: p.birthCity,
                                zodiacSign: p.zodiacSign,
                                onboardingComplete: p.onboardingComplete,
                                birthTime: p.birthTime, risingSign: p.risingSign,
                                moonSign: p.moonSign, planet: p.planet,
                                profilePicIndex: p.profilePicIndex,
                                customPhotoPath: p.customPhotoPath));
                          }),
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
                value: profile.birthTime?.isNotEmpty == true ? profile.birthTime! : '—',
                onTap: () => _showEditPopup(context, ref,
                  title: 'Doğum Saati',
                  icon: Icons.access_time_rounded,
                  fieldType: 'time',
                  currentValue: profile.birthTime ?? '',
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    // Saat değişince Yükselen yeniden hesapla
                    final rising = _AstroCalc.risingSign(p.birthDate, v);
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: p.birthCity,
                        zodiacSign: p.zodiacSign, onboardingComplete: p.onboardingComplete,
                        birthTime: v,
                        risingSign: rising ?? p.risingSign,
                        moonSign: p.moonSign,
                        planet: p.planet, profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.location_on_rounded,
                label: 'Doğum Yeri',
                value: profile.birthCity?.isNotEmpty == true ? profile.birthCity! : '—',
                onTap: () => _showEditPopup(context, ref,
                  title: 'Doğum Yeri',
                  icon: Icons.location_on_rounded,
                  fieldType: 'text',
                  currentValue: profile.birthCity ?? '',
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: v,
                        zodiacSign: p.zodiacSign,
                        onboardingComplete: p.onboardingComplete,
                        birthTime: p.birthTime, risingSign: p.risingSign,
                        moonSign: p.moonSign, planet: p.planet,
                        profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Burç',
                value: profile.zodiacSign?.isNotEmpty == true ? profile.zodiacSign! : '—',
                onTap: () => _showEditPopup(context, ref,
                  title: 'Burç',
                  icon: Icons.auto_awesome_rounded,
                  fieldType: 'roller',
                  currentValue: profile.zodiacSign ?? '',
                  options: const [
                    ('Koç','Koç ♈'), ('Boğa','Boğa ♉'), ('İkizler','İkizler ♊'),
                    ('Yengeç','Yengeç ♋'), ('Aslan','Aslan ♌'), ('Başak','Başak ♍'),
                    ('Terazi','Terazi ♎'), ('Akrep','Akrep ♏'), ('Yay','Yay ♐'),
                    ('Oğlak','Oğlak ♑'), ('Kova','Kova ♒'), ('Balık','Balık ♓'),
                  ],
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: p.birthCity,
                        zodiacSign: v,
                        onboardingComplete: p.onboardingComplete,
                        birthTime: p.birthTime, risingSign: p.risingSign,
                        moonSign: p.moonSign, planet: p.planet,
                        profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
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
                onTap: () => _showEditPopup(context, ref,
                  title: 'Gezegen',
                  icon: Icons.public_rounded,
                  fieldType: 'roller',
                  currentValue: planet,
                  options: const [
                    ('Güneş',  'Güneş ☀️'),
                    ('Ay',     'Ay 🌙'),
                    ('Merkür', 'Merkür ☿'),
                    ('Venüs',  'Venüs ♀'),
                    ('Mars',   'Mars ♂'),
                    ('Jüpiter','Jüpiter ♃'),
                    ('Satürn', 'Satürn ♄'),
                    ('Uranüs', 'Uranüs ⛢'),
                    ('Neptün', 'Neptün ♆'),
                    ('Plüton', 'Plüton ♇'),
                  ],
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: p.birthCity,
                        zodiacSign: p.zodiacSign,
                        onboardingComplete: p.onboardingComplete,
                        birthTime: p.birthTime,
                        risingSign: p.risingSign,
                        moonSign: p.moonSign,
                        planet: v,
                        profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.trending_up_rounded,
                label: 'Yükselen',
                value: profile.risingSign?.isNotEmpty == true ? profile.risingSign! : '—',
                onTap: () => _showEditPopup(context, ref,
                  title: 'Yükselen Burç',
                  icon: Icons.trending_up_rounded,
                  fieldType: 'roller',
                  currentValue: profile.risingSign ?? '',
                  options: const [
                    ('__auto__','✦ Otomatik Hesapla'),
                    ('Koç','Koç ♈'), ('Boğa','Boğa ♉'), ('İkizler','İkizler ♊'),
                    ('Yengeç','Yengeç ♋'), ('Aslan','Aslan ♌'), ('Başak','Başak ♍'),
                    ('Terazi','Terazi ♎'), ('Akrep','Akrep ♏'), ('Yay','Yay ♐'),
                    ('Oğlak','Oğlak ♑'), ('Kova','Kova ♒'), ('Balık','Balık ♓'),
                  ],
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    final rising = v == '__auto__'
                        ? (_AstroCalc.risingSign(p.birthDate, p.birthTime) ?? p.risingSign)
                        : v;
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: p.birthCity,
                        zodiacSign: p.zodiacSign, onboardingComplete: p.onboardingComplete,
                        birthTime: p.birthTime, risingSign: rising, moonSign: p.moonSign,
                        planet: p.planet, profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.nightlight_rounded,
                label: 'Ay Burcu',
                value: profile.moonSign?.isNotEmpty == true ? profile.moonSign! : '—',
                onTap: () => _showEditPopup(context, ref,
                  title: 'Ay Burcu',
                  icon: Icons.nightlight_rounded,
                  fieldType: 'roller',
                  currentValue: profile.moonSign ?? '',
                  options: const [
                    ('__auto__','✦ Otomatik Hesapla'),
                    ('Koç','Koç ♈'), ('Boğa','Boğa ♉'), ('İkizler','İkizler ♊'),
                    ('Yengeç','Yengeç ♋'), ('Aslan','Aslan ♌'), ('Başak','Başak ♍'),
                    ('Terazi','Terazi ♎'), ('Akrep','Akrep ♏'), ('Yay','Yay ♐'),
                    ('Oğlak','Oğlak ♑'), ('Kova','Kova ♒'), ('Balık','Balık ♓'),
                  ],
                  onSave: (v) async {
                    final p = ref.read(userProfileProvider);
                    final moon = v == '__auto__'
                        ? (_AstroCalc.moonSign(p.birthDate) ?? p.moonSign)
                        : v;
                    await ref.read(userProfileProvider.notifier).save(
                      UserProfile(name: p.name, age: p.age, gender: p.gender,
                        job: p.job, maritalStatus: p.maritalStatus,
                        birthDate: p.birthDate, birthCity: p.birthCity,
                        zodiacSign: p.zodiacSign, onboardingComplete: p.onboardingComplete,
                        birthTime: p.birthTime, risingSign: p.risingSign, moonSign: moon,
                        planet: p.planet, profilePicIndex: p.profilePicIndex,
                        customPhotoPath: p.customPhotoPath));
                  }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Cinsiyete göre varsayılan avatar index: kadın=0, erkek=1, belirtilmiyor=3
  int _defaultAvatarIndex(String gender) {
    if (gender == 'kadin') return 0;
    if (gender == 'erkek') return 1;
    return 3;
  }

  Widget _buildAvatarCenter(BuildContext context, WidgetRef ref, UserProfile profile) {
    final initials = profile.name.isNotEmpty
        ? profile.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : 'M';

    // Avatar içeriği: özel fotoğraf > preset sprite > varsayılan ikon
    Widget avatarContent;
    if (profile.customPhotoPath?.isNotEmpty == true) {
      avatarContent = Image.file(File(profile.customPhotoPath!), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/magnusicon.png', fit: BoxFit.cover));
    } else {
      // Seçili preset varsa onu göster, yoksa cinsiyete göre default belirle
      final idx = profile.profilePicIndex ?? _defaultAvatarIndex(profile.gender);
      avatarContent = _SpriteAvatar(index: idx, size: 76);
    }

    return GestureDetector(
      onTap: () => _showProfileEdit(context, ref, profile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
                child: ClipOval(child: avatarContent),
              ),
              // Düzenle rozeti
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDD00BB),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A0A3C), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFDD00BB).withValues(alpha: 0.5),
                          blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 11),
                ),
              ),
            ],
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
      ),
    );
  }

  // ── Donut grafikler ───────────────────────────────────────────────────────

  Widget _buildDonutRow(Map<String, double> s) {
    // Modalite: size=120, extra=50 → totalHeight=220. Yukarı kaydır: yarıçap=60
    // Polarite/Element: size=120, extra=20 → totalHeight=160. Yukarı kaydır: çap=120
    const modTotal = 120.0 + 35 * 2; // 190
    const rowTotal = 120.0 + 35 * 2; // 190
    const modShift = 60.0;           // yarıçap
    const rowShift = 120.0;          // çap

    final modalite = _DonutChart(
      title: 'Modalite',
      size: 120,
      labelInset: 1,
      delay: Duration.zero,
      segments: [
        _Seg(const Color(0xFFFFDD00), s['Kardinal']!, 'Kardinal'),
        _Seg(const Color(0xFF00EE88), s['Değişken']!, 'Değişken'),
        _Seg(const Color(0xFF00CCFF), s['Sabit']!,    'Sabit'),
      ],
    );

    final polRow = Row(
      children: [
        Expanded(
          child: Center(
            child: _DonutChart(
              title: 'Polarite',
              size: 120,
              labelInset: 1,
              delay: const Duration(milliseconds: 950),
              segments: [
                _Seg(const Color(0xFFAA44FF), s['Feminen']!,  'Feminen'),
                _Seg(const Color(0xFF00CCAA), s['Maskülen']!, 'Maskülen'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: _DonutChart(
              title: 'Element',
              size: 120,
              labelInset: 1,
              labelDy: 1,
              delay: const Duration(milliseconds: 1900),
              segments: [
                _Seg(const Color(0xFFFF6622), s['Ateş']!,   'Ateş'),
                _Seg(const Color(0xFF88DD00), s['Toprak']!, 'Toprak'),
                _Seg(const Color(0xFF00AAFF), s['Hava']!,   'Hava'),
                _Seg(const Color(0xFF0066FF), s['Su']!,     'Su'),
              ],
            ),
          ),
        ),
      ],
    );

    // Her donut totalSize=190, merkezi içeride: extra(35) + yarıçap(60) = 95px
    // Merkez-merkez arası dikey mesafe: gap
    const donutTotal = 190.0;
    const centerOffset = 95.0; // donutun üstünden merkezine
    const gap = 150.0;         // Modalite merkezi ile alt donutlar merkezi arası

    // Toplam yükseklik: Modalite merkezi + gap + alt donut alt kenarı
    const totalH = centerOffset + gap + (donutTotal - centerOffset);

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Modalite — yatayda ortala, üstte
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: modalite),
          ),
          // Polarite + Element — Modalite merkezinden gap kadar aşağıda
          Positioned(
            top: gap,
            left: 0,
            right: 0,
            child: polRow,
          ),
        ],
      ),
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

  // ── Profil düzenleme ──────────────────────────────────────────────────────

  void _showProfileEdit(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileEditSheet(
        profile: profile,
        onSave: (name, picIndex, photoPath) async {
          final p = ref.read(userProfileProvider);
          await ref.read(userProfileProvider.notifier).save(UserProfile(
            name: name.isEmpty ? p.name : name,
            age: p.age,
            gender: p.gender,
            job: p.job,
            maritalStatus: p.maritalStatus,
            birthDate: p.birthDate,
            birthCity: p.birthCity,
            zodiacSign: p.zodiacSign,
            onboardingComplete: p.onboardingComplete,
            birthTime: p.birthTime,
            risingSign: p.risingSign,
            moonSign: p.moonSign,
            planet: p.planet,
            profilePicIndex: picIndex,
            customPhotoPath: photoPath,
          ));
        },
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

  void _showAdminPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFFFCC00), width: 1.5),
      ),
      builder: (ctx) {
        bool resetDone = false;
        return StatefulBuilder(
        builder: (ctx, setPanelState) {
          Future<void> doReset() async {
            final prefs = await SharedPreferences.getInstance();
            // ⚠️ YENİ GÜNLÜK FAL EKLENİNCE BURAYA DA EKLE
            // Format: '<tur>_bugun_tarih'
            await prefs.remove('motivasyon_bugun_tarih');
            await prefs.remove('olumlama_bugun_tarih');   // limitsiz ama temizlik için
            await prefs.remove('ozlusoz_bugun_tarih');
            await prefs.remove('ozlusoz_session_tarih');
            await prefs.remove('ozlusoz_session_ids');
            await prefs.remove('ozlusoz_session_bgs');
            await prefs.remove('ozlusoz_gosterilen_idler');
            await prefs.remove('tarot_bugun_tarih');
            await prefs.remove('kahve_bugun_tarih');
            await prefs.remove('astroloji_bugun_tarih');
            await prefs.remove('kaderkitabi_bugun_tarih');
            await prefs.remove('dertortagi_bugun_tarih');
            await prefs.remove('acigercekler_bugun_tarih');
            // Numeroloji: tüm cache sıfırla (genel + yıl + bugün)
            await prefs.remove('num_bugun_tarih');
            await prefs.remove('num_bugun_metin');
            await prefs.remove('num_bugun_unlock');
            await prefs.remove('num_genel_done');
            await prefs.remove('num_genel_metin');
            await prefs.remove('num_genel_unlock');
            final numYil = DateTime.now().year.toString();
            await prefs.remove('num_yil_done');
            await prefs.remove('num_yil_metin_$numYil');
            await prefs.remove('num_yil_unlock_$numYil');
            setPanelState(() => resetDone = true);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tutma çubuğu
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Başlık
                const Row(
                  children: [
                    Icon(Icons.settings_rounded, color: Color(0xFFFFCC00), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Color(0xFFFFCC00),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Günlük Hakları Sıfırla butonu
                GestureDetector(
                  onTap: resetDone ? null : doReset,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: resetDone
                          ? const Color(0xFF003322)
                          : const Color(0xFF00CCFF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: resetDone
                            ? const Color(0xFF00FF88).withValues(alpha: 0.6)
                            : const Color(0xFF00CCFF).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          resetDone
                              ? Icons.check_circle_outline_rounded
                              : Icons.hourglass_empty_rounded,
                          color: resetDone
                              ? const Color(0xFF00FF88)
                              : const Color(0xFF00CCFF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resetDone
                                  ? 'Günlük haklar sıfırlandı ✓'
                                  : 'Günlük Hakları Sıfırla',
                              style: TextStyle(
                                color: resetDone
                                    ? const Color(0xFF00FF88)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!resetDone)
                              const Text(
                                'Motivasyon, olumlama, özlü söz, tarot, kahve, astroloji',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
        );
      },
    );
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
