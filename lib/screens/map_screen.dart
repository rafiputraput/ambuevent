// lib/screens/map_screen.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../service/map_service.dart';
import '../service/routing_service.dart';

class MapScreen extends StatefulWidget {
  final String bookingState;
  final String eventName;
  final String eventDate;
  final String eventLoc;
  final VoidCallback onCancel;

  const MapScreen({
    super.key,
    required this.bookingState,
    required this.eventName,
    required this.eventDate,
    required this.eventLoc,
    required this.onCancel,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final RoutingService _routingService = RoutingService();

  static const LatLng _defaultCenter = LatLng(-7.6298, 111.5239);

  LatLng? _userLocation;
  LatLng? _eventLocation;
  List<AmbulanceLocation> _ambulances = [];
  List<LatLng> _routePoints = [];
  RouteResult? _routeResult;

  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  bool _showPuskesmas = true;
  String? _selectedAmbulanceId;

  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<List<AmbulanceLocation>>? _ambulanceSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenAmbulances();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _ambulanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    final location = await _mapService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userLocation = location ?? _defaultCenter;
        _isLoadingLocation = false;
      });
      if (location != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _mapController.move(location, 14);
        });
      }
    }
    _locationSubscription = _mapService.getLocationStream().listen((latLng) {
      if (mounted) setState(() => _userLocation = latLng);
    });
    if (widget.eventLoc.isNotEmpty) {
      _eventLocation = LatLng(
        (_userLocation?.latitude ?? _defaultCenter.latitude) + 0.01,
        (_userLocation?.longitude ?? _defaultCenter.longitude) + 0.015,
      );
    }
  }

  void _listenAmbulances() {
    _ambulanceSubscription =
        _mapService.getAmbulancesLocation().listen((ambulances) {
      if (mounted) setState(() => _ambulances = ambulances);
    });
  }

  Future<void> _loadRoute(LatLng from, LatLng to) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
      _routeResult = null;
    });
    final result = await _routingService.getRoute(from, to);
    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        if (result != null) {
          _routePoints = result.points;
          _routeResult = result;
        }
      });
      if (result != null && result.points.isNotEmpty) {
        _fitRouteBounds(result.points);
      }
    }
  }

  void _fitRouteBounds(List<LatLng> points) {
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

  void _onAmbulanceTap(AmbulanceLocation amb) {
    setState(() => _selectedAmbulanceId = amb.id);
    final destination = _userLocation ?? _eventLocation;
    if (destination != null) _loadRoute(amb.latLng, destination);
    _mapController.move(amb.latLng, 14);
    _showAmbulanceSheet(amb);
  }

  // ── Modal helper — safe area selalu diperhitungkan ──
  void _showSheet(Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final safePad = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: safePad),
          child: content,
        );
      },
    );
  }

  void _showAmbulanceSheet(AmbulanceLocation amb) {
    final destination = _userLocation ?? _defaultCenter;
    final distance = _mapService.calculateDistance(amb.latLng, destination);
    _showSheet(Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(),
        Row(children: [
          _iconBox(Icons.local_hospital, Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(amb.plate,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Petugas: ${amb.petugasName ?? 'Belum ada'}',
                  style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          _badge(amb.status, Colors.green),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _infoChip(Icons.straighten, _mapService.formatDistance(distance), Colors.blue),
          const SizedBox(width: 12),
          _infoChip(Icons.access_time, _mapService.estimateTime(distance), Colors.orange),
        ]),
        if (_isLoadingRoute) ...[
          const SizedBox(height: 16),
          const Row(children: [
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Menghitung rute...', style: TextStyle(color: Colors.grey)),
          ]),
        ],
        if (_routeResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.route, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Rute: ${_routingService.formatDistance(_routeResult!.distanceMeters)} • '
                '${_routingService.formatDuration(_routeResult!.durationSeconds)}',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
              )),
            ]),
          ),
        ],
      ]),
    ));
  }

  void _showPuskesmasSheet(PuskesmasLocation puskesmas) {
    _showSheet(Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        _handle(),
        Row(children: [
          _iconBox(Icons.local_hospital, Colors.green),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(puskesmas.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('No. ${puskesmas.no}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(puskesmas.address,
              style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ]),
        if (_userLocation != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(children: [
            _infoChip(Icons.straighten,
                _mapService.formatDistance(
                    _mapService.calculateDistance(_userLocation!, puskesmas.latLng)),
                Colors.blue),
            const SizedBox(width: 12),
            _infoChip(Icons.access_time,
                _mapService.estimateTime(
                    _mapService.calculateDistance(_userLocation!, puskesmas.latLng)),
                Colors.orange),
          ]),
        ],
      ]),
    ));
  }

  // ── Shared small widgets ──
  Widget _handle() => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: color, size: 28),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    // navH = tinggi bottom nav bar (70) + viewPadding bawah (gesture bar / home indicator)
    // Pakai viewPadding (bukan padding) karena Scaffold parent mungkin sudah consume padding
    final mq = MediaQuery.of(context);
    final navH = 70.0 + mq.viewPadding.bottom;

    return Scaffold(
      // Pastikan konten tidak extend ke bawah nav bar
      extendBody: false,
      body: Stack(children: [

        // ── PETA — beri padding bottom agar tidak bocor ke bawah nav bar ──
        Positioned(
          top: 0, left: 0, right: 0,
          bottom: navH,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _defaultCenter,
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
                  Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 4),
                ]),
              MarkerLayer(markers: [
                if (_userLocation != null)
                  Marker(point: _userLocation!, width: 60, height: 60,
                      child: _userMarker()),
                if (_eventLocation != null)
                  Marker(point: _eventLocation!, width: 50, height: 60,
                      child: _eventMarker()),
                if (_showPuskesmas)
                  ..._mapService.getPuskesmasList().map((p) => Marker(
                    point: p.latLng, width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => _showPuskesmasSheet(p),
                      child: _puskesmasMarker(),
                    ),
                  )),
                ..._ambulances.map((amb) => Marker(
                  point: amb.latLng, width: 60, height: 60,
                  child: GestureDetector(
                    onTap: () => _onAmbulanceTap(amb),
                    child: _ambulanceMarker(isSelected: _selectedAmbulanceId == amb.id),
                  ),
                )),
              ]),
              const RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ]),
            ],
          ),
        ),

        // ── Loading ──
        if (_isLoadingLocation)
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

        // ── Top bar ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Material(
                  color: Colors.white, shape: const CircleBorder(), elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onCancel,
                    child: const Padding(padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back, size: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.event, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.eventName.isEmpty ? 'Peta Event' : widget.eventName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Legend kanan ──
        Positioned(
          right: 12, top: 100,
          child: Column(children: [
            _legendItem(Colors.blue, Icons.person_pin_circle, 'Lokasi Saya'),
            const SizedBox(height: 8),
            _legendItem(Colors.green, Icons.location_on, 'Lokasi Event'),
            const SizedBox(height: 8),
            _legendItem(Colors.red, Icons.local_hospital, 'Ambulance'),
            const SizedBox(height: 8),
            Material(
              color: _showPuskesmas ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 3,
              child: InkWell(
                onTap: () => setState(() => _showPuskesmas = !_showPuskesmas),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_hospital,
                        color: _showPuskesmas ? Colors.white : Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text('Puskesmas (${_mapService.getPuskesmasList().length})',
                        style: TextStyle(
                            fontSize: 10,
                            color: _showPuskesmas ? Colors.white : Colors.black)),
                  ]),
                ),
              ),
            ),
          ]),
        ),

        // ── Recenter — posisi di atas bottom card ──
        Positioned(
          right: 12,
          bottom: navH + _cardHeight() + 12,
          child: Material(
            color: Colors.white, shape: const CircleBorder(), elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (_userLocation != null) _mapController.move(_userLocation!, 15);
              },
              child: const Padding(padding: EdgeInsets.all(12),
                  child: Icon(Icons.my_location, color: Colors.blue, size: 24)),
            ),
          ),
        ),

        // ── Bottom card — tepat di atas nav bar ──
        Positioned(
          left: 16, right: 16,
          bottom: navH,          // <-- kunci: naik setinggi nav bar
          child: _buildBottomCard(),
        ),

      ]),
    );
  }

  double _cardHeight() {
    switch (widget.bookingState) {
      case 'searching': return 160;
      case 'booked':    return 210;
      default:          return 80;
    }
  }

  // ── Marker widgets ──
  Widget _userMarker() => Stack(alignment: Alignment.center, children: [
    Container(width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle,
          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2))),
    Container(width: 18, height: 18,
        decoration: const BoxDecoration(
          color: Colors.blue, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)]),
        child: const Icon(Icons.person, color: Colors.white, size: 12)),
  ]);

  Widget _eventMarker() => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)]),
      child: const Icon(Icons.event, color: Colors.white, size: 18)),
    const Icon(Icons.arrow_drop_down, color: Colors.green, size: 20),
  ]);

  Widget _ambulanceMarker({bool isSelected = false}) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: isSelected ? Colors.red : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.red, width: isSelected ? 3 : 2),
      boxShadow: [BoxShadow(
        color: Colors.red.withOpacity(0.4),
        blurRadius: isSelected ? 10 : 4,
        spreadRadius: isSelected ? 2 : 0)],
    ),
    child: Icon(Icons.local_hospital,
        color: isSelected ? Colors.white : Colors.red, size: 22),
  );

  Widget _puskesmasMarker() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white, shape: BoxShape.circle,
      border: Border.all(color: Colors.green, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
    child: const Icon(Icons.local_hospital, color: Colors.green, size: 16),
  );

  Widget _legendItem(Color color, IconData icon, String label) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(8), elevation: 3,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]),
    ),
  );

  // ── Bottom card per state ──
  Widget _buildBottomCard() {
    switch (widget.bookingState) {
      case 'searching':
        return Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 10),
              const Text('Memverifikasi Ketersediaan...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Harap tunggu sebentar',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.red, size: 16),
                label: const Text('Batalkan', style: TextStyle(color: Colors.red)),
              ),
            ]),
          ),
        );

      case 'booked':
        return Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Row(children: [
                    Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text('BOOKING TERKIRIM',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Spacer(),
                if (_ambulances.isNotEmpty)
                  Text('${_ambulances.length} ambulance aktif',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.local_hospital, color: Colors.red, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.eventName.isEmpty ? 'Event Baru' : widget.eventName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${widget.eventDate} • ${widget.eventLoc}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
              ]),
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                'Tap marker ambulance 🚑 atau Puskesmas 🏥 untuk detail',
                style: TextStyle(fontSize: 11, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  child: const Text('Kembali ke Menu Utama'),
                ),
              ),
            ]),
          ),
        );

      default:
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Tap marker untuk melihat detail. ${_showPuskesmas ? '🏥 Puskesmas aktif' : ''}',
                style: const TextStyle(fontSize: 12),
              )),
              if (_ambulances.isEmpty)
                const Text('Tidak ada\nambulance aktif',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.right),
            ]),
          ),
        );
    }
  }
}