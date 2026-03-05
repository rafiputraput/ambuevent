// lib/screens/petugas_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';
import '../service/map_service.dart';

// ─────────────────────────────────────────────────────────────────────
// WRAPPER — mengelola tab aktif petugas
// ─────────────────────────────────────────────────────────────────────
class PetugasHomeWrapper extends StatefulWidget {
  final UserModel petugasUser;
  final VoidCallback onLogout;

  const PetugasHomeWrapper({
    super.key,
    required this.petugasUser,
    required this.onLogout,
  });

  @override
  State<PetugasHomeWrapper> createState() => _PetugasHomeWrapperState();
}

class _PetugasHomeWrapperState extends State<PetugasHomeWrapper> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      PetugasTugasScreen(petugasUser: widget.petugasUser),
      PetugasPetaScreen(petugasUser: widget.petugasUser),
      PetugasProfilScreen(
          petugasUser: widget.petugasUser, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: tabs[_tabIndex],
      bottomNavigationBar: _PetugasBottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// BOTTOM NAV PETUGAS — warna soft, tidak hijau
// ─────────────────────────────────────────────────────────────────────
class _PetugasBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _PetugasBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _activeColor = Color(0xFFD94F4F);
  static const _inactiveColor = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.assignment_outlined, Icons.assignment, 'Tugas'),
              _navItem(1, Icons.map_outlined, Icons.map, 'Peta'),
              _navItem(2, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData iconSelected, String label) {
    final bool selected = currentIndex == idx;
    return GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _activeColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? iconSelected : icon,
                size: 22,
                color: selected ? _activeColor : _inactiveColor),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? _activeColor : _inactiveColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 1 — TUGAS
// ─────────────────────────────────────────────────────────────────────
class PetugasTugasScreen extends StatelessWidget {
  final UserModel petugasUser;
  const PetugasTugasScreen({super.key, required this.petugasUser});

  Color _statusColor(String? s) {
    switch (s) {
      case 'Disetujui': return const Color(0xFF4CAF7D);
      case 'Selesai':   return const Color(0xFF5B8DB8);
      case 'Ditolak':   return const Color(0xFFD94F4F);
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Tugas Saya'),
        centerTitle: true,
        backgroundColor: const Color(0xFFD94F4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('petugasId', isEqualTo: petugasUser.uid)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD94F4F)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada tugas',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  const Text('Tugas yang ditugaskan akan muncul di sini.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Sort by createdAt desc at client
          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
          docs.sort((a, b) {
            final aT = (a.data() as Map)['createdAt'];
            final bT = (b.data() as Map)['createdAt'];
            if (aT == null) return -1;
            if (bT == null) return 1;
            return (bT as dynamic).compareTo(aT as dynamic);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Menunggu';
              final statusColor = _statusColor(status);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor)),
                        ),
                        const Spacer(),
                        Text(data['date'] ?? '-',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 10),
                      Text(data['eventName'] ?? 'Event',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                              data['location'] ?? data['eventLoc'] ?? '-',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                      ]),
                      if (data['ambulancePlate'] != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.local_hospital,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Armada: ${data['ambulancePlate']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ]),
                      ],
                      if (status == 'Disetujui') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(docs[i].id)
                                  .update({'status': 'Selesai'});
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tugas ditandai selesai!'),
                                    backgroundColor: Color(0xFF4CAF7D),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 16),
                            label: const Text('Tandai Selesai'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF7D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 2 — PETA
// ─────────────────────────────────────────────────────────────────────
class PetugasPetaScreen extends StatefulWidget {
  final UserModel petugasUser;
  const PetugasPetaScreen({super.key, required this.petugasUser});

  @override
  State<PetugasPetaScreen> createState() => _PetugasPetaScreenState();
}

class _PetugasPetaScreenState extends State<PetugasPetaScreen> {
  final MapService _mapService = MapService();
  LatLng? _userLocation;
  bool _sharing = false;

  static const LatLng _dinkesLocation =
      LatLng(-7.624662988533274, 111.4947916090254);

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await _mapService.getCurrentLocation();
    if (mounted) setState(() => _userLocation = loc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation ?? _dinkesLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ambuevent',
              ),
              MarkerLayer(markers: [
                // Dinkes marker
                Marker(
                  point: _dinkesLocation,
                  width: 40, height: 40,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFD94F4F), shape: BoxShape.circle),
                    child: const Icon(Icons.local_hospital,
                        color: Colors.white, size: 20),
                  ),
                ),
                // User location
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 40, height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B8DB8), shape: BoxShape.circle),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
                  ),
              ]),
            ],
          ),

          // Header info
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8)
                ],
              ),
              child: Row(children: [
                Icon(
                  _sharing
                      ? Icons.location_on
                      : Icons.location_off,
                  color: _sharing
                      ? const Color(0xFF4CAF7D)
                      : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Berbagi Lokasi: ${_sharing ? "ON" : "OFF"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ]),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20,
                  20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _sharing = !_sharing),
                      icon: Icon(
                          _sharing ? Icons.stop : Icons.play_arrow,
                          size: 20),
                      label: Text(
                          _sharing
                              ? 'Stop Berbagi Lokasi'
                              : 'Mulai Berbagi Lokasi GPS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sharing
                            ? Colors.grey.shade600
                            : const Color(0xFF4CAF7D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada event aktif yang ditugaskan saat ini.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 3 — PROFIL
// ─────────────────────────────────────────────────────────────────────
class PetugasProfilScreen extends StatelessWidget {
  final UserModel petugasUser;
  final VoidCallback onLogout;

  const PetugasProfilScreen({
    super.key,
    required this.petugasUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: const Color(0xFFD94F4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFD94F4F),
                backgroundImage: petugasUser.photoUrl.isNotEmpty
                    ? NetworkImage(petugasUser.photoUrl)
                    : null,
                child: petugasUser.photoUrl.isEmpty
                    ? Text(
                        petugasUser.name.isNotEmpty
                            ? petugasUser.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(petugasUser.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD94F4F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('PETUGAS',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          _infoCard('Email', petugasUser.email, Icons.email_outlined),
          const SizedBox(height: 12),
          _infoCard('Role', 'Petugas Ambulance', Icons.medical_services_outlined),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Color(0xFFD94F4F)),
              label: const Text('Logout',
                  style: TextStyle(
                      color: Color(0xFFD94F4F),
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD94F4F)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFD94F4F), size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ]),
    );
  }
}