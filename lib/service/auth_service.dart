// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List email admin (hardcoded)
  final List<String> _adminEmails = [
    'rafiputraadipratama4@gmail.com',
    'campgreget@gmail.com',
  ];

  // === LOGIN DENGAN EMAIL & PASSWORD ===
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return null;

      // Ambil data user dari Firestore
      return await getUserData(user.uid);
    } catch (e) {
      print('Error login: $e');
      return null;
    }
  }

  // === REGISTER DENGAN EMAIL & PASSWORD ===
  Future<UserModel?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return null;

      // Tentukan role (default user, admin dari list)
      String role = 'user';
      if (_adminEmails.contains(email)) {
        role = 'admin';
      }
      // Role petugas di-set dari admin panel, default tetap 'user'

      // Simpan ke Firestore DULU (saat user masih ter-autentikasi)
      final newUser = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        photoUrl: '',
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // Update display name SETELAH data tersimpan
      await user.updateDisplayName(name);
      await user.reload();

      return newUser;
    } catch (e) {
      print('Error register: $e');
      return null;
    }
  }

  // === LOGIN DENGAN GOOGLE ===
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User membatalkan sign-in

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase
      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) return null;

      // Cek apakah user sudah ada di Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        // User baru, simpan ke Firestore
        final String role = _adminEmails.contains(user.email) ? 'admin' : 'user';
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          photoUrl: user.photoURL ?? '',
          role: role,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      } else {
        // User lama, ambil dari Firestore
        return await getUserData(user.uid);
      }
    } catch (e) {
      print('Error Google Sign-In: $e');
      return null;
    }
  }

  // === GET USER DATA FROM FIRESTORE ===
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error get user data: $e');
      return null;
    }
  }

  // === SIGN OUT ===
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error sign out: $e');
    }
  }

  // === GET CURRENT USER ===
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // === STREAM AUTH STATE ===
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}