// lib/screens/user_screens.dart

import 'package:flutter/material.dart';

// --- History Screen ---
class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Event"),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada riwayat event',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 80, top: 10, left: 16, right: 16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                Color statusColor = item['status'] == 'Selesai'
                    ? Colors.green
                    : (item['status'] == 'Dibatalkan'
                        ? Colors.red
                        : Colors.orange);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['date'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['status'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['eventName'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Tipe: ${item['type'] ?? '-'} • Supir: ${item['driver'] ?? '-'}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --- Menu/Profile Screen ---
class MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final String userPhoto;

  const MenuScreen({
    super.key,
    required this.onLogout,
    this.userName = 'Pengguna',
    this.userEmail = '',
    this.userPhoto = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Halo",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      Text("Selamat",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      Text("Siang! 👋",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: userPhoto.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  userPhoto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(userEmail,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  _menuItem(Icons.notifications, "Notifications"),
                  _menuItem(Icons.message, "Messages", badge: "2"),
                  _menuItem(Icons.person, "My Profile"),
                  _menuItem(Icons.settings, "Settings"),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.grey, shape: BoxShape.circle),
                      child: const Icon(Icons.logout,
                          color: Colors.white, size: 16),
                    ),
                    title: const Text("Logout",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {String? badge}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
              child: Text(badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            )
          : null,
    );
  }
}