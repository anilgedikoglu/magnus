// C:/src/magnus_app/lib/presentation/kehanet/kehanet_menu_screen.dart
// Kehanet ana menüsü - Faloya, Maganda, Tamua, Yana, Kahinlere Sor

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KehanetMenuScreen extends StatelessWidget {
  const KehanetMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KehanetItem('Faloya', 'assets/images/kehanet/faloya.png', '/faloya'),
      _KehanetItem('Maganda', 'assets/images/kehanet/maganda.png', '/maganda'),
      _KehanetItem('Tamua', 'assets/images/kehanet/tamua.png', '/tamua'),
      _KehanetItem('Yana', 'assets/images/kehanet/yana.png', '/yana'),
      _KehanetItem('Kahinlere Sor', 'assets/images/menu/kehanet.png', '/kahinler'),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'KEHANET',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _buildItem(ctx, items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _KehanetItem item) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  item.iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFF55FF),
                    size: 60,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KehanetItem {
  final String label, iconPath, route;
  const _KehanetItem(this.label, this.iconPath, this.route);
}
