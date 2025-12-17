import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/santri.dart';
import '../models/barang.dart';
import '../models/transaksi.dart';
import '../models/supplier.dart';
import '../models/kasir.dart';
import '../models/karyawan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
      // Bersihkan barcode duplikat setelah database siap
      await _cleanDuplicateBarcodesOnInit();
    }
    return _database!;
  }

  Future<void> _cleanDuplicateBarcodesOnInit() async {
    try {
      await cleanDuplicateBarcodes();
    } catch (e) {
      // Ignore errors during cleanup
      print('Warning: Could not clean duplicate barcodes: $e');
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'santri_cooperative.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah tabel karyawan untuk upgrade dari versi 1 ke 2
      await db.execute('''
        CREATE TABLE karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama TEXT NOT NULL,
          id_pengguna TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          level_akses TEXT NOT NULL DEFAULT 'karyawan',
          shift TEXT NOT NULL DEFAULT 'pagi',
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insert default karyawan
      await db.insert('karyawan', {
        'nama': 'Karyawan Default',
        'id_pengguna': 'karyawan01',
        'password': 'karyawan123',
        'level_akses': 'karyawan',
        'shift': 'pagi',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Santri
    await db.execute('''
      CREATE TABLE santri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_kartu TEXT UNIQUE NOT NULL,
        nama TEXT NOT NULL,
        nis TEXT UNIQUE NOT NULL,
        kelas TEXT NOT NULL,
        pin TEXT,
        saldo REAL DEFAULT 0.0,
        limit_harian REAL DEFAULT 50000.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Supplier
    await db.execute('''
      CREATE TABLE supplier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_kontak TEXT,
        alamat TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Barang
    await db.execute('''
      CREATE TABLE barang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga REAL NOT NULL,
        stok INTEGER NOT NULL DEFAULT 0,
        satuan TEXT NOT NULL,
        barcode TEXT UNIQUE,
        harga_beli REAL,
        supplier_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
      )
    ''');

    // Tabel Kasir
    await db.execute('''
      CREATE TABLE kasir (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        id_pengguna TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        level_akses TEXT NOT NULL DEFAULT 'kasir',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        id_pengguna TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        level_akses TEXT NOT NULL DEFAULT 'karyawan',
        shift TEXT NOT NULL DEFAULT 'pagi',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_kartu TEXT NOT NULL,
        jenis TEXT NOT NULL,
        nominal REAL NOT NULL,
        keterangan TEXT,
        kasir TEXT NOT NULL,
        detail_barang TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (nomor_kartu) REFERENCES santri (nomor_kartu)
      )
    ''');

    // Insert default admin
    await db.insert('kasir', {
      'nama': 'Administrator',
      'id_pengguna': 'admin',
      'password': 'admin123',
      'level_akses': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default karyawan
    await db.insert('karyawan', {
      'nama': 'Karyawan Default',
      'id_pengguna': 'karyawan01',
      'password': 'karyawan123',
      'level_akses': 'karyawan',
      'shift': 'pagi',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // CRUD Santri
  Future<int> insertSantri(Santri santri) async {
    final db = await database;
    return await db.insert('santri', santri.toMap());
  }

  Future<List<Santri>> getAllSantri() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('santri');
    return List.generate(maps.length, (i) => Santri.fromMap(maps[i]));
  }

  Future<Santri?> getSantriByKartu(String nomorKartu) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'santri',
      where: 'nomor_kartu = ?',
      whereArgs: [nomorKartu],
    );
    if (maps.isNotEmpty) {
      return Santri.fromMap(maps.first);
    }
    return null;
  }

  Future<Santri?> getSantriByNis(String nis) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'santri',
      where: 'nis = ?',
      whereArgs: [nis],
    );
    if (maps.isNotEmpty) {
      return Santri.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSantri(Santri santri) async {
    final db = await database;
    return await db.update(
      'santri',
      santri.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [santri.id],
    );
  }

  Future<int> updateSaldoSantri(String nomorKartu, double saldo) async {
    final db = await database;
    return await db.update(
      'santri',
      {
        'saldo': saldo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'nomor_kartu = ?',
      whereArgs: [nomorKartu],
    );
  }

  Future<int> deleteSantri(int id) async {
    final db = await database;
    return await db.delete(
      'santri',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Barang
  Future<int> insertBarang(Barang barang) async {
    final db = await database;
    try {
      return await db.insert('barang', barang.toMap());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: barang.barcode')) {
        throw Exception('Barcode sudah digunakan oleh barang lain');
      }
      rethrow;
    }
  }

  Future<List<Barang>> getAllBarang() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('barang');
    return List.generate(maps.length, (i) => Barang.fromMap(maps[i]));
  }

  Future<int> updateBarang(Barang barang) async {
    final db = await database;
    try {
      return await db.update(
        'barang',
        barang.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [barang.id],
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: barang.barcode')) {
        throw Exception('Barcode sudah digunakan oleh barang lain');
      }
      rethrow;
    }
  }

  Future<int> updateStokBarang(int barangId, int stokBaru) async {
    final db = await database;
    return await db.update(
      'barang',
      {
        'stok': stokBaru,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [barangId],
    );
  }

  Future<int> deleteBarang(int id) async {
    final db = await database;
    return await db.delete(
      'barang',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Barang?> getBarangById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'barang',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Barang.fromMap(maps.first);
    }
    return null;
  }

  Future<Barang?> getBarangByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'barang',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Barang.fromMap(maps.first);
    }
    return null;
  }

  // Fungsi untuk membersihkan barcode duplikat
  Future<void> cleanDuplicateBarcodes() async {
    final db = await database;
    
    // Cari barcode yang duplikat
    final duplicates = await db.rawQuery('''
      SELECT barcode, COUNT(*) as count 
      FROM barang 
      WHERE barcode IS NOT NULL AND barcode != '' 
      GROUP BY barcode 
      HAVING COUNT(*) > 1
    ''');
    
    for (var duplicate in duplicates) {
      final barcode = duplicate['barcode'] as String;
      
      // Ambil semua barang dengan barcode yang sama
      final barangList = await db.query(
        'barang',
        where: 'barcode = ?',
        whereArgs: [barcode],
        orderBy: 'id ASC',
      );
      
      // Biarkan yang pertama, hapus barcode dari yang lain
      for (int i = 1; i < barangList.length; i++) {
        await db.update(
          'barang',
          {
            'barcode': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [barangList[i]['id']],
        );
      }
    }
  }

  // CRUD Transaksi
  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromMap(maps[i]));
  }

  Future<List<Transaksi>> getTransaksiByKartu(String nomorKartu) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'nomor_kartu = ?',
      whereArgs: [nomorKartu],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromMap(maps[i]));
  }

  // CRUD Supplier
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('supplier', supplier.toMap());
  }

  Future<List<Supplier>> getAllSupplier() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('supplier');
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      'supplier',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete(
      'supplier',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Kasir
  Future<int> insertKasir(Kasir kasir) async {
    final db = await database;
    return await db.insert('kasir', kasir.toMap());
  }

  Future<List<Kasir>> getAllKasir() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kasir');
    return List.generate(maps.length, (i) => Kasir.fromMap(maps[i]));
  }

  Future<Kasir?> getKasirByCredentials(String idPengguna, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kasir',
      where: 'id_pengguna = ? AND password = ? AND is_active = 1',
      whereArgs: [idPengguna, password],
    );
    if (maps.isNotEmpty) {
      return Kasir.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateKasir(Kasir kasir) async {
    final db = await database;
    return await db.update(
      'kasir',
      kasir.toMap(),
      where: 'id = ?',
      whereArgs: [kasir.id],
    );
  }

  Future<int> deleteKasir(int id) async {
    final db = await database;
    return await db.delete(
      'kasir',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Laporan
  Future<Map<String, dynamic>> getLaporanHarian(DateTime tanggal) async {
    final db = await database;
    final startDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final endDate = startDate.add(const Duration(days: 1));
    
    final transaksi = await db.query(
      'transaksi',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    double totalTopup = 0;
    double totalPenarikan = 0;
    double totalBelanja = 0;
    int jumlahTransaksi = transaksi.length;

    for (var t in transaksi) {
      switch (t['jenis']) {
        case 'topup':
          totalTopup += (t['nominal'] as num).toDouble();
          break;
        case 'penarikan':
          totalPenarikan += (t['nominal'] as num).toDouble();
          break;
        case 'belanja':
          totalBelanja += (t['nominal'] as num).toDouble();
          break;
      }
    }

    return {
      'tanggal': tanggal,
      'total_topup': totalTopup,
      'total_penarikan': totalPenarikan,
      'total_belanja': totalBelanja,
      'jumlah_transaksi': jumlahTransaksi,
      'omzet': totalBelanja,
    };
  }

  Future<Map<String, dynamic>> getLaporanBulanan(int tahun, int bulan) async {
    final db = await database;
    final startDate = DateTime(tahun, bulan, 1);
    final endDate = DateTime(tahun, bulan + 1, 1);
    
    final transaksi = await db.query(
      'transaksi',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    double totalTopup = 0;
    double totalPenarikan = 0;
    double totalBelanja = 0;
    int jumlahTransaksi = transaksi.length;

    for (var t in transaksi) {
      switch (t['jenis']) {
        case 'topup':
          totalTopup += (t['nominal'] as num).toDouble();
          break;
        case 'penarikan':
          totalPenarikan += (t['nominal'] as num).toDouble();
          break;
        case 'belanja':
          totalBelanja += (t['nominal'] as num).toDouble();
          break;
      }
    }

    return {
      'tahun': tahun,
      'bulan': bulan,
      'total_topup': totalTopup,
      'total_penarikan': totalPenarikan,
      'total_belanja': totalBelanja,
      'jumlah_transaksi': jumlahTransaksi,
      'omzet': totalBelanja,
    };
  }

  Future<double> getTotalSaldoSemua() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(saldo) as total FROM santri');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getBarangStokRendah({int batasStok = 10}) async {
    final db = await database;
    return await db.query(
      'barang',
      where: 'stok <= ?',
      whereArgs: [batasStok],
      orderBy: 'stok ASC',
    );
  }

  Future<bool> isNomorKartuExists(String nomorKartu) async {
    final db = await database;
    final result = await db.query(
      'santri',
      where: 'nomor_kartu = ?',
      whereArgs: [nomorKartu],
    );
    return result.isNotEmpty;
  }

  Future<bool> isNisExists(String nis) async {
    final db = await database;
    final result = await db.query(
      'santri',
      where: 'nis = ?',
      whereArgs: [nis],
    );
    return result.isNotEmpty;
  }

  // CRUD Karyawan
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('karyawan');
    return List.generate(maps.length, (i) => Karyawan.fromMap(maps[i]));
  }

  Future<Karyawan?> getKaryawanByCredentials(String idPengguna, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'karyawan',
      where: 'id_pengguna = ? AND password = ? AND is_active = 1',
      whereArgs: [idPengguna, password],
    );
    if (maps.isNotEmpty) {
      return Karyawan.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Karyawan>> getKaryawanByShift(String shift) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'karyawan',
      where: 'shift = ? AND is_active = 1',
      whereArgs: [shift],
    );
    return List.generate(maps.length, (i) => Karyawan.fromMap(maps[i]));
  }

  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await database;
    return await db.update(
      'karyawan',
      karyawan.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  Future<int> deleteKaryawan(int id) async {
    final db = await database;
    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isIdPenggunaKaryawanExists(String idPengguna) async {
    final db = await database;
    final result = await db.query(
      'karyawan',
      where: 'id_pengguna = ?',
      whereArgs: [idPengguna],
    );
    return result.isNotEmpty;
  }

  // Fungsi Validasi Limit
  Future<bool> validateTransactionLimit(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final limitTransaksi = prefs.getDouble('limit_transaksi') ?? 50000.0;
    return amount <= limitTransaksi;
  }

  Future<bool> validateDailyLimit(String nomorKartu, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final limitHarian = prefs.getDouble('limit_harian') ?? 100000.0;
    
    // Get today's transactions for this card
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(nominal) as total FROM transaksi WHERE nomor_kartu = ? AND jenis_transaksi = "belanja" AND created_at >= ? AND created_at < ?',
      [nomorKartu, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    final todayTotal = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return (todayTotal + amount) <= limitHarian;
  }

  Future<bool> validateSaldoLimit(double newSaldo) async {
    final prefs = await SharedPreferences.getInstance();
    final limitSaldoMin = prefs.getDouble('limit_saldo_min') ?? 0.0;
    final limitSaldoMax = prefs.getDouble('limit_saldo_max') ?? 500000.0;
    
    return newSaldo >= limitSaldoMin && newSaldo <= limitSaldoMax;
  }

  Future<Map<String, double>> getLimits() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'limit_transaksi': prefs.getDouble('limit_transaksi') ?? 50000.0,
      'limit_harian': prefs.getDouble('limit_harian') ?? 100000.0,
      'limit_saldo_min': prefs.getDouble('limit_saldo_min') ?? 0.0,
      'limit_saldo_max': prefs.getDouble('limit_saldo_max') ?? 500000.0,
    };
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Backup dan Restore Database
  Future<String> backupDatabase() async {
    try {
      // Request storage permissions
      if (Platform.isAndroid) {
        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        var manageStorageStatus = await Permission.manageExternalStorage.status;
        if (!manageStorageStatus.isGranted) {
          manageStorageStatus = await Permission.manageExternalStorage.request();
        }
        
        // Also request regular storage permission for compatibility
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        // Check if at least one permission is granted
        if (!manageStorageStatus.isGranted && !storageStatus.isGranted) {
          throw Exception('Storage permission denied. Please grant storage access in app settings.');
        }
      }

      final db = await database;
      
      // Get all data from all tables
      final backup = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
        'santri': await db.query('santri'),
        'barang': await db.query('barang'),
        'transaksi': await db.query('transaksi'),
        'supplier': await db.query('supplier'),
        'kasir': await db.query('kasir'),
        'karyawan': await db.query('karyawan'),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backup);
      
      // Create custom backup directory
      // Backup files will be saved to: /storage/emulated/0/mitra dot asia/
      // This allows easy access and sharing of backup files
      Directory backupDir;
      if (Platform.isAndroid) {
        // Use custom path: /storage/emulated/0/mitra dot asia/
        backupDir = Directory('/storage/emulated/0/mitra dot asia');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
      } else {
        // For other platforms, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        backupDir = Directory('${directory.path}/mitra dot asia');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
      }

      // Create backup file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'koperasi_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  Future<bool> restoreDatabase(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup format
      if (!backup.containsKey('version') || !backup.containsKey('santri')) {
        throw Exception('Invalid backup file format');
      }

      final db = await database;
      
      // Start transaction
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('transaksi');
        await txn.delete('barang');
        await txn.delete('santri');
        await txn.delete('supplier');
        await txn.delete('kasir');
        await txn.delete('karyawan');
        
        // Restore data
        if (backup['santri'] != null) {
          for (var item in backup['santri'] as List) {
            await txn.insert('santri', item as Map<String, dynamic>);
          }
        }
        
        if (backup['supplier'] != null) {
          for (var item in backup['supplier'] as List) {
            await txn.insert('supplier', item as Map<String, dynamic>);
          }
        }
        
        if (backup['barang'] != null) {
          for (var item in backup['barang'] as List) {
            await txn.insert('barang', item as Map<String, dynamic>);
          }
        }
        
        if (backup['kasir'] != null) {
          for (var item in backup['kasir'] as List) {
            await txn.insert('kasir', item as Map<String, dynamic>);
          }
        }
        
        if (backup['karyawan'] != null) {
          for (var item in backup['karyawan'] as List) {
            await txn.insert('karyawan', item as Map<String, dynamic>);
          }
        }
        
        if (backup['transaksi'] != null) {
          for (var item in backup['transaksi'] as List) {
            await txn.insert('transaksi', item as Map<String, dynamic>);
          }
        }
      });
      
      return true;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }

  Future<List<String>> getBackupFiles() async {
    try {
      Directory backupDir;
      if (Platform.isAndroid) {
        // Use custom path: /storage/emulated/0/mitra dot asia/
        backupDir = Directory('/storage/emulated/0/mitra dot asia');
      } else {
        // For other platforms, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        backupDir = Directory('${directory.path}/mitra dot asia');
      }
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir.listSync()
          .where((file) => file.path.endsWith('.json') && file.path.contains('koperasi_backup'))
          .map((file) => file.path)
          .toList();
      
      files.sort((a, b) => b.compareTo(a)); // Sort by newest first
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return {
        'timestamp': backup['timestamp'],
        'version': backup['version'],
        'santri_count': (backup['santri'] as List?)?.length ?? 0,
        'barang_count': (backup['barang'] as List?)?.length ?? 0,
        'transaksi_count': (backup['transaksi'] as List?)?.length ?? 0,
        'file_size': await file.length(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete backup file: $e');
    }
  }
}
