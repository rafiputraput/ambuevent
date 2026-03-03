// lib/screens/admin_screens.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../service/firestore_service.dart';

// =====================================================================
// CRUD USER
// =====================================================================
class AdminUserScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminUserScreen({super.key, required this.onBack});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah User Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Min. 6 karakter',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                      labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'user', child: Text('User (Pelanggan)')),
                    DropdownMenuItem(
                        value: 'petugas',
                        child: Text('Petugas Ambulance')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedRole = val ?? 'user'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Lengkapi semua field! Password min 6 karakter.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final userCred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                        );
                        if (userCred.user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCred.user!.uid)
                              .set({
                            'uid': userCred.user!.uid,
                            'email': emailController.text.trim(),
                            'name': nameController.text,
                            'photoUrl': '',
                            'role': selectedRole,
                            'createdAt': DateTime.now(),
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User berhasil ditambahkan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: false,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                    labelText: 'Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'user', child: Text('User (Pelanggan)')),
                  DropdownMenuItem(
                      value: 'petugas',
                      child: Text('Petugas Ambulance')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) =>
                    setDialogState(() => selectedRole = val ?? 'user'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final success = await _firestoreService.updateUser(
                    user['uid'],
                    {'name': nameController.text, 'role': selectedRole},
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success
                          ? 'User berhasil diupdate!'
                          : 'Gagal update user'),
                      backgroundColor:
                          success ? Colors.green : Colors.red,
                    ));
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus user "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _firestoreService.deleteUser(uid);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'User berhasil dihapus!'
                      : 'Gagal hapus user'),
                  backgroundColor:
                      success ? Colors.red : Colors.orange,
                ));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada user',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u['role'] == 'admin'
                        ? Colors.red.shade100
                        : (u['role'] == 'petugas'
                            ? Colors.orange.shade100
                            : Colors.blue.shade100),
                    backgroundImage:
                        u['photoUrl'] != null && u['photoUrl'].isNotEmpty
                            ? NetworkImage(u['photoUrl'])
                            : null,
                    child: u['photoUrl'] == null || u['photoUrl'].isEmpty
                        ? Icon(
                            u['role'] == 'admin'
                                ? Icons.shield
                                : (u['role'] == 'petugas'
                                    ? Icons.medical_services
                                    : Icons.person),
                            color: u['role'] == 'admin'
                                ? Colors.red
                                : (u['role'] == 'petugas'
                                    ? Colors.orange
                                    : Colors.blue),
                          )
                        : null,
                  ),
                  title: Text(u['name'] ?? 'No Name',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(u['email'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          (u['role'] ?? 'user').toString().toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                        backgroundColor: u['role'] == 'admin'
                            ? Colors.red
                            : (u['role'] == 'petugas'
                                ? Colors.orange
                                : Colors.blue),
                      ),
                      IconButton(
                        onPressed: () => _showEditUserDialog(u),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () =>
                            _confirmDelete(u['uid'], u['name'] ?? 'User'),
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                      ),
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

// =====================================================================
// CRUD ARMADA
// =====================================================================
class AdminAmbulanceScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminAmbulanceScreen({super.key, required this.onBack});

  @override
  State<AdminAmbulanceScreen> createState() => _AdminAmbulanceScreenState();
}

class _AdminAmbulanceScreenState extends State<AdminAmbulanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddDialog() async {
    final plateController = TextEditingController();
    String selectedStatus = 'Tersedia';
    String? selectedPetugasId;

    final petugasSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'petugas')
        .get();
    final petugasList = petugasSnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc.data()['name'] ?? 'No Name'};
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Armada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                      labelText: 'Nomor Polisi',
                      hintText: 'B 1234 ABC',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPetugasId,
                  decoration: const InputDecoration(
                      labelText: 'Petugas',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('-- Belum Ada Petugas --')),
                    ...petugasList.map((p) => DropdownMenuItem(
                          value: p['id'],
                          child: Text(p['name']!),
                        )),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedPetugasId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'Tersedia', child: Text('Tersedia')),
                    DropdownMenuItem(
                        value: 'Maintenance',
                        child: Text('Maintenance')),
                    DropdownMenuItem(
                        value: 'Booked Event',
                        child: Text('Booked Event')),
                  ],
                  onChanged: (val) => setDialogState(
                      () => selectedStatus = val ?? 'Tersedia'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (plateController.text.isNotEmpty) {
                  final success =
                      await _firestoreService.addAmbulance({
                    'plate': plateController.text,
                    'petugasId': selectedPetugasId,
                    'petugasName': selectedPetugasId != null
                        ? petugasList.firstWhere(
                            (p) => p['id'] == selectedPetugasId)['name']
                        : null,
                    'status': selectedStatus,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success
                          ? 'Armada berhasil ditambahkan!'
                          : 'Gagal tambah armada'),
                      backgroundColor:
                          success ? Colors.green : Colors.red,
                    ));
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> ambulance) async {
    final plateController =
        TextEditingController(text: ambulance['plate']);
    String selectedStatus = ambulance['status'] ?? 'Tersedia';
    String? selectedPetugasId = ambulance['petugasId'];

    final petugasSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'petugas')
        .get();
    final petugasList = petugasSnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc.data()['name'] ?? 'No Name'};
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Armada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                      labelText: 'Nomor Polisi',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPetugasId,
                  decoration: const InputDecoration(
                      labelText: 'Petugas',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('-- Belum Ada Petugas --')),
                    ...petugasList.map((p) => DropdownMenuItem(
                          value: p['id'],
                          child: Text(p['name']!),
                        )),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedPetugasId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'Tersedia', child: Text('Tersedia')),
                    DropdownMenuItem(
                        value: 'Maintenance',
                        child: Text('Maintenance')),
                    DropdownMenuItem(
                        value: 'Booked Event',
                        child: Text('Booked Event')),
                  ],
                  onChanged: (val) => setDialogState(
                      () => selectedStatus = val ?? 'Tersedia'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success =
                    await _firestoreService.updateAmbulance(
                  ambulance['id'],
                  {
                    'plate': plateController.text,
                    'petugasId': selectedPetugasId,
                    'petugasName': selectedPetugasId != null
                        ? petugasList.firstWhere(
                            (p) => p['id'] == selectedPetugasId)['name']
                        : null,
                    'status': selectedStatus,
                  },
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? 'Armada berhasil diupdate!'
                        : 'Gagal update armada'),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ));
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String plate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Armada'),
        content: Text('Yakin ingin menghapus armada "$plate"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await _firestoreService.deleteAmbulance(id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Armada berhasil dihapus!'
                      : 'Gagal hapus armada'),
                  backgroundColor:
                      success ? Colors.red : Colors.orange,
                ));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Armada'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Armada'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getAmbulances(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada armada',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          final ambulances = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ambulances.length,
            itemBuilder: (ctx, i) {
              final a = ambulances[i];
              Color statusColor = a['status'] == 'Tersedia'
                  ? Colors.green
                  : (a['status'] == 'Maintenance'
                      ? Colors.orange
                      : Colors.blue);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(Icons.local_hospital,
                        color: Colors.red),
                  ),
                  title: Text(a['plate'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                              'Petugas: ${a['petugasName'] ?? 'Belum ada'}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          a['status'] ?? 'Tersedia',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditDialog(a),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () =>
                            _confirmDelete(a['id'], a['plate'] ?? ''),
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                      ),
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

// =====================================================================
// ADMIN KEGIATAN — Tab: Kegiatan | Jadwal | Rekap
// =====================================================================
class AdminKegiatanScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminKegiatanScreen({super.key, required this.onBack});

  @override
  State<AdminKegiatanScreen> createState() => _AdminKegiatanScreenState();
}

class _AdminKegiatanScreenState extends State<AdminKegiatanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kegiatan & Penjadwalan'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.event_note, size: 18), text: 'Kegiatan'),
            Tab(
                icon: Icon(Icons.calendar_month, size: 18),
                text: 'Jadwal'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Rekap'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _KegiatanTab(),
          _JadwalTab(),
          _RekapTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Kegiatan ──────────────────────────────────────────────────
class _KegiatanTab extends StatelessWidget {
  const _KegiatanTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(Icons.event_busy, 'Belum ada kegiatan masuk',
              'Booking dari pelanggan akan tampil di sini.');
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _KegiatanCard(docId: docs[i].id, data: data);
          },
        );
      },
    );
  }
}

class _KegiatanCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _KegiatanCard({required this.docId, required this.data});

  Color _statusColor(String? s) {
    switch (s) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _eventIcon(String? type) {
    switch (type) {
      case 'Konser':
        return Icons.music_note;
      case 'Olahraga':
        return Icons.emoji_events;
      case 'Pernikahan':
        return Icons.people_alt;
      case 'Gathering':
        return Icons.work;
      case 'Pengajian':
        return Icons.mosque;
      case 'Pencak Silat':
        return Icons.sports_martial_arts;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Menunggu Konfirmasi';
    final statusColor = _statusColor(status);
    final docs = (data['documents'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_eventIcon(data['type']),
                      color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['eventName'] ?? 'Tanpa Nama',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(data['type'] ?? '-',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _infoRow(Icons.calendar_today, 'Tanggal',
                data['date'] ?? '-'),
            const SizedBox(height: 6),
            _infoRow(Icons.location_on, 'Lokasi',
                data['location'] ?? data['eventLoc'] ?? '-'),
            const SizedBox(height: 6),
            _infoRow(Icons.person, 'Pemohon',
                data['userName'] ?? data['userId'] ?? '-'),
            if (data['petugasName'] != null) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.medical_services, 'Petugas',
                  data['petugasName']),
            ],
            if (docs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: docs.map((url) => _docChip(url)).toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (status == 'Menunggu Konfirmasi')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _updateStatus(context, docId, 'Ditolak'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAssignDialog(context, docId, data),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Setujui & Tugaskan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            if (status == 'Disetujui')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateStatus(context, docId, 'Selesai'),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Tandai Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _docChip(String url) {
    final name = url.split('/').last.split('?').first;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file,
              size: 12, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            name.length > 20 ? '${name.substring(0, 20)}...' : name,
            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': status});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status diubah ke "$status"'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _showAssignDialog(BuildContext context, String docId,
      Map<String, dynamic> data) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'petugas')
        .get();
    final petugasList = snap.docs
        .map((d) => {'id': d.id, 'name': d.data()['name'] ?? '-'})
        .toList();

    final ambSnap = await FirebaseFirestore.instance
        .collection('ambulances')
        .where('status', isEqualTo: 'Tersedia')
        .get();
    final ambList = ambSnap.docs
        .map((d) => {'id': d.id, 'plate': d.data()['plate'] ?? '-'})
        .toList();

    if (!context.mounted) return;

    String? selectedPetugasId;
    String? selectedAmbId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDs) => AlertDialog(
          title: const Text('Setujui & Tugaskan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPetugasId,
                decoration: const InputDecoration(
                    labelText: 'Pilih Petugas',
                    border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('-- Pilih Petugas --')),
                  ...petugasList.map((p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text(p['name']!),
                      )),
                ],
                onChanged: (v) =>
                    setDs(() => selectedPetugasId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAmbId,
                decoration: const InputDecoration(
                    labelText: 'Pilih Armada',
                    border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('-- Pilih Armada --')),
                  ...ambList.map((a) => DropdownMenuItem(
                        value: a['id'],
                        child: Text(a['plate']!),
                      )),
                ],
                onChanged: (v) => setDs(() => selectedAmbId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final petugasName = selectedPetugasId != null
                    ? petugasList.firstWhere(
                        (p) => p['id'] == selectedPetugasId)['name']
                    : null;
                final ambPlate = selectedAmbId != null
                    ? ambList.firstWhere(
                        (a) => a['id'] == selectedAmbId)['plate']
                    : null;

                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(docId)
                    .update({
                  'status': 'Disetujui',
                  'petugasId': selectedPetugasId,
                  'petugasName': petugasName,
                  'ambulanceId': selectedAmbId,
                  'ambulancePlate': ambPlate,
                  'approvedAt': DateTime.now(),
                });

                if (selectedAmbId != null) {
                  await FirebaseFirestore.instance
                      .collection('ambulances')
                      .doc(selectedAmbId)
                      .update({'status': 'Booked Event'});
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content: Text(
                        'Kegiatan disetujui & petugas ditugaskan!'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
              child: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: Jadwal ────────────────────────────────────────────────────
class _JadwalTab extends StatelessWidget {
  const _JadwalTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['Disetujui', 'Selesai'])
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
              Icons.calendar_today,
              'Belum ada jadwal disetujui',
              'Kegiatan yang sudah disetujui akan muncul di sini.');
        }

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] ?? 'Tanggal tidak diketahui';
          grouped.putIfAbsent(date, () => []);
          grouped[date]!.add({...data, 'id': doc.id});
        }
        final sortedDates = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (ctx, i) {
            final date = sortedDates[i];
            return _DateGroup(date: date, events: grouped[date]!);
          },
        );
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> events;
  const _DateGroup({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    String displayDate = date;
    try {
      final parsed = DateTime.parse(date);
      displayDate =
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white, size: 13),
              const SizedBox(width: 6),
              Text(displayDate,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ...events.map((e) => _JadwalItem(data: e)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _JadwalItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _JadwalItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final isSelesai = data['status'] == 'Selesai';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelesai ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSelesai
                ? Colors.grey.shade200
                : Colors.green.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: isSelesai ? Colors.grey : Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(data['eventName'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelesai
                            ? Colors.grey.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(data['status'] ?? '-',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelesai
                                  ? Colors.grey
                                  : Colors.green.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(data['location'] ?? data['eventLoc'] ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.medical_services,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Petugas: ${data['petugasName'] ?? '-'}  •  Armada: ${data['ambulancePlate'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Rekap ─────────────────────────────────────────────────────
class _RekapTab extends StatelessWidget {
  const _RekapTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }

        final docs = snapshot.data?.docs ?? [];
        final int total = docs.length;
        final int menunggu = docs
            .where((d) =>
                (d.data() as Map)['status'] == 'Menunggu Konfirmasi')
            .length;
        final int disetujui = docs
            .where(
                (d) => (d.data() as Map)['status'] == 'Disetujui')
            .length;
        final int selesai = docs
            .where((d) => (d.data() as Map)['status'] == 'Selesai')
            .length;
        final int ditolak = docs
            .where((d) => (d.data() as Map)['status'] == 'Ditolak')
            .length;

        final Map<String, int> typeCount = {};
        final Map<String, int> petugasCount = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? 'Lainnya';
          typeCount[type] = (typeCount[type] ?? 0) + 1;
          if (data['petugasName'] != null &&
              data['petugasName'].toString().isNotEmpty) {
            final name = data['petugasName'].toString();
            petugasCount[name] = (petugasCount[name] ?? 0) + 1;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Ringkasan Kegiatan',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _statCard('Total Booking', total, Colors.blue,
                    Icons.event_note),
                _statCard('Menunggu', menunggu, Colors.orange,
                    Icons.hourglass_empty),
                _statCard('Disetujui', disetujui, Colors.green,
                    Icons.check_circle),
                _statCard(
                    'Selesai', selesai, Colors.teal, Icons.done_all),
                _statCard(
                    'Ditolak', ditolak, Colors.red, Icons.cancel),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Rekap per Tipe Acara',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (typeCount.isEmpty)
              _emptyInline('Belum ada data')
            else
              ...typeCount.entries.map((e) => _barItem(
                  e.key, e.value, total, _typeColor(e.key),
                  _typeIcon(e.key))),
            const SizedBox(height: 24),
            const Text('Rekap Penugasan Petugas',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (petugasCount.isEmpty)
              _emptyInline('Belum ada petugas ditugaskan')
            else
              ...petugasCount.entries
                  .map((e) => _petugasItem(e.key, e.value)),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _statCard(
      String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barItem(String label, int count, int total, Color color,
      IconData icon) {
    final pct = total == 0 ? 0.0 : count / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600))),
              Text('$count kegiatan',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(0)}% dari total',
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _petugasItem(String name, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.red.shade100,
            child: const Icon(Icons.medical_services,
                color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count tugas',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _emptyInline(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
          child:
              Text(msg, style: const TextStyle(color: Colors.grey))),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Konser':       return Colors.purple;
      case 'Olahraga':     return Colors.orange;
      case 'Pernikahan':   return Colors.pink;
      case 'Gathering':    return Colors.blue;
      case 'Pengajian':    return Colors.teal;
      case 'Pencak Silat': return Colors.red;
      default:             return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Konser':       return Icons.music_note;
      case 'Olahraga':     return Icons.emoji_events;
      case 'Pernikahan':   return Icons.people_alt;
      case 'Gathering':    return Icons.work;
      case 'Pengajian':    return Icons.mosque;
      case 'Pencak Silat': return Icons.sports_martial_arts;
      default:             return Icons.event;
    }
  }
}

// =====================================================================
// HELPER — shared empty state
// =====================================================================
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center),
      ],
    ),
  );
}