import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/database_helper.dart';
import '../../models/santri.dart';
import '../../models/transaksi.dart';

class TopUpScreen extends StatefulWidget {
  final Santri santri;

  const TopUpScreen({super.key, required this.santri});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  bool _isLoading = false;

  final List<double> _quickAmounts = [10000, 20000, 50000, 100000, 200000];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Saldo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Santri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.santri.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('NIS: ${widget.santri.nis}'),
                      Text('Kelas: ${widget.santri.kelas}'),
                      const SizedBox(height: 8),
                      Text(
                        'Saldo Saat Ini: Rp ${_formatCurrency(widget.santri.saldo)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Amount Buttons
              const Text(
                'Pilih Nominal Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _quickAmounts.map((amount) {
                  return ElevatedButton(
                    onPressed: () {
                      _nominalController.text = amount.toStringAsFixed(0);
                    },
                    child: Text('Rp ${_formatCurrency(amount)}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Input Nominal
              TextFormField(
                controller: _nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal Top Up',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  final nominal = double.tryParse(value);
                  if (nominal == null || nominal <= 0) {
                    return 'Nominal harus lebih dari 0';
                  }
                  if (nominal > 1000000) {
                    return 'Nominal maksimal Rp 1.000.000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Keterangan
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Proses Top Up',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTopUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nominal = double.parse(_nominalController.text);
      final saldoBaru = widget.santri.saldo + nominal;

      // Update saldo santri
      await DatabaseHelper.instance.updateSaldoSantri(
        widget.santri.nomorKartu,
        saldoBaru,
      );

      // Insert transaksi
      final transaksi = Transaksi(
        nomorKartu: widget.santri.nomorKartu,
        jenis: JenisTransaksi.topup,
        nominal: nominal,
        keterangan: _keteranganController.text.isEmpty 
            ? null 
            : _keteranganController.text,
        kasir: 'Admin', // TODO: Get from current user session
      );

      await DatabaseHelper.instance.insertTransaksi(transaksi);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Top up berhasil! Saldo baru: Rp ${_formatCurrency(saldoBaru)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
}
