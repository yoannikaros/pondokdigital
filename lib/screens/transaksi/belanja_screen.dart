import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/santri.dart';
import '../../models/barang.dart';
import '../../models/transaksi.dart';

class BelanjaScreen extends StatefulWidget {
  final Santri santri;

  const BelanjaScreen({super.key, required this.santri});

  @override
  State<BelanjaScreen> createState() => _BelanjaScreenState();
}

class _BelanjaScreenState extends State<BelanjaScreen> {
  List<Barang> _barangList = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang() async {
    try {
      final barangList = await DatabaseHelper.instance.getAllBarang();
      setState(() {
        _barangList = barangList.where((b) => b.stok > 0).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading barang: $e')),
        );
      }
    }
  }

  double get _totalBelanja {
    return _cartItems.fold(0, (sum, item) => sum + (item.barang.harga * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belanja'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text(_cartItems.length.toString()),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: _showCart,
            ),
        ],
      ),
      body: Column(
        children: [
          // Info Santri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
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
                Text('Saldo: Rp ${_formatCurrency(widget.santri.saldo)}'),
                if (_totalBelanja > 0)
                  Text(
                    'Total Belanja: Rp ${_formatCurrency(_totalBelanja)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
          
          // Daftar Barang
          Expanded(
            child: ListView.builder(
              itemCount: _barangList.length,
              itemBuilder: (context, index) {
                final barang = _barangList[index];
                final cartItem = _cartItems.firstWhere(
                  (item) => item.barang.id == barang.id,
                  orElse: () => CartItem(barang: barang, quantity: 0),
                );
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(barang.nama),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rp ${_formatCurrency(barang.harga)} / ${barang.satuan}'),
                        Text('Stok: ${barang.stok}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: cartItem.quantity > 0 
                              ? () => _updateCart(barang, cartItem.quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          cartItem.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: cartItem.quantity < barang.stok
                              ? () => _updateCart(barang, cartItem.quantity + 1)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Checkout Button
          if (_cartItems.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Checkout - Rp ${_formatCurrency(_totalBelanja)}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateCart(Barang barang, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeWhere((item) => item.barang.id == barang.id);
      } else {
        final existingIndex = _cartItems.indexWhere((item) => item.barang.id == barang.id);
        if (existingIndex >= 0) {
          _cartItems[existingIndex] = CartItem(barang: barang, quantity: quantity);
        } else {
          _cartItems.add(CartItem(barang: barang, quantity: quantity));
        }
      }
    });
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Keranjang Belanja',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._cartItems.map((item) => ListTile(
              title: Text(item.barang.nama),
              subtitle: Text('${item.quantity} x Rp ${_formatCurrency(item.barang.harga)}'),
              trailing: Text(
                'Rp ${_formatCurrency(item.barang.harga * item.quantity)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
            const Divider(),
            ListTile(
              title: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                'Rp ${_formatCurrency(_totalBelanja)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    if (_totalBelanja > widget.santri.saldo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo tidak mencukupi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update saldo santri
      final saldoBaru = widget.santri.saldo - _totalBelanja;
      await DatabaseHelper.instance.updateSaldoSantri(
        widget.santri.nomorKartu,
        saldoBaru,
      );

      // Update stok barang
      for (final item in _cartItems) {
        final stokBaru = item.barang.stok - item.quantity;
        await DatabaseHelper.instance.updateStokBarang(item.barang.id!, stokBaru);
      }

      // Insert transaksi
      final transaksi = Transaksi(
        nomorKartu: widget.santri.nomorKartu,
        jenis: JenisTransaksi.belanja,
        nominal: _totalBelanja,
        keterangan: 'Belanja ${_cartItems.length} item',
        kasir: 'Admin', // TODO: Get from current user session
        detailBarang: {
          'items': _cartItems.map((item) => {
            'nama': item.barang.nama,
            'quantity': item.quantity,
            'harga': item.barang.harga,
            'total': item.barang.harga * item.quantity,
          }).toList(),
        },
      );

      await DatabaseHelper.instance.insertTransaksi(transaksi);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Belanja berhasil! Saldo tersisa: Rp ${_formatCurrency(saldoBaru)}',
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
}

class CartItem {
  final Barang barang;
  final int quantity;

  CartItem({required this.barang, required this.quantity});
}
