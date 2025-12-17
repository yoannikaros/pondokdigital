import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanLimitScreen extends StatefulWidget {
  const PengaturanLimitScreen({super.key});

  @override
  State<PengaturanLimitScreen> createState() => _PengaturanLimitScreenState();
}

class _PengaturanLimitScreenState extends State<PengaturanLimitScreen> {
  final TextEditingController _limitTransaksiController = TextEditingController();
  final TextEditingController _limitSaldoMinController = TextEditingController();
  final TextEditingController _limitSaldoMaxController = TextEditingController();
  final TextEditingController _limitHarianController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;

  // Default values
  static const double _defaultLimitTransaksi = 50000.0;
  static const double _defaultLimitSaldoMin = 0.0;
  static const double _defaultLimitSaldoMax = 500000.0;
  static const double _defaultLimitHarian = 100000.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _limitTransaksiController.dispose();
    _limitSaldoMinController.dispose();
    _limitSaldoMaxController.dispose();
    _limitHarianController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final limitTransaksi = prefs.getDouble('limit_transaksi') ?? _defaultLimitTransaksi;
      final limitSaldoMin = prefs.getDouble('limit_saldo_min') ?? _defaultLimitSaldoMin;
      final limitSaldoMax = prefs.getDouble('limit_saldo_max') ?? _defaultLimitSaldoMax;
      final limitHarian = prefs.getDouble('limit_harian') ?? _defaultLimitHarian;
      
      _limitTransaksiController.text = limitTransaksi.toStringAsFixed(0);
      _limitSaldoMinController.text = limitSaldoMin.toStringAsFixed(0);
      _limitSaldoMaxController.text = limitSaldoMax.toStringAsFixed(0);
      _limitHarianController.text = limitHarian.toStringAsFixed(0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
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

  Future<void> _saveSettings() async {
    if (!_validateInputs()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final limitTransaksi = double.parse(_limitTransaksiController.text);
      final limitSaldoMin = double.parse(_limitSaldoMinController.text);
      final limitSaldoMax = double.parse(_limitSaldoMaxController.text);
      final limitHarian = double.parse(_limitHarianController.text);
      
      await prefs.setDouble('limit_transaksi', limitTransaksi);
      await prefs.setDouble('limit_saldo_min', limitSaldoMin);
      await prefs.setDouble('limit_saldo_max', limitSaldoMax);
      await prefs.setDouble('limit_harian', limitHarian);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan limit berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  bool _validateInputs() {
    final limitTransaksi = double.tryParse(_limitTransaksiController.text);
    final limitSaldoMin = double.tryParse(_limitSaldoMinController.text);
    final limitSaldoMax = double.tryParse(_limitSaldoMaxController.text);
    final limitHarian = double.tryParse(_limitHarianController.text);

    if (limitTransaksi == null || limitTransaksi < 0) {
      _showErrorSnackBar('Limit transaksi harus berupa angka positif');
      return false;
    }

    if (limitSaldoMin == null || limitSaldoMin < 0) {
      _showErrorSnackBar('Limit saldo minimum harus berupa angka positif');
      return false;
    }

    if (limitSaldoMax == null || limitSaldoMax < 0) {
      _showErrorSnackBar('Limit saldo maksimum harus berupa angka positif');
      return false;
    }

    if (limitHarian == null || limitHarian < 0) {
      _showErrorSnackBar('Limit harian harus berupa angka positif');
      return false;
    }

    if (limitSaldoMin >= limitSaldoMax) {
      _showErrorSnackBar('Limit saldo minimum harus lebih kecil dari maksimum');
      return false;
    }

    if (limitTransaksi > limitHarian) {
      _showErrorSnackBar('Limit transaksi tidak boleh lebih besar dari limit harian');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset ke Default'),
        content: const Text(
          'Apakah Anda yakin ingin mereset semua pengaturan limit ke nilai default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _limitTransaksiController.text = _defaultLimitTransaksi.toStringAsFixed(0);
      _limitSaldoMinController.text = _defaultLimitSaldoMin.toStringAsFixed(0);
      _limitSaldoMaxController.text = _defaultLimitSaldoMax.toStringAsFixed(0);
      _limitHarianController.text = _defaultLimitHarian.toStringAsFixed(0);
      
      await _saveSettings();
    }
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return 'Rp 0';
    final number = double.tryParse(value) ?? 0;
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pengaturan Limit',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadSettings,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
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
                                    'Pengaturan Limit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Atur batas transaksi dan saldo santri',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Limit Settings
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_rounded,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Pengaturan Limit Transaksi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Limit Transaksi Per Item
                        TextField(
                          controller: _limitTransaksiController,
                          decoration: InputDecoration(
                            labelText: 'Limit Transaksi Per Item',
                            hintText: 'Masukkan limit transaksi',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.shopping_cart_outlined),
                            suffixText: 'Rupiah',
                            helperText: _formatCurrency(_limitTransaksiController.text),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        
                        // Limit Harian
                        TextField(
                          controller: _limitHarianController,
                          decoration: InputDecoration(
                            labelText: 'Limit Transaksi Harian',
                            hintText: 'Masukkan limit harian',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.today_outlined),
                            suffixText: 'Rupiah',
                            helperText: _formatCurrency(_limitHarianController.text),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        
                        // Limit Saldo Minimum
                        TextField(
                          controller: _limitSaldoMinController,
                          decoration: InputDecoration(
                            labelText: 'Limit Saldo Minimum',
                            hintText: 'Masukkan saldo minimum',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                            suffixText: 'Rupiah',
                            helperText: _formatCurrency(_limitSaldoMinController.text),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        
                        // Limit Saldo Maximum
                        TextField(
                          controller: _limitSaldoMaxController,
                          decoration: InputDecoration(
                            labelText: 'Limit Saldo Maksimum',
                            hintText: 'Masukkan saldo maksimum',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.savings_outlined),
                            suffixText: 'Rupiah',
                            helperText: _formatCurrency(_limitSaldoMaxController.text),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Pengaturan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Limit Transaksi: Batas maksimal per item yang dapat dibeli\n'
                          '• Limit Harian: Batas maksimal transaksi per hari\n'
                          '• Saldo Minimum: Saldo terendah yang harus dimiliki santri\n'
                          '• Saldo Maksimum: Saldo tertinggi yang dapat dimiliki santri',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetToDefault,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'Reset Default',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
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
                              : const Text(
                                  'Simpan Pengaturan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}