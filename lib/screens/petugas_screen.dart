// lib/screens/petugas_screen.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../service/map_service.dart';
import '../service/routing_service.dart';
import '../models/user_models.dart';

// =====================================================================
// WRAPPER
// =====================================================================
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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      PetugasDashboardScreen(petugasUser: widget.petugasUser),
      PetugasMapScreen(petugasUser: widget.petugasUser),
      PetugasProfileScreen(
          petugasUser: widget.petugasUser, onLogout: widget.onLogout),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF00FF00),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard, 'Tugas'),
                _navItem(1, Icons.map, 'Peta'),
                _navItem(2, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.black45, size: 26),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.black45)),
        ],
      ),
    );
  }
}

// =====================================================================
// 1. DASHBOARD
// =====================================================================
class PetugasDashboardScreen extends StatefulWidget {
  final UserModel petugasUser;
  const PetugasDashboardScreen({super.key, required this.petugasUser});

  @override
  State<PetugasDashboardScreen> createState() => _PetugasDashboardScreenState();
}

class _PetugasDashboardScreenState extends State<PetugasDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _myAmbulance;
  bool _loadingAmb = true;

  @override
  void initState() {
    super.initState();
    _listenMyAmbulance();
  }

  void _listenMyAmbulance() {
    _db
        .collection('ambulances')
        .where('petugasId', isEqualTo: widget.petugasUser.uid)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _myAmbulance = snap.docs.isEmpty
              ? null
              : {...snap.docs.first.data(), 'id': snap.docs.first.id};
          _loadingAmb = false;
        });
      }
    });
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Tersedia':    return Colors.green;
      case 'Booked Event': return Colors.blue;
      case 'Maintenance': return Colors.orange;
      default:            return Colors.grey;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'Tersedia':    return Icons.check_circle;
      case 'Booked Event': return Icons.event_available;
      case 'Maintenance': return Icons.build;
      default:            return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        backgroundImage: widget.petugasUser.photoUrl.isNotEmpty
                            ? NetworkImage(widget.petugasUser.photoUrl)
                            : null,
                        child: widget.petugasUser.photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Halo, Petugas 👋',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(widget.petugasUser.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('PETUGAS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loadingAmb)
                    const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                  else if (_myAmbulance == null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Belum ada armada yang di-assign ke Anda.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital,
                              color: Colors.red, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_myAmbulance!['plate'] ?? '-',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              const Text('Armada saya',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(_myAmbulance!['status'])
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(_myAmbulance!['status'])),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_statusIcon(_myAmbulance!['status']),
                                size: 12,
                                color: _statusColor(_myAmbulance!['status'])),
                            const SizedBox(width: 4),
                            Text(
                              _myAmbulance!['status'] ?? '-',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(_myAmbulance!['status'])),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  Row(children: [
                    _summaryCard(
                      icon: Icons.calendar_today,
                      label: 'Tugas Aktif',
                      color: Colors.blue,
                      valueWidget: StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('bookings')
                            .where('petugasId', isEqualTo: widget.petugasUser.uid)
                            .where('status', isEqualTo: 'Menunggu Konfirmasi')
                            .snapshots(),
                        builder: (ctx, snap) => Text(
                          '${snap.data?.docs.length ?? 0}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      icon: Icons.check_circle_outline,
                      label: 'Selesai',
                      color: Colors.green,
                      valueWidget: StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('bookings')
                            .where('petugasId', isEqualTo: widget.petugasUser.uid)
                            .where('status', isEqualTo: 'Selesai')
                            .snapshots(),
                        builder: (ctx, snap) => Text(
                          '${snap.data?.docs.length ?? 0}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Daftar Booking Ditugaskan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('bookings')
                        .where('petugasId', isEqualTo: widget.petugasUser.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.red));
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return _emptyBooking();
                      }
                      return Column(
                        children: snap.data!.docs.map((doc) {
                          return _bookingCard(
                              doc.data() as Map<String, dynamic>, doc.id);
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Booking dari pelanggan akan muncul di sini setelah admin menugaskan Anda.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required Color color,
    required Widget valueWidget,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          valueWidget,
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _emptyBooking() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('Belum ada tugas booking',
            style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _bookingCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? '-';
    final statusColor = status == 'Selesai'
        ? Colors.green
        : status == 'Dibatalkan'
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(data['eventName'] ?? 'Event',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today, data['date'] ?? '-'),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on, data['location'] ?? '-'),
          const SizedBox(height: 4),
          _infoRow(Icons.local_activity, data['type'] ?? '-'),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

// =====================================================================
// 2. PETA PETUGAS
// =====================================================================
class PetugasMapScreen extends StatefulWidget {
  final UserModel petugasUser;
  const PetugasMapScreen({super.key, required this.petugasUser});

  @override
  State<PetugasMapScreen> createState() => _PetugasMapScreenState();
}

class _PetugasMapScreenState extends State<PetugasMapScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final RoutingService _routingService = RoutingService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const LatLng _defaultCenter = LatLng(-7.6298, 111.5239);

  LatLng? _myLocation;
  bool _isSharing = false;
  bool _loadingLocation = true;
  bool _showPuskesmas = true;

  String? _ambId;
  Map<String, dynamic>? _activeBooking;
  LatLng? _eventLocation;
  List<LatLng> _routePoints = [];
  RouteResult? _routeResult;
  bool _loadingRoute = false;

  StreamSubscription<LatLng>? _locationSub;
  Timer? _shareTimer;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _shareTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAll() async {
    final loc = await _mapService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _myLocation = loc ?? _defaultCenter;
        _loadingLocation = false;
      });
      if (loc != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _mapController.move(loc, 14);
        });
      }
    }

    final snap = await _db
        .collection('ambulances')
        .where('petugasId', isEqualTo: widget.petugasUser.uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) _ambId = snap.docs.first.id;

    _locationSub = _mapService.getLocationStream().listen((latLng) {
      if (mounted) setState(() => _myLocation = latLng);
      if (_isSharing && _ambId != null) {
        _mapService.updateAmbulanceLocation(_ambId!, latLng);
      }
    });

    _listenActiveBooking();
  }

  void _listenActiveBooking() {
    _db
        .collection('bookings')
        .where('petugasId', isEqualTo: widget.petugasUser.uid)
        .where('status', isEqualTo: 'Menunggu Konfirmasi')
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _activeBooking = {...data, 'id': snap.docs.first.id};
          _eventLocation = LatLng(
            (_myLocation?.latitude ?? _defaultCenter.latitude) + 0.012,
            (_myLocation?.longitude ?? _defaultCenter.longitude) + 0.018,
          );
        });
      } else {
        setState(() {
          _activeBooking = null;
          _eventLocation = null;
          _routePoints = [];
          _routeResult = null;
        });
      }
    });
  }

  void _toggleSharing() {
    setState(() => _isSharing = !_isSharing);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isSharing
          ? '📍 Lokasi mulai dibagikan ke sistem'
          : 'Berbagi lokasi dihentikan'),
      backgroundColor: _isSharing ? Colors.green : Colors.grey,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _loadRouteToEvent() async {
    if (_myLocation == null || _eventLocation == null) return;
    setState(() {
      _loadingRoute = true;
      _routePoints = [];
      _routeResult = null;
    });
    final result = await _routingService.getRoute(_myLocation!, _eventLocation!);
    if (mounted) {
      setState(() {
        _loadingRoute = false;
        if (result != null) {
          _routePoints = result.points;
          _routeResult = result;
        }
      });
      if (result != null && result.points.isNotEmpty) _fitBounds(result.points);
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(minLat - 0.005, minLng - 0.005),
        LatLng(maxLat + 0.005, maxLng + 0.005),
      ),
      padding: const EdgeInsets.all(60),
    ));
  }

  // ── Shared modal helper — FIX: isScrollControlled + padding safe area ──
  void _showSheet(Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom
            + MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: content,
        );
      },
    );
  }

  void _showPuskesmasInfo(PuskesmasLocation puskesmas) {
    _showSheet(
      Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital,
                    color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(puskesmas.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('No. ${puskesmas.no}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(puskesmas.address,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            ]),
            if (_myLocation != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(children: [
                _infoChip(
                  Icons.straighten,
                  _mapService.formatDistance(
                      _mapService.calculateDistance(_myLocation!, puskesmas.latLng)),
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.access_time,
                  _mapService.estimateTime(
                      _mapService.calculateDistance(_myLocation!, puskesmas.latLng)),
                  Colors.orange,
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pakai viewPadding agar dapat gesture bar height meski parent Scaffold sudah consume padding
    final bottomNavHeight = 65.0 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: false,
      body: Stack(
        children: [
          // ── PETA — dibatasi agar tidak bocor ke bawah nav bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            bottom: bottomNavHeight,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _myLocation ?? _defaultCenter,
                initialZoom: 13,
                maxZoom: 18,
                minZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ambuevent',
                  maxZoom: 18,
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.5),
                  ]),
                MarkerLayer(markers: [
                  if (_myLocation != null)
                    Marker(
                        point: _myLocation!, width: 60, height: 60,
                        child: _myMarker()),
                  if (_eventLocation != null)
                    Marker(
                        point: _eventLocation!, width: 50, height: 60,
                        child: _eventMarker()),
                  if (_showPuskesmas)
                    ..._mapService.getPuskesmasList().map((p) => Marker(
                          point: p.latLng, width: 40, height: 40,
                          child: GestureDetector(
                            onTap: () => _showPuskesmasInfo(p),
                            child: _puskesmasMarker(),
                          ),
                        )),
                ]),
                const RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ]),
              ],
            ),
          ),

          if (_loadingLocation)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 12),
                      Text('Mendapatkan lokasi...'),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Top Bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(
                        _isSharing
                            ? Icons.wifi_tethering
                            : Icons.wifi_tethering_off,
                        color: _isSharing ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSharing
                            ? 'Berbagi Lokasi: ON'
                            : 'Berbagi Lokasi: OFF',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isSharing ? Colors.green : Colors.grey),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ── Legend + Toggle Puskesmas ──
          Positioned(
            right: 12, top: 100,
            child: Column(children: [
              _legendItem(Colors.blue, Icons.person_pin_circle, 'Lokasi Saya'),
              const SizedBox(height: 8),
              _legendItem(Colors.orange, Icons.event, 'Lokasi Event'),
              const SizedBox(height: 8),
              Material(
                color: _showPuskesmas ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 3,
                child: InkWell(
                  onTap: () => setState(() => _showPuskesmas = !_showPuskesmas),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_hospital,
                          color: _showPuskesmas ? Colors.white : Colors.green,
                          size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Puskesmas (${_mapService.getPuskesmasList().length})',
                        style: TextStyle(
                            fontSize: 10,
                            color: _showPuskesmas ? Colors.white : Colors.black),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),

          // ── Recenter ──
          Positioned(
            right: 12,
            bottom: bottomNavHeight + _panelHeight() + 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (_myLocation != null) _mapController.move(_myLocation!, 15);
                },
                child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.my_location, color: Colors.blue, size: 24)),
              ),
            ),
          ),

          // ── Bottom Panel ──
          Positioned(
            bottom: bottomNavHeight,
            left: 0, right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  double _panelHeight() {
    if (_activeBooking != null) return _routeResult != null ? 260 : 220;
    return 120;
  }

  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleSharing,
                icon: Icon(_isSharing ? Icons.stop_circle : Icons.play_circle),
                label: Text(
                  _isSharing
                      ? 'Hentikan Berbagi Lokasi'
                      : 'Mulai Berbagi Lokasi GPS',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_activeBooking != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_available,
                      color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_activeBooking!['eventName'] ?? 'Event Aktif',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '${_activeBooking!['date'] ?? '-'} • ${_activeBooking!['location'] ?? '-'}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadingRoute ? null : _loadRouteToEvent,
                  icon: _loadingRoute
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.route, size: 18),
                  label: Text(
                    _loadingRoute
                        ? 'Menghitung rute...'
                        : 'Lihat Rute ke Lokasi Event',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_routeResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _routeChip(Icons.straighten,
                          _routingService.formatDistance(
                              _routeResult!.distanceMeters)),
                      _routeChip(Icons.access_time,
                          _routingService.formatDuration(
                              _routeResult!.durationSeconds)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              const Text(
                'Tidak ada event aktif yang ditugaskan saat ini.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _routeChip(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.blue),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _myMarker() {
    return Stack(alignment: Alignment.center, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _isSharing
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
              color: _isSharing
                  ? Colors.green.withValues(alpha: 0.6)
                  : Colors.blue.withValues(alpha: 0.5),
              width: 2),
        ),
      ),
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: _isSharing ? Colors.green : Colors.blue,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 12),
      ),
    ]);
  }

  Widget _eventMarker() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.orange, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: const Icon(Icons.event, color: Colors.white, size: 18),
      ),
      const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 20),
    ]);
  }

  Widget _puskesmasMarker() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.local_hospital, color: Colors.green, size: 16),
    );
  }
}

// =====================================================================
// 3. PROFIL
// =====================================================================
class PetugasProfileScreen extends StatelessWidget {
  final UserModel petugasUser;
  final VoidCallback onLogout;
  const PetugasProfileScreen({
    super.key,
    required this.petugasUser,
    required this.onLogout,
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
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: petugasUser.photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                petugasUser.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 40, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 40, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(petugasUser.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(petugasUser.email,
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
        decoration: BoxDecoration(
            color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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