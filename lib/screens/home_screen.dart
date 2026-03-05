// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/map_service.dart';
import '../service/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String bookingState;
  final VoidCallback onStartBooking;
  final VoidCallback onCancelForm;
  final VoidCallback onConfirmBooking;
  final String eventType;
  final Function(String) onEventTypeChanged;
  final TextEditingController nameCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController locCtrl;
  final VoidCallback onGoToAdminUser;
  final VoidCallback onGoToAdminAmb;
  final VoidCallback onGoToMap;
  final VoidCallback onGoToAdminKegiatan;
  final List<String> uploadedDocNames;
  final Function(List<String>)? onDocumentsChanged;

  const HomeScreen({
    super.key,
    required this.role,
    required this.bookingState,
    required this.onStartBooking,
    required this.onCancelForm,
    required this.onConfirmBooking,
    required this.eventType,
    required this.onEventTypeChanged,
    required this.nameCtrl,
    required this.dateCtrl,
    required this.locCtrl,
    required this.onGoToAdminUser,
    required this.onGoToAdminAmb,
    required this.onGoToMap,
    required this.onGoToAdminKegiatan,
    this.uploadedDocNames = const [],
    this.onDocumentsChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();

  static const LatLng _dinkesLocation =
      LatLng(-7.624662988533274, 111.4947916090254);

  LatLng? _userLocation;
  bool _locationLoaded = false;
  bool _pickingFile = false;
  bool _isSubmitting = false;

  DateTime? _selectedDate;

  final List<Map<String, dynamic>> _eventTypes = [
    {'label': 'Konser',       'icon': Icons.music_note},
    {'label': 'Olahraga',     'icon': Icons.emoji_events},
    {'label': 'Pengajian',    'icon': Icons.mosque},
    {'label': 'Pencak Silat', 'icon': Icons.sports_martial_arts},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final location = await _mapService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userLocation = location;
        _locationLoaded = true;
      });
    }
  }

  Future<void> _pickFiles() async {
    if (_pickingFile) return;
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        final newNames = result.files
            .map((f) => f.name)
            .where((name) => !widget.uploadedDocNames.contains(name))
            .toList();
        if (newNames.isNotEmpty) {
          final updated = List<String>.from(widget.uploadedDocNames)
            ..addAll(newNames);
          widget.onDocumentsChanged?.call(updated);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memilih file: $e'),
              backgroundColor: const Color(0xFFD94F4F)),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _removeDoc(int index) {
    final updated = List<String>.from(widget.uploadedDocNames)..removeAt(index);
    widget.onDocumentsChanged?.call(updated);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: const Color(0xFFD94F4F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        widget.dateCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── VALIDASI LALU TAMPILKAN DIALOG KONFIRMASI ──
  void _handleKirimBooking() {
    if (widget.nameCtrl.text.trim().isEmpty) {
      _showSnack('Nama event harus diisi!');
      return;
    }
    if (widget.dateCtrl.text.trim().isEmpty) {
      _showSnack('Tanggal event harus diisi!');
      return;
    }
    if (widget.locCtrl.text.trim().isEmpty) {
      _showSnack('Lokasi event harus diisi!');
      return;
    }
    _showKonfirmasiDialog();
  }

  // ── DIALOG KONFIRMASI SEBELUM SUBMIT ──
  void _showKonfirmasiDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_turned_in,
                      color: const Color(0xFFD94F4F), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Konfirmasi Booking',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Detail ringkasan
              _konfirmasiRow(Icons.event, 'Nama Event',
                  widget.nameCtrl.text.trim()),
              const SizedBox(height: 10),
              _konfirmasiRow(Icons.calendar_today, 'Tanggal',
                  widget.dateCtrl.text.trim()),
              const SizedBox(height: 10),
              _konfirmasiRow(Icons.location_on, 'Lokasi',
                  widget.locCtrl.text.trim()),
              const SizedBox(height: 10),
              _konfirmasiRow(Icons.category, 'Tipe Acara',
                  widget.eventType),

              if (widget.uploadedDocNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                _konfirmasiRow(Icons.attach_file, 'Dokumen',
                    '${widget.uploadedDocNames.length} file terlampir'),
              ],

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD59A)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 16, color: const Color(0xFFB87333)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Booking akan menunggu konfirmasi dari admin. Tim medis hadir 1 jam sebelum acara.',
                      style: TextStyle(fontSize: 11, color: const Color(0xFFD4843A)),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Tombol aksi
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Periksa Lagi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submitBooking();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD94F4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Ya, Kirim!',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _konfirmasiRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD94F4F)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── SUBMIT KE FIRESTORE ──
  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('Silakan login terlebih dahulu!');
        setState(() => _isSubmitting = false);
        return;
      }

      String userName = user.displayName ?? 'Pengguna';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? userName;
        }
      } catch (_) {}

      final bookingId = await _firestoreService.addBooking(
        userId: user.uid,
        userName: userName,
        eventName: widget.nameCtrl.text.trim(),
        date: widget.dateCtrl.text.trim(),
        location: widget.locCtrl.text.trim(),
        type: widget.eventType,
        documentNames: widget.uploadedDocNames,
      );

      if (bookingId != null) {
        widget.onConfirmBooking();
        if (mounted) {
          _showSnack('Booking berhasil dikirim! Menunggu konfirmasi admin.',
              isSuccess: true);
        }
      } else {
        _showSnack('Gagal mengirim booking. Coba lagi.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? const Color(0xFF4CAF7D) : const Color(0xFFD94F4F),
    ));
  }

  // =====================================================================
  // BUILD UTAMA
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    if (widget.bookingState != 'idle') {
      return _buildBookingForm(context);
    }

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _dinkesLocation,
                  initialZoom: 15,
                  maxZoom: 18,
                  minZoom: 5,
                  interactionOptions:
                      InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ambuevent',
                    maxZoom: 18,
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _dinkesLocation,
                      width: 60,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD94F4F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFD94F4F).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ],
                            ),
                            child: const Icon(Icons.local_hospital,
                                color: Colors.white, size: 20),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: const Color(0xFFD94F4F), size: 20),
                        ],
                      ),
                    ),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B8DB8).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF5B8DB8).withValues(alpha: 0.5),
                                    width: 2),
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: const Color(0xFF5B8DB8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black38, blurRadius: 3)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ],
              ),

              if (!_locationLoaded)
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Mendapatkan lokasi...',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),

              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0), shape: BoxShape.circle),
                      child: const Icon(Icons.local_hospital,
                          color: const Color(0xFFD94F4F), size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dinkes Kab. Madiun',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Jl. Raya Solo No. 32, Jiwan',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),

              Positioned(
                bottom: 14,
                right: 14,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onGoToMap,
                    child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.fullscreen,
                            color: const Color(0xFFD94F4F), size: 22)),
                  ),
                ),
              ),

              if (_userLocation != null)
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ]),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me,
                              size: 12, color: const Color(0xFF5B8DB8)),
                          const SizedBox(width: 4),
                          Text(
                            _mapService.formatDistance(
                                _mapService.calculateDistance(
                                    _userLocation!, _dinkesLocation)),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5B8DB8)),
                          ),
                          const Text(' dari Anda',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5))
              ],
            ),
            child: _buildIdleContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleContent() {
    if (widget.role == 'user') return _buildUserIdle();
    return _buildAdminIdle();
  }

  Widget _buildUserIdle() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 70;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0), shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined,
                size: 56, color: const Color(0xFFD94F4F)),
          ),
          const SizedBox(height: 12),
          const Text('Booking Event',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Sediakan layanan medis standby untuk kelancaran event Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onStartBooking,
              icon: const Icon(Icons.add_circle_outline, size: 22),
              label: const Text('BUAT BOOKING BARU',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94F4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: widget.onGoToMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Lihat Peta Lokasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD94F4F),
                side: const BorderSide(color: const Color(0xFFD94F4F)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAdminIdle() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 70;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medical_services_outlined,
                  color: const Color(0xFFD94F4F), size: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Admin',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Kelola booking & armada',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: 'Menunggu Konfirmasi')
                .snapshots(),
            builder: (ctx, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: widget.onGoToAdminKegiatan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                        left: BorderSide(
                            color: const Color(0xFF5B8DB8), width: 4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.notifications_active,
                        size: 18, color: const Color(0xFF5B8DB8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$count booking baru menunggu konfirmasi.',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: const Color(0xFF7AADD4), size: 18),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Menu Utama',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _adminMenuCard('Kelola User', Icons.people_alt,
                  const Color(0xFF5B8DB8), widget.onGoToAdminUser),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _adminMenuCard('Kelola Armada', Icons.local_hospital,
                  const Color(0xFFD94F4F), widget.onGoToAdminAmb),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _adminMenuCard('Kegiatan', Icons.event_note,
                  const Color(0xFFD4843A), widget.onGoToAdminKegiatan),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _adminMenuCard('Peta Event', Icons.map_outlined,
                  Colors.teal, widget.onGoToMap),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _adminMenuCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  // =====================================================================
  // BOOKING FORM
  // =====================================================================
  Widget _buildBookingForm(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).viewPadding.bottom;

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 0),
          child: Row(children: [
            IconButton(
              onPressed: widget.onCancelForm,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black87, size: 20),
            ),
            const Expanded(
              child: Text('Form Booking Event',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: widget.onCancelForm,
              icon: const Icon(Icons.close, color: Colors.grey),
            ),
          ]),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [
              _sectionLabel('Nama Event *'),
              const SizedBox(height: 6),
              _buildTextField(
                  'Contoh: Konser Rakyat Madiun', widget.nameCtrl,
                  icon: Icons.event),

              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Tanggal *'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _buildTextField(
                              'YYYY-MM-DD', widget.dateCtrl,
                              icon: Icons.calendar_today),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Lokasi *'),
                      const SizedBox(height: 6),
                      _buildTextField('Contoh: GOR Madiun', widget.locCtrl,
                          icon: Icons.location_on),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              _sectionLabel('Tipe Acara'),
              const SizedBox(height: 10),
              // Gunakan Column + Row agar tidak ada whitespace berlebih
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _eventTypeBtn(
                          _eventTypes[0]['label'] as String,
                          _eventTypes[0]['icon'] as IconData)),
                      const SizedBox(width: 8),
                      Expanded(child: _eventTypeBtn(
                          _eventTypes[1]['label'] as String,
                          _eventTypes[1]['icon'] as IconData)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _eventTypeBtn(
                          _eventTypes[2]['label'] as String,
                          _eventTypes[2]['icon'] as IconData)),
                      const SizedBox(width: 8),
                      Expanded(child: _eventTypeBtn(
                          _eventTypes[3]['label'] as String,
                          _eventTypes[3]['icon'] as IconData)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(children: [
                _sectionLabel('Dokumen Pendukung'),
                const Spacer(),
                GestureDetector(
                  onTap: _pickingFile ? null : _pickFiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _pickingFile
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: const Color(0xFFD94F4F)))
                          : const Icon(Icons.attach_file,
                              size: 16, color: const Color(0xFFD94F4F)),
                      const SizedBox(width: 4),
                      const Text('Pilih File',
                          style: TextStyle(
                              color: const Color(0xFFD94F4F),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              const Text(
                'PDF, DOC, JPG, PNG — bisa pilih lebih dari satu.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              if (widget.uploadedDocNames.isEmpty)
                GestureDetector(
                  onTap: _pickingFile ? null : _pickFiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file,
                              color: const Color(0xFFD94F4F), size: 22),
                          const SizedBox(width: 10),
                          Text('Tap untuk memilih file dari HP',
                              style: TextStyle(
                                  color: const Color(0xFFD94F4F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                )
              else ...[
                ...widget.uploadedDocNames.asMap().entries.map((entry) {
                  final i = entry.key;
                  final name = entry.value;
                  final ext = name.contains('.')
                      ? name.split('.').last.toLowerCase()
                      : '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(children: [
                      Icon(_fileIcon(ext),
                          color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () => _removeDoc(i),
                        child: Icon(Icons.close,
                            size: 18, color: const Color(0xFFD94F4F)),
                      ),
                    ]),
                  );
                }),
                TextButton.icon(
                  onPressed: _pickingFile ? null : _pickFiles,
                  icon: const Icon(Icons.add, size: 15, color: Colors.grey),
                  label: const Text('Tambah file lagi',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD59A)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 16, color: const Color(0xFFB87333)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tim medis hadir 1 jam sebelum acara. Booking akan dikonfirmasi oleh admin.',
                      style: TextStyle(fontSize: 12, color: const Color(0xFFD4843A)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // ── Tombol Kirim Booking — FIXED di bawah ──
        // Tambah 70 untuk tinggi BottomNav yang menindih dari parent
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              // ← Sekarang panggil _handleKirimBooking (bukan langsung submit)
              onPressed: _isSubmitting ? null : _handleKirimBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94F4F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFFBBBB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Mengirim Booking...',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('KIRIM BOOKING',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(String hint, TextEditingController ctrl,
      {IconData? icon}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: const Color(0xFFD94F4F), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _eventTypeBtn(String label, IconData icon) {
    final bool isSelected = widget.eventType == label;
    return GestureDetector(
      onTap: () => widget.onEventTypeChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F0) : Colors.white,
          border: Border.all(
              color: isSelected ? const Color(0xFFD94F4F) : const Color(0xFF9E9E9E),
              width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? const Color(0xFFD94F4F) : const Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFFD94F4F) : const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext) {
      case 'pdf':  return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':  return Icons.image;
      default:     return Icons.insert_drive_file;
    }
  }
}