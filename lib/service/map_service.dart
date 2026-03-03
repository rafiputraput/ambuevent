// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// === MODEL AMBULANCE ===
class AmbulanceLocation {
  final String id;
  final String plate;
  final String? petugasName;
  final String status;
  final LatLng latLng;

  AmbulanceLocation({
    required this.id,
    required this.plate,
    this.petugasName,
    required this.status,
    required this.latLng,
  });
}

// === MODEL PUSKESMAS ===
class PuskesmasLocation {
  final int no;
  final String name;
  final String address;
  final LatLng latLng;

  PuskesmasLocation({
    required this.no,
    required this.name,
    required this.address,
    required this.latLng,
  });
}

class MapService {
  final Distance _distance = const Distance();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === DATA PUSKESMAS KABUPATEN MADIUN (Static) ===
  static final List<PuskesmasLocation> _puskesmasList = [
    PuskesmasLocation(
        no: 1,
        name: 'Puskesmas Gantrung',
        address: 'Jl. Dipenegoro No.311, Ds. Mojorejo, Kebonsari',
        latLng: LatLng(-7.74358, 111.48732)),
    PuskesmasLocation(
        no: 2,
        name: 'Puskesmas Kebonsari',
        address: 'Jl. Husni Thamrin, Ds. Balecejo, Kebonsari',
        latLng: LatLng(-7.74285, 111.48743)),
    PuskesmasLocation(
        no: 3,
        name: 'Puskesmas Geger',
        address: 'Jl. Raya Ponorogo No.48, Geger',
        latLng: LatLng(-7.65132, 111.53290)),
    PuskesmasLocation(
        no: 4,
        name: 'Puskesmas Kalibon',
        address: 'Jl. Poncotaruno No.407, Kalibon',
        latLng: LatLng(-7.65018, 111.53481)),
    PuskesmasLocation(
        no: 5,
        name: 'Puskesmas Mlilir',
        address: 'Jl. Raya Madiun-Ponorogo km.19, Mlilir',
        latLng: LatLng(-7.73231, 111.49327)),
    PuskesmasLocation(
        no: 6,
        name: 'Puskesmas Bungonsari',
        address: 'Jl. Panjang Bungung, Bangunsari',
        latLng: LatLng(-7.73729, 111.50115)),
    PuskesmasLocation(
        no: 7,
        name: 'Puskesmas Dagangan',
        address: 'Jl. Raya Pagetan-Dagangan No.57',
        latLng: LatLng(-7.57102, 111.51324)),
    PuskesmasLocation(
        no: 8,
        name: 'Puskesmas Jetis',
        address: 'Jl. Jetis, Jetis',
        latLng: LatLng(-7.56556, 111.51132)),
    PuskesmasLocation(
        no: 9,
        name: 'Puskesmas Wungu',
        address: 'Jl. Raya Kare No.113, Wungu',
        latLng: LatLng(-7.69187, 111.54809)),
    PuskesmasLocation(
        no: 10,
        name: 'Puskesmas Doloyowono',
        address: 'Jl. Raya Dungus, Doloyowono',
        latLng: LatLng(-7.69101, 111.54725)),
    PuskesmasLocation(
        no: 11,
        name: 'Puskesmas Kare',
        address: 'Jl. Raya Randualas, Kare',
        latLng: LatLng(-7.69320, 111.55340)),
    PuskesmasLocation(
        no: 12,
        name: 'Puskesmas Gemarang',
        address: 'Jl. TGP No.17, Gemarang',
        latLng: LatLng(-7.63317, 111.50239)),
    PuskesmasLocation(
        no: 13,
        name: 'Puskesmas Saradan',
        address: 'Jl. Raya Saradan, Sugiwaras',
        latLng: LatLng(-7.56698, 111.53625)),
    PuskesmasLocation(
        no: 14,
        name: 'Puskesmas Sumbersari',
        address: 'Jl. Raya Tulung No.05, Sumbersari',
        latLng: LatLng(-7.54419, 111.52960)),
    PuskesmasLocation(
        no: 15,
        name: 'Puskesmas Pilangkenceng',
        address: 'Jl. Raya Kenongorejo No.774, Pilangkenceng',
        latLng: LatLng(-7.50222, 111.57635)),
    PuskesmasLocation(
        no: 16,
        name: 'Puskesmas Krebet',
        address: 'Jl. Gawang Utara, Krebet',
        latLng: LatLng(-7.52863, 111.58977)),
    PuskesmasLocation(
        no: 17,
        name: 'Puskesmas Klecorejo',
        address: 'Jl. Raya Wates, Klecorejo',
        latLng: LatLng(-7.62660, 111.59812)),
    PuskesmasLocation(
        no: 18,
        name: 'Puskesmas Mejayan',
        address: 'Jl. Panglima Sudirman No.52, Mejayan',
        latLng: LatLng(-7.58306, 111.68194)),
    PuskesmasLocation(
        no: 19,
        name: 'Puskesmas Monosari',
        address: 'Jl. Raya Monosari, Monosari',
        latLng: LatLng(-7.60788, 111.53832)),
    PuskesmasLocation(
        no: 20,
        name: 'Puskesmas Balecejo',
        address: 'Jl. Raya Madiun-Surabaya No.82, Balecejo',
        latLng: LatLng(-7.74375, 111.48595)),
    PuskesmasLocation(
        no: 21,
        name: 'Puskesmas Simo',
        address: 'Jl. Raya Balecejo-Ouweng No.96, Simo',
        latLng: LatLng(-7.75415, 111.48718)),
    PuskesmasLocation(
        no: 22,
        name: 'Puskesmas Madiun',
        address: 'Jl. Raya Puskesmas No.9, Tiron',
        latLng: LatLng(-7.62671, 111.51196)),
    PuskesmasLocation(
        no: 23,
        name: 'Puskesmas Dimong',
        address: 'Jl. Raya Dimong, Dimong',
        latLng: LatLng(-7.62912, 111.53948)),
    PuskesmasLocation(
        no: 24,
        name: 'Puskesmas Sawahan',
        address: 'Jl. Raya Kajang No.31, Sawahan',
        latLng: LatLng(-7.78231, 111.46858)),
    PuskesmasLocation(
        no: 25,
        name: 'Puskesmas Klagenserut',
        address: 'Jl. Raya Klagenserut, Jiwan',
        latLng: LatLng(-7.73499, 111.44911)),
    PuskesmasLocation(
        no: 26,
        name: 'Puskesmas Jiwan',
        address: 'Jl. Raya Solo No.85, Jiwan',
        latLng: LatLng(-7.73358, 111.44962)),
    PuskesmasLocation(
        no: 27,
        name: 'RSUD Caruban',
        address: 'Jl. Ahmad Yani Km.2, Mejayan',
        latLng: LatLng(-7.53929, 111.65579)),
    PuskesmasLocation(
        no: 28,
        name: 'RSUD Dolopo',
        address: 'Jl. Raya Dolopo No.117, Dolopo',
        latLng: LatLng(-7.76523, 111.52696)),
    PuskesmasLocation(
        no: 29,
        name: 'PSC 119 Kabupaten Madiun',
        address: ' Jl. Raya Madiun - Surabaya, Nglames, Kec. Madiun, Kabupaten Madiun, Jawa Timur',
        latLng: LatLng(-7.63105876, 111.5300159)),
  ];

  // === GET LOKASI USER SAAT INI ===
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // === STREAM LOKASI REAL-TIME ===
  Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  // === GET AMBULANCE DARI FIRESTORE (Real-time) ===
  Stream<List<AmbulanceLocation>> getAmbulancesLocation() {
    return _firestore
        .collection('ambulances')
        .where('status', isEqualTo: 'Tersedia')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Cek apakah ada koordinat GPS real dari petugas
        double lat = data['latitude'] ?? -7.6298;
        double lng = data['longitude'] ?? 111.5239;
        
        // Jika belum ada koordinat real, gunakan offset random untuk simulasi
        if (data['latitude'] == null || data['longitude'] == null) {
          lat = -7.6298 + (doc.id.hashCode % 100 - 50) / 5000;
          lng = 111.5239 + (doc.id.hashCode % 100 - 50) / 5000;
        }
        
        return AmbulanceLocation(
          id: doc.id,
          plate: data['plate'] ?? 'N/A',
          petugasName: data['petugasName'],
          status: data['status'] ?? 'Tersedia',
          latLng: LatLng(lat, lng),
        );
      }).toList();
    });
  }

  // === GET PUSKESMAS LIST ===
  List<PuskesmasLocation> getPuskesmasList() {
    return _puskesmasList;
  }

  // === CALCULATE DISTANCE ===
  double calculateDistance(LatLng from, LatLng to) {
    return _distance.as(LengthUnit.Meter, from, to);
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String estimateTime(double meters) {
    final minutes = (meters / 1000 * 3).round();
    if (minutes < 60) {
      return '$minutes menit';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours jam $remainingMinutes menit';
    }
  }

  // === UPDATE LOKASI AMBULANCE (untuk Petugas) ===
  Future<bool> updateAmbulanceLocation(String ambulanceId, LatLng location) async {
    try {
      await _firestore.collection('ambulances').doc(ambulanceId).update({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'lastUpdated': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error update ambulance location: $e');
      return false;
    }
  }
}