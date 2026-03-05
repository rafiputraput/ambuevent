// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String currentScreen;
  final void Function(String) onTab;

  const BottomNav({
    super.key,
    required this.currentScreen,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Putih bersih, tidak hijau
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            iconSelected: Icons.home,
            label: 'Home',
            isSelected: currentScreen == 'home',
            onTap: () => onTab('home'),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            iconSelected: Icons.map,
            label: 'Order',
            isSelected: currentScreen == 'map',
            onTap: () => onTab('map'),
          ),
          _NavItem(
            icon: Icons.history_outlined,
            iconSelected: Icons.history,
            label: 'History',
            isSelected: currentScreen == 'history',
            onTap: () => onTab('history'),
          ),
          _NavItem(
            icon: Icons.menu_outlined,
            iconSelected: Icons.menu,
            label: 'Menu',
            isSelected: currentScreen == 'menu',
            onTap: () => onTab('menu'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  // Warna utama soft red — konsisten dengan tema app
  static const _activeColor = Color(0xFFD94F4F);
  static const _inactiveColor = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconSelected : icon,
              size: 22,
              color: isSelected ? _activeColor : _inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}