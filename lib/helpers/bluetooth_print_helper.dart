import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/santri.dart';
import '../models/karyawan.dart';
import '../screens/kasir/kasir_screen.dart';

class BluetoothPrintHelper {
  static final BluetoothPrintHelper _instance = BluetoothPrintHelper._internal();
  factory BluetoothPrintHelper() => _instance;
  BluetoothPrintHelper._internal();

  static BluetoothPrintHelper get instance => _instance;

  // Connection state tracking
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;

  // Check if printer is connected
  Future<bool> isConnected() async {
    try {
      final connected = await BluetoothPrintPlus.isConnected ?? false;
      _isConnected = connected;
      return connected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  // Get connected device info
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Show device selection dialog with improved UI
  Future<void> showDeviceSelectionDialog(BuildContext context) async {
    try {
      // Stop any existing scan first
      await BluetoothPrintPlus.stopScan();
      
      // Start scanning for devices
      await BluetoothPrintPlus.startScan();
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(
            'Pilih Printer Bluetooth',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: Column(
              children: [
                // Current connection status
                if (_isConnected && _connectedDevice != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terhubung ke:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                ),
                              ),
                              Text(
                                _connectedDevice!.name ?? 'Unknown Device',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Device list
                Expanded(
                  child: StreamBuilder<List<BluetoothDevice>>(
                    stream: BluetoothPrintPlus.scanResults,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final device = snapshot.data![index];
                            final isCurrentDevice = _connectedDevice?.address == device.address;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: isCurrentDevice ? 4 : 1,
                              color: isCurrentDevice ? Colors.blue[50] : null,
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCurrentDevice ? Colors.blue[200] : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isCurrentDevice ? Icons.bluetooth_connected : Icons.print,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  device.name ?? 'Unknown Device',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentDevice ? Colors.blue[800] : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.address ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isCurrentDevice)
                                      Text(
                                        'Terhubung',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: isCurrentDevice
                                    ? Icon(Icons.check_circle, color: Colors.blue[600], size: 20)
                                    : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                onTap: isCurrentDevice
                                    ? null
                                    : () async {
                                        Navigator.pop(context);
                                        await connectToDevice(context, device);
                                      },
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mencari printer...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pastikan printer Bluetooth sudah aktif\ndan dalam mode pairing',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await BluetoothPrintPlus.stopScan();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error scanning devices: $e');
      }
    }
  }

  // Connect to selected device with improved error handling
  Future<void> connectToDevice(BuildContext context, BluetoothDevice device) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Menghubungkan ke ${device.name ?? 'Unknown Device'}...'),
                ),
              ],
            ),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 10),
          ),
        );
      }

      // Disconnect from current device if connected
      if (_isConnected) {
        await disconnect();
      }

      // Connect to the selected device
      await BluetoothPrintPlus.connect(device);
      
      // Update connection state
      _isConnected = true;
      _connectedDevice = device;
      
      if (context.mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Terhubung ke ${device.name ?? 'Unknown Device'}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Reset connection state on error
      _isConnected = false;
      _connectedDevice = null;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar(context, 'Gagal terhubung: $e');
      }
    }
  }

  // Print receipt with improved error handling
  Future<void> printReceipt({
    required BuildContext context,
    required Santri santri,
    required Karyawan karyawan,
    required List<KasirCartItem> cartItems,
    required double totalAmount,
    required double newBalance,
  }) async {
    try {
      // Check if bluetooth is connected
      bool connected = await isConnected();
      
      if (!connected) {
        // Show device selection dialog
        await showDeviceSelectionDialog(context);
        return;
      }

      // Show printing progress
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Mencetak nota...'),
              ],
            ),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Generate receipt content
      Uint8List bytes = await _generateReceiptBytes(
        santri: santri,
        karyawan: karyawan,
        cartItems: cartItems,
        totalAmount: totalAmount,
        newBalance: newBalance,
      );
      
      // Print the receipt
      await BluetoothPrintPlus.write(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text('Nota berhasil dicetak'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar(context, 'Gagal mencetak: $e');
      }
    }
  }

  // Generate receipt bytes for thermal printer with better formatting
  Future<Uint8List> _generateReceiptBytes({
    required Santri santri,
    required Karyawan karyawan,
    required List<KasirCartItem> cartItems,
    required double totalAmount,
    required double newBalance,
  }) async {
    List<int> bytes = [];
    
    // ESC/POS commands
    const int ESC = 0x1B;
    const int GS = 0x1D;
    
    // Initialize printer
    bytes.addAll([ESC, 0x40]); // Initialize
    
    // Set code page to UTF-8 if supported
    bytes.addAll([ESC, 0x74, 0x06]);
    
    // Set alignment to center
    bytes.addAll([ESC, 0x61, 0x01]);
    
    // Header with larger font
    bytes.addAll([ESC, 0x21, 0x30]); // Double height and width
    bytes.addAll([ESC, 0x45, 0x01]); // Bold on
    bytes.addAll('PESANTREN STORE\n'.codeUnits);
    bytes.addAll([ESC, 0x21, 0x00]); // Normal font
    bytes.addAll([ESC, 0x45, 0x00]); // Bold off
    bytes.addAll('======================\n'.codeUnits);
    
    // Set alignment to left
    bytes.addAll([ESC, 0x61, 0x00]);
    
    // Transaction info
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    bytes.addAll('Tanggal: ${dateFormat.format(now)}\n'.codeUnits);
    bytes.addAll('Kasir  : ${karyawan.nama}\n'.codeUnits);
    bytes.addAll('Santri : ${santri.nama}\n'.codeUnits);
    bytes.addAll('----------------------\n'.codeUnits);
    
    // Items header
    bytes.addAll([ESC, 0x45, 0x01]); // Bold on
    bytes.addAll('ITEM PEMBELIAN:\n'.codeUnits);
    bytes.addAll([ESC, 0x45, 0x00]); // Bold off
    
    // Items
    for (final item in cartItems) {
      String itemName = item.barang.nama;
      if (itemName.length > 20) {
        itemName = '${itemName.substring(0, 17)}...';
      }
      
      bytes.addAll('$itemName\n'.codeUnits);
      
      // Format quantity and price line
      final qtyPriceStr = '${item.quantity} x ${_formatCurrency(item.barang.harga)}';
      final subtotalStr = _formatCurrency(item.barang.harga * item.quantity);
      final spacesNeeded = 32 - qtyPriceStr.length - subtotalStr.length;
      final spaces = ' ' * (spacesNeeded > 0 ? spacesNeeded : 1);
      
      bytes.addAll('$qtyPriceStr$spaces$subtotalStr\n'.codeUnits);
    }
    
    bytes.addAll('----------------------\n'.codeUnits);
    
    // Total with emphasis
    bytes.addAll([ESC, 0x45, 0x01]); // Bold on
    bytes.addAll([ESC, 0x21, 0x10]); // Double height
    final totalStr = 'TOTAL: ${_formatCurrency(totalAmount)}';
    bytes.addAll('$totalStr\n'.codeUnits);
    bytes.addAll([ESC, 0x21, 0x00]); // Normal font
    bytes.addAll([ESC, 0x45, 0x00]); // Bold off
    
    // Balance info
    bytes.addAll('Saldo Tersisa: ${_formatCurrency(newBalance)}\n'.codeUnits);
    bytes.addAll('----------------------\n'.codeUnits);
    
    // Set alignment to center
    bytes.addAll([ESC, 0x61, 0x01]);
    bytes.addAll('\n'.codeUnits);
    bytes.addAll([ESC, 0x45, 0x01]); // Bold on
    bytes.addAll('TERIMA KASIH\n'.codeUnits);
    bytes.addAll([ESC, 0x45, 0x00]); // Bold off
    bytes.addAll('Selamat Berbelanja Kembali\n'.codeUnits);
    bytes.addAll('\n'.codeUnits);
    bytes.addAll([ESC, 0x21, 0x01]); // Small font
    bytes.addAll('Powered by EPondok\n'.codeUnits);
    bytes.addAll([ESC, 0x21, 0x00]); // Normal font
    
    // Feed paper
    bytes.addAll([0x0A, 0x0A, 0x0A]);
    
    // Cut paper (if supported)
    bytes.addAll([GS, 0x56, 0x00]);
    
    return Uint8List.fromList(bytes);
  }

  // Test print function
  Future<void> testPrint(BuildContext context) async {
    try {
      bool connected = await isConnected();
      
      if (!connected) {
        await showDeviceSelectionDialog(context);
        return;
      }

      List<int> bytesList = [];
      const int ESC = 0x1B;
      
      // Initialize printer
      bytesList.addAll([ESC, 0x40]);
      
      // Set alignment to center
      bytesList.addAll([ESC, 0x61, 0x01]);
      
      // Test content
      bytesList.addAll([ESC, 0x21, 0x30]); // Double size
      bytesList.addAll('TEST PRINT\n'.codeUnits);
      bytesList.addAll([ESC, 0x21, 0x00]); // Normal size
      bytesList.addAll('==================\n'.codeUnits);
      bytesList.addAll('Printer berhasil terhubung\n'.codeUnits);
      bytesList.addAll('dan siap digunakan\n'.codeUnits);
      bytesList.addAll('\n'.codeUnits);
      bytesList.addAll('${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}\n'.codeUnits);
      
      // Feed paper
      bytesList.addAll([0x0A, 0x0A, 0x0A]);
      
      // Convert to Uint8List
      final bytes = Uint8List.fromList(bytesList);
      
      await BluetoothPrintPlus.write(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Test print berhasil'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Test print gagal: $e');
      }
    }
  }

  // Format currency helper with better formatting
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Show error snackbar helper
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Disconnect from printer
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      _isConnected = false;
      _connectedDevice = null;
    } catch (e) {
      // Ignore disconnect errors but still reset state
      _isConnected = false;
      _connectedDevice = null;
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    try {
      await BluetoothPrintPlus.stopScan();
    } catch (e) {
      // Ignore stop scan errors
    }
  }

  // Clean up resources
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
  }
}