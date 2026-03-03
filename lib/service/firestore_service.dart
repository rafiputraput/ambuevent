// lib/service/firestore_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================
  // USER CRUD
  // ============================

  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error update user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      print('Error delete user: $e');
      return false;
    }
  }

  // ============================
  // ARMADA CRUD
  // ============================

  Stream<List<Map<String, dynamic>>> getAmbulances() {
    return _firestore.collection('ambulances').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<bool> addAmbulance(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ambulances').add({
        ...data,
        'createdAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error add ambulance: $e');
      return false;
    }
  }

  Future<bool> updateAmbulance(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ambulances').doc(id).update(data);
      return true;
    } catch (e) {
      print('Error update ambulance: $e');
      return false;
    }
  }

  Future<bool> deleteAmbulance(String id) async {
    try {
      await _firestore.collection('ambulances').doc(id).delete();
      return true;
    } catch (e) {
      print('Error delete ambulance: $e');
      return false;
    }
  }

  // ============================
  // BOOKING CRUD
  // ============================

  /// Tambah booking baru ke Firestore
  Future<String?> addBooking({
    required String userId,
    required String userName,
    required String eventName,
    required String date,
    required String location,
    required String type,
    List<String> documentNames = const [],
  }) async {
    try {
      final ref = await _firestore.collection('bookings').add({
        'userId': userId,
        'userName': userName,
        'eventName': eventName,
        'date': date,
        'location': location,
        'type': type,
        'status': 'Menunggu Konfirmasi',
        'documents': documentNames,
        'petugasId': null,
        'petugasName': null,
        'ambulanceId': null,
        'ambulancePlate': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      print('Error add booking: $e');
      return null;
    }
  }

  /// Stream semua booking (untuk admin)
  Stream<List<Map<String, dynamic>>> getBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Stream booking milik user tertentu
  Stream<List<Map<String, dynamic>>> getBookingsByUser(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Stream booking yang ditugaskan ke petugas tertentu
  Stream<List<Map<String, dynamic>>> getBookingsByPetugas(
      String petugasId) {
    return _firestore
        .collection('bookings')
        .where('petugasId', isEqualTo: petugasId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<bool> updateBookingStatus(String docId, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(docId)
          .update({'status': status});
      return true;
    } catch (e) {
      print('Error update booking status: $e');
      return false;
    }
  }
}