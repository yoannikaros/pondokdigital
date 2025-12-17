import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/karyawan.dart';
import 'karyawan_form_screen.dart';

class KaryawanListScreen extends StatefulWidget {
  const KaryawanListScreen({Key? key}) : super(key: key);

  @override
  State<KaryawanListScreen> createState() => _KaryawanListScreenState();
}

class _KaryawanListScreenState extends State<KaryawanListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Karyawan> _karyawanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKaryawan();
  }

  Future<void> _loadKaryawan() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final karyawan = await _databaseHelper.getAllKaryawan();
      setState(() {
        _karyawanList = karyawan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading karyawan: $e')),
      );
    }
  }

  Future<void> _deleteKaryawan(int id) async {
    try {
      await _databaseHelper.deleteKaryawan(id);
      _loadKaryawan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting karyawan: $e')),
      );
    }
  }

  void _showDeleteConfirmation(Karyawan karyawan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus karyawan ${karyawan.nama}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteKaryawan(karyawan.id!);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _karyawanList.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada data karyawan',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _karyawanList.length,
                  itemBuilder: (context, index) {
                    final karyawan = _karyawanList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: karyawan.isActive ? Colors.green : Colors.red,
                          child: Text(
                            karyawan.nama.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          karyawan.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${karyawan.idPengguna}'),
                            Text('Level: ${karyawan.levelAkses}'),
                            Text('Shift: ${karyawan.shift}'),
                            Text(
                              'Status: ${karyawan.isActive ? "Aktif" : "Nonaktif"}',
                              style: TextStyle(
                                color: karyawan.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KaryawanFormScreen(
                                    karyawan: karyawan,
                                  ),
                                ),
                              ).then((_) => _loadKaryawan());
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(karyawan);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Hapus', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KaryawanFormScreen(),
            ),
          ).then((_) => _loadKaryawan());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}