import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    final next = (_currentPage + 1) % _totalPages;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = next);
  }

  void _goPrev() {
    final prev = (_currentPage - 1 + _totalPages) % _totalPages;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = prev);
  }

  // ─── Sayfa 1 ──────────────────────────────────────────────────────────────
  List<_MenuItem> _page1Items(BuildContext context) => [
        _MenuItem('Motivasyon', 'assets/images/motivasyon_yeni.png', 0,
            () => context.push('/motivation')),
        _MenuItem('Dert Ortağı', 'assets/images/menu/dertortagi.png', 1,
            () {}),
        _MenuItem('Olumlama', 'assets/images/olumlama.png', 0,
            () => context.push('/olumlama')),
        _MenuItem('Özlü Sözler', 'assets/images/ozlusozler.png', 0,
            () => context.push('/ozlusoz')),
        _MenuItem('Kader Kitabı', 'assets/images/kadercarkimenu.png', 1,
            () {}),
        _MenuItem('Acı Gerçekler', 'assets/images/acigercekler.PNG', 1,
            () {}),
        _MenuItem('Kehanet', 'assets/images/menu/kehanet.png', 0,
            () {}),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 0,
            () {}),
        _MenuItem('Niyet', 'assets/images/menu/mistikfallar.png', 1,
            () {}),
      ];

  // ─── Sayfa 2 ──────────────────────────────────────────────────────────────
  List<_MenuItem> _page2Items(BuildContext context) => [
        _MenuItem('Kahve Falı', 'assets/images/menu/kahvefali.png', 2,
            () => context.push('/coffee')),
        _MenuItem('Tarot', 'assets/images/menu/tarot.png', 2,
            () => context.push('/tarot')),
        _MenuItem('Astroloji', 'assets/images/astroloji.png', 0,
            () => context.push('/astrology')),
        _MenuItem('Numeroloji', 'assets/images/menu/numeroloji.png', 1,
            () {}),
        _MenuItem('Durugörü', 'assets/images/menu/durugoru.png', 0,
            () {}),
        _MenuItem('Yüz Falı', 'assets/images/menu/yuzfali.png', 1,
            () {}),
        _MenuItem('Japon Falı', 'assets/images/japonfali.png', 1,
            () {}),
        _MenuItem('I-Ching', 'assets/images/ichingikon.png', 1,
            () {}),
        _MenuItem('Aşk Uyumu', 'assets/images/askuyumu.png', 1,
            () {}),
      ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Chat header (sabit) ────────────────────────────────────────
            _buildChatHeader(profile.name),

            // ─── Sayfa göstergesi ──────────────────────────────────────────
            _buildPageIndicator(),

            // ─── Animasyonlu 3×3 grid ──────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
                itemBuilder: (context, pageIndex) {
                  final items = pageIndex == 0
                      ? _page1Items(context)
                      : _page2Items(context);
                  return _buildGrid(items);
                },
              ),
            ),

            // ─── Alt bar ───────────────────────────────────────────────────
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MagnusAvatar(),
              const SizedBox(width: 8),
              Expanded(
                child: _ChatBubble(
                  text: _greeting(name),
                  gradient: const [Color(0xFF1A6B5A), Color(0xFF1A5E6B)],
                  borderColor: const Color(0xFF2DAAA0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MagnusAvatar(),
              const SizedBox(width: 8),
              Expanded(
                child: _ChatBubble(
                  text: "Magnus'un ana menüsü karşında!",
                  gradient: const [Color(0xFF3A1F8C), Color(0xFF4835A6)],
                  borderColor: const Color(0xFF7B5ECC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFAA88FF)
                  : const Color(0xFFAA88FF).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
        children: items.map((item) => _MenuCard(item: item)).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF0A0718),
      child: Row(
        children: [
          // Sol düğme: sayfa 2'de "Önceki", sayfa 1'de "Bilgiler"
          Expanded(
            child: _currentPage == 0
                ? _BottomBtn(
                    imagePath: 'assets/images/bilgiekranilogo.png',
                    label: 'Bilgiler',
                    onTap: () => context.push('/settings'),
                  )
                : _BottomBtn(
                    imagePath: 'assets/images/menuleft.png',
                    label: 'Önceki',
                    onTap: _goPrev,
                  ),
          ),
          const SizedBox(width: 8),
          _BottomIconBtn(
            onTap: () => context.push('/inbox'),
          ),
          const SizedBox(width: 8),
          // Sağ düğme: her zaman "Sonraki"
          Expanded(
            child: _BottomBtn(
              imagePath: 'assets/images/menuright.png',
              label: 'Sonraki',
              iconTrailing: true,
              onTap: _goNext,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    const messages = [
      "Arş'dan müjdeler sana ulaşsın. Mutluluk büsbütün boyunu aşsın.",
      'Yıldızlar seninle konuşmak istiyor.',
      'Kaderinle yüzleşmeye hazır mısın?',
    ];
    final n = name.isNotEmpty ? ' Hoş geldin Sevgili $name! 😊' : '';
    return '${messages[DateTime.now().hour % messages.length]}$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri modeli
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  final String title;
  final String imagePath;
  final int credits;
  final VoidCallback onTap;
  const _MenuItem(this.title, this.imagePath, this.credits, this.onTap);
}

// ─────────────────────────────────────────────────────────────────────────────
// Menü kartı
// ─────────────────────────────────────────────────────────────────────────────

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.item.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCC00BB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCC00BB).withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF1A1040)),
                ),
                // Üst karartma
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Alt karartma
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Başlık
                Positioned(
                  top: 6, left: 6, right: 6,
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Kredi rozeti
                if (widget.item.credits > 0)
                  Positioned(
                    bottom: 5, left: 5,
                    child: _CreditBadge(count: widget.item.credits),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı widget'lar
// ─────────────────────────────────────────────────────────────────────────────

class _CreditBadge extends StatelessWidget {
  final int count;
  const _CreditBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFF00E5FF), size: 10),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final Color borderColor;

  const _ChatBubble({
    required this.text,
    required this.gradient,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _MagnusAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFAA88FF), width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/magnusicon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF4835A6),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final bool iconTrailing;

  const _BottomBtn({
    required this.imagePath,
    required this.label,
    required this.onTap,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(imagePath, width: 23, height: 23);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAA00CC), Color(0xFF7700AA)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconTrailing
              ? [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 6),
                  img,
                ]
              : [
                  img,
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
        ),
      ),
    );
  }
}

class _BottomIconBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _BottomIconBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAA00CC), Color(0xFF7700AA)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/inbox_icon.png',
            width: 29,
            height: 29,
          ),
        ),
      ),
    );
  }
}
