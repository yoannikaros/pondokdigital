import 'package:flutter/material.dart';
import '../../helpers/nfc_helper.dart';
import '../../helpers/database_helper.dart';
import '../../models/santri.dart';
import '../../models/transaksi.dart';
import 'topup_screen.dart';
import 'penarikan_screen.dart';
import '../barang/barcode_scanner_screen.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  bool _isScanning = false;
  Santri? _selectedSantri;
  String _scanMethod = ''; // 'nfc' or 'barcode'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaksi Santri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kelola saldo dan transaksi santri',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Scan Options Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Status Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isScanning 
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : _selectedSantri != null
                                ? [Colors.blue[400]!, Colors.blue[600]!]
                                : [Colors.grey[300]!, Colors.grey[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isScanning ? Colors.green : _selectedSantri != null ? Colors.blue : Colors.grey).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedSantri != null 
                          ? Icons.check_circle_rounded 
                          : _isScanning
                              ? Icons.hourglass_empty_rounded
                              : Icons.person_search_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Status Text
                  Text(
                    _selectedSantri != null
                        ? 'Santri Terdeteksi'
                        : _isScanning
                            ? 'Sedang Memindai...'
                            : 'Pilih Metode Scan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Student Info
                  if (_selectedSantri != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 20,
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
                                          child: Text(
                                            _selectedSantri!.nama,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _scanMethod == 'nfc' 
                                                ? Colors.blue[100] 
                                                : Colors.purple[100],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _scanMethod == 'nfc' 
                                                  ? Colors.blue[300]! 
                                                  : Colors.purple[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _scanMethod == 'nfc' 
                                                    ? Icons.nfc_rounded 
                                                    : Icons.qr_code_rounded,
                                                size: 12,
                                                color: _scanMethod == 'nfc' 
                                                    ? Colors.blue[700] 
                                                    : Colors.purple[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _scanMethod == 'nfc' ? 'NFC' : 'NIS',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: _scanMethod == 'nfc' 
                                                      ? Colors.blue[700] 
                                                      : Colors.purple[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 16,
                                          color: Colors.green[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saldo: Rp ${_formatCurrency(_selectedSantri!.saldo)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'NIS: ${_selectedSantri!.nis}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Scan Buttons
                  if (_selectedSantri == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isScanning 
                                    ? [Colors.grey[400]!, Colors.grey[600]!]
                                    : [Colors.blue[400]!, Colors.blue[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isScanning ? Colors.grey : Colors.blue).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _scanCard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                _isScanning ? Icons.hourglass_empty_rounded : Icons.nfc_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isScanning ? 'Memindai...' : 'Scan NFC',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isScanning 
                                    ? [Colors.grey[400]!, Colors.grey[600]!]
                                    : [Colors.purple[400]!, Colors.purple[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isScanning ? Colors.grey : Colors.purple).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _scanBarcode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                _isScanning ? Icons.hourglass_empty_rounded : Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isScanning ? 'Memindai...' : 'Scan NIS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[                    // Reset button when santri is selected
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange[400]!, Colors.orange[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _resetSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Scan Ulang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[400]!, Colors.grey[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _clearNFCCache,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.clear_all_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Transaction Menu
            if (_selectedSantri != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple[400]!, Colors.purple[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pilih Jenis Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Transaction Buttons Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTransactionButton(
                            'Top Up',
                            Icons.add_circle_rounded,
                            [Colors.green[400]!, Colors.green[600]!],
                            () => _navigateToTopUp(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTransactionButton(
                            'Penarikan',
                            Icons.remove_circle_rounded,
                            [Colors.red[400]!, Colors.red[600]!],
                            () => _navigateToPenarikan(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTransactionButton(
                            'Riwayat',
                            Icons.history_rounded,
                            [Colors.orange[400]!, Colors.orange[600]!],
                            () => _showRiwayat(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()), // Empty space
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionButton(
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanCard() async {
    setState(() {
      _isScanning = true;
      _selectedSantri = null;
    });

    try {
      // Cek status NFC secara real-time
      final isNFCAvailable = await NFCHelper.instance.checkNFCStatus();
      
      if (!isNFCAvailable) {
        throw Exception('NFC tidak tersedia atau tidak aktif di perangkat ini.\n\nPastikan:\n1. Perangkat memiliki fitur NFC\n2. NFC sudah diaktifkan di pengaturan\n3. Tidak ada aplikasi lain yang menggunakan NFC');
      }

      final cardId = await NFCHelper.instance.scanCard(
        title: 'Scan Kartu',
        instruction: 'Tempelkan kartu NFC ke perangkat',
      );

      if (cardId != null) {
        final santri = await DatabaseHelper.instance.getSantriByKartu(cardId);
        
        setState(() {
          _selectedSantri = santri;
          _scanMethod = 'nfc';
        });

        if (santri == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kartu tidak terdaftar'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kartu berhasil discan: ${santri.nama}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error scanning: $e';
        
        // Berikan pesan yang lebih spesifik untuk kartu Flazz Gen 2
        if (e.toString().toLowerCase().contains('flazz') || 
            e.toString().toLowerCase().contains('gagal mengekstrak')) {
          errorMessage = 'Kartu Flazz Gen 2 terdeteksi tetapi gagal dibaca.\n\n'
                        'Tips:\n'
                        '• Pastikan kartu menempel erat ke perangkat\n'
                        '• Tahan kartu selama 2-3 detik\n'
                        '• Coba posisi kartu yang berbeda\n'
                        '• Pastikan tidak ada kartu lain di dekatnya';
        } else if (e.toString().toLowerCase().contains('nfc tidak tersedia') ||
                   e.toString().toLowerCase().contains('nfc tidak aktif')) {
          errorMessage = 'NFC tidak aktif atau tidak tersedia.\n\n'
                        'Pastikan:\n'
                        '• NFC sudah diaktifkan di pengaturan\n'
                        '• Perangkat mendukung NFC\n'
                        '• Tidak ada aplikasi lain yang menggunakan NFC';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () {
                _scanCard();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isScanning = true;
      _selectedSantri = null;
    });

    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );

      if (result != null && result.isNotEmpty) {
        final santri = await DatabaseHelper.instance.getSantriByNis(result);
        
        setState(() {
           _selectedSantri = santri;
           _scanMethod = 'barcode';
         });

        if (santri == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Santri dengan NIS "$result" tidak ditemukan'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('NIS berhasil discan: ${santri.nama}'),
                backgroundColor: Colors.green,
              ),
            );
          }
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
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedSantri = null;
      _isScanning = false;
      _scanMethod = '';
    });
  }

  void _navigateToTopUp() {
    _validatePinAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TopUpScreen(santri: _selectedSantri!),
        ),
      ).then((_) => _refreshSantriData());
    });
  }

  void _navigateToPenarikan() {
    _validatePinAndNavigate(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PenarikanScreen(santri: _selectedSantri!),
        ),
      ).then((_) => _refreshSantriData());
    });
  }

  void _validatePinAndNavigate(VoidCallback onSuccess) {
    if (_selectedSantri?.pin == null || _selectedSantri!.pin!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN belum diatur untuk santri ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showPinDialog(onSuccess);
  }

  void _showPinDialog(VoidCallback onSuccess) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan PIN untuk ${_selectedSantri!.nama}'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == _selectedSantri!.pin) {
                Navigator.pop(context);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN salah'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSantriData() async {
    if (_selectedSantri != null) {
      final updatedSantri = await DatabaseHelper.instance
          .getSantriByKartu(_selectedSantri!.nomorKartu);
      setState(() {
        _selectedSantri = updatedSantri;
      });
    }
  }

  void _showRiwayat() async {
    final transaksiList = await DatabaseHelper.instance
        .getTransaksiByKartu(_selectedSantri!.nomorKartu);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Riwayat ${_selectedSantri!.nama}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: transaksiList.length,
              itemBuilder: (context, index) {
                final transaksi = transaksiList[index];
                return ListTile(
                  leading: Icon(_getTransactionIcon(transaksi.jenis)),
                  title: Text(_getTransactionTitle(transaksi.jenis)),
                  subtitle: Text(
                    '${_formatDate(transaksi.createdAt)} - ${transaksi.kasir}',
                  ),
                  trailing: Text(
                    'Rp ${_formatCurrency(transaksi.nominal)}',
                    style: TextStyle(
                      color: _getTransactionColor(transaksi.jenis),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  IconData _getTransactionIcon(JenisTransaksi jenis) {
    switch (jenis) {
      case JenisTransaksi.topup:
        return Icons.add_circle;
      case JenisTransaksi.penarikan:
        return Icons.remove_circle;
      case JenisTransaksi.belanja:
        return Icons.shopping_cart;
      case JenisTransaksi.penarikanMasal:
        return Icons.group_remove;
    }
  }

  String _getTransactionTitle(JenisTransaksi jenis) {
    switch (jenis) {
      case JenisTransaksi.topup:
        return 'Top Up';
      case JenisTransaksi.penarikan:
        return 'Penarikan';
      case JenisTransaksi.belanja:
        return 'Belanja';
      case JenisTransaksi.penarikanMasal:
        return 'Penarikan Masal';
    }
  }

  Color _getTransactionColor(JenisTransaksi jenis) {
    switch (jenis) {
      case JenisTransaksi.topup:
        return Colors.green;
      case JenisTransaksi.penarikan:
      case JenisTransaksi.penarikanMasal:
        return Colors.red;
      case JenisTransaksi.belanja:
        return Colors.blue;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _clearNFCCache() async {
     try {
       NFCHelper.instance.clearCardCache();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Cache NFC berhasil dibersihkan'),
             backgroundColor: Colors.green,
             duration: Duration(seconds: 2),
           ),
         );
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error clearing NFC cache: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }
}
