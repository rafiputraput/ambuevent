// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import '../service/map_service.dart';

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

  static const LatLng _dinkesLocation =
      LatLng(-7.624662988533274, 111.4947916090254);

  LatLng? _userLocation;
  bool _locationLoaded = false;
  bool _pickingFile = false;

  final List<Map<String, dynamic>> _eventTypes = [
    {'label': 'Konser', 'icon': Icons.music_note},
    {'label': 'Olahraga', 'icon': Icons.emoji_events},
    {'label': 'Pernikahan', 'icon': Icons.people_alt},
    {'label': 'Gathering', 'icon': Icons.work},
    {'label': 'Pengajian', 'icon': Icons.mosque},
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
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _removeDoc(int index) {
    final updated = List<String>.from(widget.uploadedDocNames)
      ..removeAt(index);
    widget.onDocumentsChanged?.call(updated);
  }

  // =====================================================================
  // BUILD UTAMA
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    if (widget.bookingState != 'idle') {
      // Form booking pakai SizedBox.expand agar Column punya height constraint
      return SizedBox.expand(child: _buildBookingForm(context));
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
                  interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.none),
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
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.red.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ],
                            ),
                            child: const Icon(Icons.local_hospital,
                                color: Colors.white, size: 20),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.red, size: 20),
                        ],
                      ),
                    ),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      Colors.blue.withValues(alpha: 0.5),
                                  width: 2),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black38, blurRadius: 3)
                              ],
                            ),
                          ),
                        ]),
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
                          color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.local_hospital,
                          color: Colors.red, size: 16),
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
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey)),
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
                            color: Colors.red, size: 22)),
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.near_me, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        _mapService.formatDistance(_mapService
                            .calculateDistance(_userLocation!, _dinkesLocation)),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const Text(' dari Anda',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
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

  // =====================================================================
  // IDLE CONTENT
  // =====================================================================
  Widget _buildIdleContent() {
    if (widget.role == 'user') return _buildUserIdle();
    return _buildAdminIdle();
  }

  Widget _buildUserIdle() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined,
                size: 56, color: Colors.red),
          ),
          const SizedBox(height: 12),
          const Text('Booking Event',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Sediakan layanan medis standby untuk kelancaran event Anda.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onStartBooking,
              icon: const Icon(Icons.calendar_month, size: 20),
              label: const Text('PESAN AMBULANCE EVENT',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: widget.onGoToMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Lihat Peta Lokasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminIdle() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medical_services_outlined,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Admin',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Kelola booking & armada',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                  left:
                      BorderSide(color: Colors.blue.shade600, width: 4)),
            ),
            child: Row(children: [
              Icon(Icons.notifications_active,
                  size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('3 Jadwal event baru masuk.',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.blue.shade400, size: 18),
            ]),
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
                  Colors.blue, widget.onGoToAdminUser),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _adminMenuCard('Kelola Armada', Icons.local_hospital,
                  Colors.red, widget.onGoToAdminAmb),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _adminMenuCard('Kegiatan', Icons.event_note,
                  Colors.orange, widget.onGoToAdminKegiatan),
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
    final botPad = MediaQuery.of(context).padding.bottom;

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
              child: Text('Detail Event',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: widget.onCancelForm,
              icon: const Icon(Icons.close, color: Colors.grey),
            ),
          ]),
        ),
        const Divider(height: 1),

        // Scrollable body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [
              _buildTextField(
                  'Nama Event', 'Contoh: Konser Fair', widget.nameCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _buildTextField(
                      'Tanggal', 'YYYY-MM-DD', widget.dateCtrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                      'Lokasi', 'Contoh: GBK', widget.locCtrl),
                ),
              ]),
              const SizedBox(height: 20),

              const Text('Tipe Acara:',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: _eventTypes
                    .map((e) => _eventTypeBtn(
                        e['label'] as String, e['icon'] as IconData))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Dokumen
              Row(children: [
                const Text('Dokumen Pendukung:',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: _pickingFile ? null : _pickFiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _pickingFile
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.attach_file,
                              size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text('Pilih File',
                          style: TextStyle(
                              color: Colors.red,
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
                              color: Colors.red.shade300, size: 22),
                          const SizedBox(width: 10),
                          Text('Tap untuk memilih file dari HP',
                              style: TextStyle(
                                  color: Colors.red.shade400,
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
                            size: 18, color: Colors.red.shade300),
                      ),
                    ]),
                  );
                }),
                TextButton.icon(
                  onPressed: _pickingFile ? null : _pickFiles,
                  icon:
                      const Icon(Icons.add, size: 15, color: Colors.grey),
                  label: const Text('Tambah file lagi',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tim medis hadir 1 jam sebelum acara di Loading Dock.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Tombol konfirmasi — FIXED di bawah, di atas nav bar
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
              onPressed: widget.onConfirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'KONFIRMASI JADWAL',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================
  Widget _buildTextField(
      String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _eventTypeBtn(String label, IconData icon) {
    final bool isSelected = widget.eventType == label;
    return GestureDetector(
      onTap: () => widget.onEventTypeChanged(label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          border: Border.all(
              color: isSelected ? Colors.red : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.red : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.red : Colors.grey)),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}