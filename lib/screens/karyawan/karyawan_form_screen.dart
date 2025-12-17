import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/karyawan.dart';
import '../barang/barcode_scanner_screen.dart';

class KaryawanFormScreen extends StatefulWidget {
  final Karyawan? karyawan;

  const KaryawanFormScreen({Key? key, this.karyawan}) : super(key: key);

  @override
  State<KaryawanFormScreen> createState() => _KaryawanFormScreenState();
}

class _KaryawanFormScreenState extends State<KaryawanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  final _namaController = TextEditingController();
  final _idPenggunaController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _levelAkses = 'karyawan';
  String _shift = 'pagi';
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _levelAksesList = ['karyawan', 'supervisor', 'manager'];
  final List<String> _shiftList = ['pagi', 'siang', 'malam'];

  @override
  void initState() {
    super.initState();
    if (widget.karyawan != null) {
      _namaController.text = widget.karyawan!.nama;
      _idPenggunaController.text = widget.karyawan!.idPengguna;
      _passwordController.text = widget.karyawan!.password;
      _levelAkses = widget.karyawan!.levelAkses;
      _shift = widget.karyawan!.shift;
      _isActive = widget.karyawan!.isActive;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _idPenggunaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveKaryawan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if ID pengguna already exists (for new karyawan or different ID)
      if (widget.karyawan == null || 
          widget.karyawan!.idPengguna != _idPenggunaController.text) {
        final exists = await _databaseHelper.isIdPenggunaKaryawanExists(_idPenggunaController.text);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Pengguna sudah digunakan')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final now = DateTime.now();
      final karyawan = Karyawan(
        id: widget.karyawan?.id,
        nama: _namaController.text,
        idPengguna: _idPenggunaController.text,
        password: _passwordController.text,
        levelAkses: _levelAkses,
        shift: _shift,
        isActive: _isActive,
        createdAt: widget.karyawan?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.karyawan == null) {
        await _databaseHelper.insertKaryawan(karyawan);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
        );
      } else {
        await _databaseHelper.updateKaryawan(karyawan);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil diupdate')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.karyawan == null ? 'Tambah Karyawan' : 'Edit Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Karyawan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idPenggunaController,
                      decoration: InputDecoration(
                        labelText: 'ID Pengguna',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BarcodeScannerScreen(),
                              ),
                            );
                            if (result != null) {
                              _idPenggunaController.text = result;
                            }
                          },
                          tooltip: 'Scan Barcode',
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ID Pengguna tidak boleh kosong';
                        }
                        if (value.length < 3) {
                          return 'ID Pengguna minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _levelAkses,
                      decoration: const InputDecoration(
                        labelText: 'Level Akses',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: _levelAksesList.map((String level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _levelAkses = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _shift,
                      decoration: const InputDecoration(
                        labelText: 'Shift Kerja',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _shiftList.map((String shift) {
                        return DropdownMenuItem<String>(
                          value: shift,
                          child: Text(shift.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _shift = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      subtitle: Text(_isActive ? 'Karyawan aktif' : 'Karyawan nonaktif'),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveKaryawan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.karyawan == null ? 'Tambah Karyawan' : 'Update Karyawan',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}