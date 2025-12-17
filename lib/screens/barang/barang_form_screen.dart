import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/database_helper.dart';
import '../../models/barang.dart';
import '../../models/supplier.dart';
import '../supplier/supplier_list_screen.dart';
import 'barcode_scanner_screen.dart';

class BarangFormScreen extends StatefulWidget {
  final Barang? barang;
  final String? initialBarcode;

  const BarangFormScreen({super.key, this.barang, this.initialBarcode});

  @override
  State<BarangFormScreen> createState() => _BarangFormScreenState();
}

class _BarangFormScreenState extends State<BarangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _satuanController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hargaBeliController = TextEditingController();

  List<Supplier> _supplierList = [];
  Supplier? _selectedSupplier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    if (widget.barang != null) {
      _populateForm();
    } else if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await DatabaseHelper.instance.getAllSupplier();
      setState(() {
        _supplierList = suppliers;
        if (widget.barang?.supplierId != null) {
          _selectedSupplier = suppliers.firstWhere(
            (s) => s.id == widget.barang!.supplierId,
            orElse: () => suppliers.first,
          );
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void _populateForm() {
    final barang = widget.barang!;
    _namaController.text = barang.nama;
    _hargaController.text = barang.harga.toStringAsFixed(0);
    _stokController.text = barang.stok.toString();
    _satuanController.text = barang.satuan;
    _barcodeController.text = barang.barcode ?? '';
    _hargaBeliController.text = barang.hargaBeli?.toStringAsFixed(0) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.barang == null ? 'Tambah Barang' : 'Edit Barang',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.inventory,
                          size: 40,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.barang == null
                            ? 'Tambah Barang Baru'
                            : 'Edit Data Barang',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lengkapi informasi barang di bawah ini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Dasar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Barang *',
                          hintText: 'Masukkan nama barang',
                          prefixIcon: const Icon(Icons.inventory),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama barang tidak boleh kosong';
                          }
                          if (value.trim().length < 2) {
                            return 'Nama barang minimal 2 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _satuanController,
                              decoration: InputDecoration(
                                labelText: 'Satuan *',
                                hintText: 'pcs, kg, liter',
                                prefixIcon: const Icon(Icons.straighten),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Satuan tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stokController,
                              decoration: InputDecoration(
                                labelText: 'Stok Awal *',
                                hintText: '0',
                                prefixIcon: const Icon(Icons.inventory_2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Stok tidak boleh kosong';
                                }
                                final stok = int.tryParse(value);
                                if (stok == null || stok < 0) {
                                  return 'Stok harus berupa angka positif';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pricing Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Harga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _hargaBeliController,
                        decoration: InputDecoration(
                          labelText: 'Harga Beli',
                          hintText: '0',
                          prefixText: 'Rp ',
                          prefixIcon: const Icon(Icons.shopping_cart),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _hargaController,
                        decoration: InputDecoration(
                          labelText: 'Harga Jual *',
                          hintText: '0',
                          prefixText: 'Rp ',
                          prefixIcon: const Icon(Icons.sell),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga jual tidak boleh kosong';
                          }
                          final harga = double.tryParse(value);
                          if (harga == null || harga <= 0) {
                            return 'Harga harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Barcode & Supplier Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Tambahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Barcode',
                          hintText: 'Scan atau masukkan barcode',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: _scanBarcode,
                                tooltip: 'Scan Barcode',
                              ),
                              IconButton(
                                icon: const Icon(Icons.auto_awesome),
                                onPressed: _generateBarcode,
                                tooltip: 'Generate Barcode',
                              ),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.trim().isEmpty) {
                            return 'Barcode tidak boleh hanya berisi spasi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Supplier>(
                        value: _selectedSupplier,
                        decoration: InputDecoration(
                          labelText: 'Supplier',
                          hintText: 'Pilih supplier',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _refreshSuppliers,
                                tooltip: 'Refresh Data Supplier',
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _navigateToSupplierList,
                                tooltip: 'Kelola Supplier',
                              ),
                            ],
                          ),
                        ),
                        items: _supplierList.map((supplier) {
                          return DropdownMenuItem(
                            value: supplier,
                            child: Text(supplier.nama),
                          );
                        }).toList(),
                        onChanged: (supplier) {
                          setState(() {
                            _selectedSupplier = supplier;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // Required field note
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '* Wajib diisi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Menyimpan...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save),
                            const SizedBox(width: 8),
                            Text(
                              widget.barang == null ? 'Tambah Barang' : 'Update Barang',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _barcodeController.text = timestamp.substring(timestamp.length - 8);
    });
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      if (result != null && result is String) {
        setState(() {
          _barcodeController.text = result;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Row(
               children: [
                 const Icon(Icons.error, color: Colors.white),
                 const SizedBox(width: 8),
                 Expanded(child: Text('Error scanning barcode: $e')),
               ],
             ),
             backgroundColor: Colors.red,
             behavior: SnackBarBehavior.floating,
           ),
         );
       }
    }
  }

  Future<void> _refreshSuppliers() async {
    try {
      await _loadSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data supplier berhasil direfresh'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error refresh data supplier: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToSupplierList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupplierListScreen(),
      ),
    );
    
    if (result == true) {
      _loadSuppliers();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi barcode duplikat jika barcode diisi
      final barcodeText = _barcodeController.text.trim();
      if (barcodeText.isNotEmpty) {
        final existingBarang = await DatabaseHelper.instance.getBarangByBarcode(barcodeText);
        if (existingBarang != null && existingBarang.id != widget.barang?.id) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Barcode $barcodeText sudah digunakan oleh barang "${existingBarang.nama}"')),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final barang = Barang(
        id: widget.barang?.id,
        nama: _namaController.text,
        harga: double.parse(_hargaController.text),
        stok: int.parse(_stokController.text),
        satuan: _satuanController.text,
        barcode: barcodeText.isEmpty ? null : barcodeText,
        hargaBeli: _hargaBeliController.text.isEmpty 
            ? null 
            : double.parse(_hargaBeliController.text),
        supplierId: _selectedSupplier?.id,
      );

      if (widget.barang == null) {
        await DatabaseHelper.instance.insertBarang(barang);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Barang berhasil ditambahkan'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.updateBarang(barang);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Data barang berhasil diupdate'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _satuanController.dispose();
    _barcodeController.dispose();
    _hargaBeliController.dispose();
    super.dispose();
  }
}
