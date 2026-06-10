// Kaynak: assets/data/dertortagi.json
// Akış: Kategori → Dert seçimi → Kum saati (5sn) → Derman (tavsiye)
// Günlük limit  : günde 1 kez  (dertortagi_bugun_tarih)
// Günlük seçim  : aynı gün aynı kategoride hep aynı 6 dert (dertortagi_gunluk_<k>_<tarih>)
// Tekrar gösterilmeme: kategori bazlı, farklı günlerde yeni sorular (dertortagi_gosterilen_<k>)
// Koşul filtrelemesi: cinsiyet, medeni_durum, meslek

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum _DertAdim { kategori, dert, yukleniyor, derman }

class DertOrtagiScreen extends ConsumerStatefulWidget {
  const DertOrtagiScreen({super.key});

  @override
  ConsumerState<DertOrtagiScreen> createState() => _DertOrtagiScreenState();
}

class _DertOrtagiScreenState extends ConsumerState<DertOrtagiScreen>
    with TickerProviderStateMixin {

  // ── Pref anahtarları ────────────────────────────────────────────────────────
  static const _prefBugun      = 'dertortagi_bugun_tarih';
  static const _prefGosterilen = 'dertortagi_gosterilen_'; // + kategori
  static const _prefGunluk     = 'dertortagi_gunluk_';    // + kategori_tarih

  // ── Durum ───────────────────────────────────────────────────────────────────
  _DertAdim _adim               = _DertAdim.kategori;
  String    _seciliKategori     = '';
  Map<String, dynamic>? _seciliDert;
  bool _limitDoldu  = false;
  bool _ilkYukleme  = true;

  Map<String, List<Map<String, dynamic>>> _tumDertler   = {};
  List<Map<String, dynamic>>              _gosterilenDertler = [];

  // ── Animasyon ───────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  Timer? _gecisTimer;

  String get _bugun => DateTime.now().toIso8601String().substring(0, 10);

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _gecisTimer?.cancel();
    super.dispose();
  }

  // ── Veri yükleme ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefBugun) == _bugun) {
      if (mounted) setState(() { _limitDoldu = true; _ilkYukleme = false; });
      return;
    }
    final jsonStr = await rootBundle.loadString('assets/data/dertortagi.json');
    final raw     = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data    = raw['dertler'] as Map<String, dynamic>;

    final tumDertler = <String, List<Map<String, dynamic>>>{};
    for (final k in ['genel', 'ask', 'saglik', 'kariyer']) {
      tumDertler[k] = (data[k] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (mounted) {
      setState(() { _tumDertler = tumDertler; _ilkYukleme = false; });
      _fadeCtrl.forward();
    }
  }

  // ── Koşul filtresi ───────────────────────────────────────────────────────────

  bool _kosullarUygun(List<dynamic> kosullar, UserProfile profile) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final m = k as Map;
      if (_profilDegeri(m['degisken'] as String? ?? '', profile) != (m['deger'] as String? ?? '')) {
        return false;
      }
    }
    return true;
  }

  String _profilDegeri(String deg, UserProfile p) {
    switch (deg) {
      case 'cinsiyet':     return p.gender;
      case 'medeni_durum': return p.maritalStatus;
      case 'meslek':       return p.job;
      default:             return '';
    }
  }

  // ── Kategori seçildi ─────────────────────────────────────────────────────────
  // Aynı gün aynı kategoride hep aynı dertler gösterilir.

  Future<void> _kategoriSec(String kategori) async {
    final profile = ref.read(userProfileProvider);
    final prefs   = await SharedPreferences.getInstance();
    final gunlukKey = '$_prefGunluk${kategori}_$_bugun';

    List<Map<String, dynamic>> secilen;

    // Bugün bu kategori için seçim yapıldı mı?
    final savedIds = prefs.getStringList(gunlukKey);
    if (savedIds != null && savedIds.isNotEmpty) {
      final tumK = _tumDertler[kategori] ?? [];
      secilen = savedIds
          .map((id) => tumK.firstWhere((d) => d['id'] == id, orElse: () => <String, dynamic>{}))
          .where((d) => d.isNotEmpty)
          .toList();
    } else {
      // Yeni seçim yap
      final uygunlar = (_tumDertler[kategori] ?? [])
          .where((d) => _kosullarUygun(d['kosullar'] as List<dynamic>, profile))
          .toList();

      if (uygunlar.isEmpty) {
        secilen = [];
      } else {
        // Tekrar gösterilmeme
        final gostKey  = '$_prefGosterilen$kategori';
        List<String> gostIds = prefs.getStringList(gostKey) ?? [];
        List<Map<String, dynamic>> havuz = uygunlar
            .where((d) => !gostIds.contains(d['id'] as String))
            .toList();

        if (havuz.isEmpty) {
          await prefs.remove(gostKey);
          havuz = List.from(uygunlar);
        }

        havuz.shuffle(Random());
        secilen = havuz.take(havuz.length.clamp(1, 6)).toList();
        // Bugünkü seçimi kaydet
        await prefs.setStringList(
          gunlukKey,
          secilen.map((d) => d['id'] as String).toList(),
        );
      }
    }

    if (mounted) {
      setState(() {
        _seciliKategori    = kategori;
        _gosterilenDertler = secilen;
        _adim = _DertAdim.dert;
      });
      _fadeCtrl.forward(from: 0);
    }
  }

  // ── Dert seçildi ─────────────────────────────────────────────────────────────

  Future<void> _dertSec(Map<String, dynamic> dert) async {
    final prefs = await SharedPreferences.getInstance();

    // Gösterilen listeye ekle (farklı günler için no-repeat)
    final gostKey = '$_prefGosterilen$_seciliKategori';
    final ids = prefs.getStringList(gostKey) ?? [];
    final dertId = dert['id'] as String;
    if (!ids.contains(dertId)) {
      ids.add(dertId);
      await prefs.setStringList(gostKey, ids);
    }

    // Günlük limiti işaretle
    await prefs.setString(_prefBugun, _bugun);

    if (!mounted) return;
    setState(() {
      _seciliDert = dert;
      _adim       = _DertAdim.yukleniyor;
    });
    _fadeCtrl.forward(from: 0);

    // 5 saniye sonra tavsiyelere geç
    _gecisTimer?.cancel();
    _gecisTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _adim = _DertAdim.derman);
        _fadeCtrl.forward(from: 0);
      }
    });
  }

  // ── Geri git ─────────────────────────────────────────────────────────────────

  void _geriDon() {
    switch (_adim) {
      case _DertAdim.dert:
        setState(() { _adim = _DertAdim.kategori; });
        _fadeCtrl.forward(from: 0);
      case _DertAdim.yukleniyor:
        _gecisTimer?.cancel();
        setState(() { _adim = _DertAdim.dert; });
        _fadeCtrl.forward(from: 0);
      case _DertAdim.derman:
        context.pop();
      case _DertAdim.kategori:
        context.pop();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: _ilkYukleme
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAA88FF)))
          : _limitDoldu
              ? _buildLimitSayfasi()
              : FadeTransition(opacity: _fadeAnim, child: _buildAdim()),
    );
  }

  Widget _buildAdim() {
    switch (_adim) {
      case _DertAdim.kategori:   return _buildKategoriSayfasi();
      case _DertAdim.dert:       return _buildDertSayfasi();
      case _DertAdim.yukleniyor: return _buildYukleniyorSayfasi();
      case _DertAdim.derman:     return _buildDermanSayfasi();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Limit doldu
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLimitSayfasi() {
    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 20),
                    const Text(
                      'Bugün yeterince dertleştik.',
                      style: TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.bold, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Yarın tekrar gel, her zaman buradayım.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Kategori seçimi (dikeyde ortalı, alta geri butonu)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildKategoriSayfasi() {
    final profile = ref.watch(userProfileProvider);
    final isim    = profile.name.isNotEmpty ? profile.name : '';
    final baslik  = isim.isNotEmpty ? 'Derdin neyle ilgili $isim?' : 'Derdin neyle ilgili?';

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          // Şıklar tam ortalı; balon üstteki boşluğa Stack ile yerleşir
          Expanded(
            child: LayoutBuilder(builder: (ctx, box) {
              return Stack(
                children: [
                  // ① Grid: tam dikey ortalı (şıkların konumu değişmez)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.05,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _KategoriKutu(label: 'Genel',  emoji: '🌀',
                              renk: const Color(0xFF6A3FBF), onTap: () => _kategoriSec('genel')),
                          _KategoriKutu(label: 'Aşk',    emoji: '💜',
                              renk: const Color(0xFFBB1A7A), onTap: () => _kategoriSec('ask')),
                          _KategoriKutu(label: 'Sağlık', emoji: '🌿',
                              renk: const Color(0xFF1A6B4A), onTap: () => _kategoriSec('saglik')),
                          _KategoriKutu(label: 'Kariyer',emoji: '⚡',
                              renk: const Color(0xFF1A3A8F), onTap: () => _kategoriSec('kariyer')),
                        ],
                      ),
                    ),
                  ),
                  // ② Balon: üstteki boş alanda ortalı, şıkları kaydırmaz
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: box.maxHeight * 0.30,
                    child: Center(child: _MagnusBalonu(metin: baslik)),
                  ),
                ],
              );
            }),
          ),
          // Alt geri butonu
          _buildAltGeriButonu(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dert seçimi (dikeyde ortalı, alta geri butonu)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDertSayfasi() {
    if (_gosterilenDertler.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _buildBaslikBar(),
            const Expanded(
              child: Center(
                child: Text('Bu kategori için uygun dert bulunamadı.',
                    style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              ),
            ),
            _buildAltGeriButonu(),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          // Şıklar tam ortalı; balon üstteki boşluğa Stack ile yerleşir
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  // ① Şık listesi: tam dikey ortalı (konumu değişmez)
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < _gosterilenDertler.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _DertSecenegi(
                                metin: _gosterilenDertler[i]['metin'] as String,
                                onTap: () => _dertSec(_gosterilenDertler[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ② Balon: üstteki boş alanda ortalı, şıkları kaydırmaz
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: constraints.maxHeight * 0.22,
                    child: const Center(
                      child: _MagnusBalonu(metin: 'Hangisi seni daha iyi anlatıyor?'),
                    ),
                  ),
                ],
              );
            }),
          ),
          _buildAltGeriButonu(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Kum saati yükleme ekranı
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildYukleniyorSayfasi() {
    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kum saati animasyonu
                  const ElegantHourglass(size: 72, color: Color(0xFFBB88FF)),
                  const SizedBox(height: 28),
                  const Text(
                    'Dertlerini çözümlüyorum...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Biraz sabır...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Derman (tavsiye) sayfası
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDermanSayfasi() {
    final profile   = ref.read(userProfileProvider);
    final varMap    = profile.toVariableMap();
    final dermanlar = (_seciliDert!['dermanlar'] as List).cast<String>();
    final secilenM  = _seciliDert!['metin'] as String;

    return SafeArea(
      child: Column(
        children: [
          _buildBaslikBar(),
          const SizedBox(height: 8),
          const _MagnusBalonu(metin: 'İşte sana tavsiyelerim!'),
          const SizedBox(height: 10),
          // Seçilen dert alıntısı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                '"$secilenM"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dermanlar
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              itemCount: dermanlar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DermanKarti(
                numara: i + 1,
                metin: VariableReplacer.replace(dermanlar[i], varMap),
              ),
            ),
          ),
          // Kapat
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFAA00CC), Color(0xFF7700AA)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF55FF).withValues(alpha: 0.80),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('Teşekkürler',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Ortak widget'lar
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildBaslikBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _geriDon,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              ref.watch(l10nProvider).companionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAltGeriButonu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: GestureDetector(
        onTap: _geriDon,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 2),
              Text(
                ref.read(l10nProvider).backButton,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Magnus konuşma balonu
// ─────────────────────────────────────────────────────────────────────────────

class _MagnusBalonu extends StatelessWidget {
  final String metin;
  const _MagnusBalonu({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFAA88FF), width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset('assets/images/magnusicon.png', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF4835A6),
                child: const Center(
                  child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A1F8C), Color(0xFF4835A6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: const Color(0xFF7B5ECC).withValues(alpha: 0.5)),
            ),
            child: Text(metin,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kategori kutusu
// ─────────────────────────────────────────────────────────────────────────────

class _KategoriKutu extends StatefulWidget {
  final String label, emoji;
  final Color renk;
  final VoidCallback onTap;
  const _KategoriKutu({required this.label, required this.emoji, required this.renk, required this.onTap});

  @override
  State<_KategoriKutu> createState() => _KategoriKutuState();
}

class _KategoriKutuState extends State<_KategoriKutu> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.renk, widget.renk.withValues(alpha: 0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.renk.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [BoxShadow(color: widget.renk.withValues(alpha: 0.35), blurRadius: 10)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 8),
              Text(widget.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dert seçeneği satırı
// ─────────────────────────────────────────────────────────────────────────────

class _DertSecenegi extends StatefulWidget {
  final String metin;
  final VoidCallback onTap;
  const _DertSecenegi({required this.metin, required this.onTap});

  @override
  State<_DertSecenegi> createState() => _DertSecenegiState();
}

class _DertSecenegiState extends State<_DertSecenegi> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _p = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _p
                ? [const Color(0xFF2A1A5C), const Color(0xFF3A2A7C)]
                : [const Color(0xFF1A1040), const Color(0xFF251860)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFAA88FF).withValues(alpha: _p ? 0.6 : 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(widget.metin,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Derman kartı
// ─────────────────────────────────────────────────────────────────────────────

class _DermanKarti extends StatelessWidget {
  final int    numara;
  final String metin;
  const _DermanKarti({required this.numara, required this.metin});

  static const _gradients = [
    [Color(0xFF1A3A6B), Color(0xFF2A4A8F)],
    [Color(0xFF3A1F8C), Color(0xFF4835A6)],
    [Color(0xFF1A5A4A), Color(0xFF2A7A6A)],
    [Color(0xFF5A2A1A), Color(0xFF7A4A2A)],
    [Color(0xFF2A1A5A), Color(0xFF4A3A8A)],
  ];

  @override
  Widget build(BuildContext context) {
    final g = _gradients[(numara - 1) % _gradients.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: g[0].withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$numara',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(metin,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.55)),
          ),
        ],
      ),
    );
  }
}
