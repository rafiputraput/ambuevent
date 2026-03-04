// lib/screens/user_screens.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================================
// HISTORY SCREEN — baca dari Firestore real-time
// =====================================================================
class HistoryScreen extends StatelessWidget {
  // Parameter lama dipertahankan agar tidak breaking change di main.dart
  final List<Map<String, dynamic>> history;
  const HistoryScreen({super.key, required this.history});

  Color _statusColor(String? status) {
    switch (status) {
      case 'Disetujui': return Colors.green;
      case 'Selesai':   return Colors.blue;
      case 'Ditolak':
      case 'Dibatalkan': return Colors.red;
      default:          return Colors.orange; // Menunggu Konfirmasi
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Disetujui': return Icons.check_circle;
      case 'Selesai':   return Icons.done_all;
      case 'Ditolak':
      case 'Dibatalkan': return Icons.cancel;
      default:          return Icons.hourglass_empty;
    }
  }

  IconData _eventIcon(String? type) {
    switch (type) {
      case 'Konser':       return Icons.music_note;
      case 'Olahraga':     return Icons.emoji_events;
      case 'Pengajian':    return Icons.mosque;
      case 'Pencak Silat': return Icons.sports_martial_arts;
      default:             return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: uid == null
          ? _emptyState(
              Icons.lock_outline,
              'Belum Login',
              'Silakan login untuk melihat riwayat booking.')
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState(
                    Icons.history,
                    'Belum ada riwayat booking',
                    'Booking yang kamu buat akan muncul di sini.',
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _BookingCard(
                      data: data,
                      docId: docs[i].id,
                      statusColor: _statusColor(data['status']),
                      statusIcon: _statusIcon(data['status']),
                      eventIcon: _eventIcon(data['type']),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Card booking ──────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final Color statusColor;
  final IconData statusIcon;
  final IconData eventIcon;

  const _BookingCard({
    required this.data,
    required this.docId,
    required this.statusColor,
    required this.statusIcon,
    required this.eventIcon,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Menunggu Konfirmasi';
    final docs = (data['documents'] as List?)?.cast<String>() ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris atas: status badge + tanggal ──
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ]),
              ),
              const Spacer(),
              Text(data['date'] ?? '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),

            const SizedBox(height: 12),

            // ── Info event ──
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(eventIcon, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['eventName'] ?? 'Event',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['type'] ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Detail ──
            _infoRow(Icons.location_on,
                data['location'] ?? data['eventLoc'] ?? '-'),
            const SizedBox(height: 4),

            if (data['petugasName'] != null &&
                data['petugasName'].toString().isNotEmpty) ...[
              _infoRow(Icons.medical_services,
                  'Petugas: ${data['petugasName']}',
                  color: Colors.green),
              const SizedBox(height: 4),
            ],

            if (data['ambulancePlate'] != null &&
                data['ambulancePlate'].toString().isNotEmpty)
              _infoRow(Icons.local_hospital,
                  'Armada: ${data['ambulancePlate']}',
                  color: Colors.blue),

            // ── Dokumen ──
            if (docs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: docs.map((name) {
                  final short = name.length > 22
                      ? '${name.substring(0, 22)}...'
                      : name;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.attach_file,
                          size: 11, color: Colors.blue.shade700),
                      const SizedBox(width: 3),
                      Text(short,
                          style: TextStyle(
                              fontSize: 11, color: Colors.blue.shade700)),
                    ]),
                  );
                }).toList(),
              ),
            ],

            // ── Tombol Batalkan (hanya jika masih menunggu) ──
            if (status == 'Menunggu Konfirmasi') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: Colors.red),
                  label: const Text('Batalkan Booking',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 14, color: color ?? Colors.grey),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 12, color: color ?? Colors.grey)),
      ),
    ]);
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: Text(
            'Yakin ingin membatalkan booking "${data['eventName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(docId)
                  .update({'status': 'Dibatalkan'});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking berhasil dibatalkan.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// MENU / PROFILE SCREEN
// =====================================================================
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
                  Column(children: [
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
                  ]),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(children: [
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
              ]),
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
        decoration:
            BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
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
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
            )
          : null,
    );
  }
}