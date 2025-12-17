import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/nfc_helper.dart';
import '../../models/santri.dart';
import '../barang/barcode_scanner_screen.dart';

class SantriFormScreen extends StatefulWidget {
  final Santri? santri;
  final String? initialNomorKartu;

  const SantriFormScreen({super.key, this.santri, this.initialNomorKartu});

  @override
  State<SantriFormScreen> createState() => _SantriFormScreenState();
}

class _SantriFormScreenState extends State<SantriFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorKartuController = TextEditingController();
  final _namaController = TextEditingController();
  final _nisController = TextEditingController();
  final _kelasController = TextEditingController();
  final _pinController = TextEditingController();
  final _saldoController = TextEditingController();
  final _limitHarianController = TextEditingController();

  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.santri != null) {
      _populateForm();
    } else {
      _saldoController.text = '0';
      _limitHarianController.text = '50000';
      if (widget.initialNomorKartu != null) {
        _nomorKartuController.text = widget.initialNomorKartu!;
      }
    }
  }

  void _populateForm() {
    final santri = widget.santri!;
    _nomorKartuController.text = santri.nomorKartu;
    _namaController.text = santri.nama;
    _nisController.text = santri.nis;
    _kelasController.text = santri.kelas;
    _pinController.text = santri.pin ?? '';
    _saldoController.text = santri.saldo.toStringAsFixed(0);
    _limitHarianController.text = santri.limitHarian.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.santri == null ? 'Tambah Santri' : 'Edit Santri'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Colors.grey[50],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NFC Card Section
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isScanning ? Colors.green[100] : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 48,
                          color: _isScanning ? Colors.green[700] : Colors.blue[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan Kartu NFC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tempelkan kartu NFC ke perangkat\n\nUntuk kartu Flazz Gen 2:\nTahan kartu selama 2-3 detik',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(_isScanning ? Icons.hourglass_empty : Icons.nfc),
                        label: Text(
                          _isScanning ? 'Scanning...' : 'Scan Kartu RFID',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields
              TextFormField(
                controller: _nomorKartuController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kartu RFID (Flazz Gen 2 Supported)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.credit_card, color: Colors.green),
                  helperText: 'Mendukung kartu Flazz Gen 2 dan kartu RFID lainnya',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor kartu tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Santri',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.person_outline, color: Colors.purple),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nisController,
                      decoration: const InputDecoration(
                        labelText: 'NIS / ID Santri',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIS tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: IconButton(
                      onPressed: _scanBarcode,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.blue,
                        size: 28,
                      ),
                      tooltip: 'Scan Barcode NIS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kelasController,
                decoration: const InputDecoration(
                  labelText: 'Kelas / Kamar / Angkatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.school_outlined, color: Colors.indigo),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kelas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (Wajib - 6 digit)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.orange),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN wajib diisi';
                  }
                  if (value.length != 6) {
                    return 'PIN harus 6 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _saldoController,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Colors.teal),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Saldo tidak boleh kosong';
                  }
                  final saldo = double.tryParse(value);
                  if (saldo == null || saldo < 0) {
                    return 'Saldo harus berupa angka positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _limitHarianController,
                decoration: const InputDecoration(
                  labelText: 'Limit Belanja Harian',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.trending_up_outlined, color: Colors.red),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Limit harian tidak boleh kosong';
                  }
                  final limit = double.tryParse(value);
                  if (limit == null || limit <= 0) {
                    return 'Limit harian harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.santri == null ? 'Tambah Santri' : 'Update Santri',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _nisController.text = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NIS berhasil discan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanCard() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Cek status NFC secara real-time
      final isNFCAvailable = await NFCHelper.instance.checkNFCStatus();
      
      if (!isNFCAvailable) {
        throw Exception('NFC tidak tersedia atau tidak aktif di perangkat ini.\n\nPastikan:\n1. Perangkat memiliki fitur NFC\n2. NFC sudah diaktifkan di pengaturan\n3. Tidak ada aplikasi lain yang menggunakan NFC');
      }

      // Gunakan timeout yang sama dengan NFCScannerScreen yang bekerja
      // dan tambahkan retry mechanism untuk kartu Flazz Gen 2
      String? cardId;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (cardId == null && retryCount < maxRetries) {
        try {
          cardId = await NFCHelper.instance.scanCard(
            title: 'Scan Kartu RFID',
            instruction: retryCount == 0 
                ? 'Tempelkan kartu NFC ke perangkat\n\nUntuk kartu Flazz Gen 2: tahan kartu selama 2-3 detik'
                : 'Coba lagi: tempelkan kartu dengan lebih erat (${retryCount + 1}/$maxRetries)',
            timeout: const Duration(seconds: 30), // Sama dengan NFCScannerScreen
          );
          
          if (cardId != null && cardId.isNotEmpty) {
            break; // Berhasil, keluar dari loop
          }
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // Lempar error jika sudah mencoba maksimal
          }
          
          // Tunggu sebentar sebelum retry
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal scan (percobaan $retryCount/$maxRetries). Mencoba lagi...'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      }

      if (cardId != null && cardId.isNotEmpty) {
        setState(() {
          _nomorKartuController.text = cardId!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(retryCount > 0 
                  ? 'Kartu berhasil discan setelah ${retryCount + 1} percobaan'
                  : 'Kartu berhasil discan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan dibatalkan atau tidak ada kartu terdeteksi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi duplikasi untuk santri baru
      if (widget.santri == null) {
        final isKartuExists = await DatabaseHelper.instance.isNomorKartuExists(_nomorKartuController.text);
        if (isKartuExists) {
          throw Exception('Nomor kartu sudah digunakan');
        }
        
        final isNisExists = await DatabaseHelper.instance.isNisExists(_nisController.text);
        if (isNisExists) {
          throw Exception('NIS sudah digunakan');
        }
      } else {
        // Validasi duplikasi untuk update (kecuali data sendiri)
        final existingSantriByKartu = await DatabaseHelper.instance.getSantriByKartu(_nomorKartuController.text);
        if (existingSantriByKartu != null && existingSantriByKartu.id != widget.santri!.id) {
          throw Exception('Nomor kartu sudah digunakan');
        }
      }

      // Validasi PIN wajib
      if (_pinController.text.isEmpty || _pinController.text.length != 6) {
        throw Exception('PIN wajib diisi dan harus 6 digit');
      }

      final santri = Santri(
        id: widget.santri?.id,
        nomorKartu: _nomorKartuController.text,
        nama: _namaController.text,
        nis: _nisController.text,
        kelas: _kelasController.text,
        pin: _pinController.text,
        saldo: double.parse(_saldoController.text),
        limitHarian: double.parse(_limitHarianController.text),
      );

      if (widget.santri == null) {
        await DatabaseHelper.instance.insertSantri(santri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Santri berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.updateSantri(santri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data santri berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomorKartuController.dispose();
    _namaController.dispose();
    _nisController.dispose();
    _kelasController.dispose();
    _pinController.dispose();
    _saldoController.dispose();
    _limitHarianController.dispose();
    super.dispose();
  }
}
