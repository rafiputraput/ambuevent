import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String currentScreen;
  final Function(String) onTab;
  const BottomNav({super.key, required this.currentScreen, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF00FF00),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem("Home", Icons.home, 'home'),
          _navItem("Order", Icons.map, 'map'),
          _navItem("History", Icons.history, 'history'),
          _navItem("Menu", Icons.menu, 'menu'),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, String key) {
    bool isActive = currentScreen == key;
    return GestureDetector(
      onTap: () => onTab(key),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.black54),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.black54)),
        ],
      ),
    );
  }
}