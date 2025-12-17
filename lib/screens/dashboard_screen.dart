import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/karyawan.dart';
import 'santri/santri_list_screen.dart';
import 'barang/barang_list_screen.dart';
import 'transaksi/transaksi_screen.dart';
import 'laporan/laporan_screen.dart';
import 'pengaturan/pengaturan_screen.dart';
import 'karyawan/karyawan_list_screen.dart';
import 'kasir/kasir_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalSantri = 0;
  int _totalBarang = 0;
  double _totalOmzet = 0;
  int _transaksiHariIni = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final santriList = await DatabaseHelper.instance.getAllSantri();
      final barangList = await DatabaseHelper.instance.getAllBarang();
      final laporanHarian = await DatabaseHelper.instance.getLaporanHarian(
        DateTime.now(),
      );

      setState(() {
        _totalSantri = santriList.length;
        _totalBarang = barangList.length;
        _totalOmzet = laporanHarian['omzet'] ?? 0;
        _transaksiHariIni = laporanHarian['jumlah_transaksi'] ?? 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Pondok Digital",

          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDashboardData,
              color: Colors.teal[700],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: Colors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[600]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
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
                            Icons.dashboard_rounded,
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
                                'Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Kelola koperasi santri dengan mudah',
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
              // Statistik Cards
              const Text(
                'Statistik Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Santri',
                      _totalSantri.toString(),
                      Icons.people_rounded,
                      [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Barang',
                      _totalBarang.toString(),
                      Icons.inventory_2_rounded,
                      [Colors.orange[400]!, Colors.orange[600]!],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Omzet Hari Ini',
                      'Rp ${_formatCurrency(_totalOmzet)}',
                      Icons.trending_up_rounded,
                      [Colors.green[400]!, Colors.green[600]!],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Transaksi Hari Ini',
                      _transaksiHariIni.toString(),
                      Icons.receipt_long_rounded,
                      [Colors.purple[400]!, Colors.purple[600]!],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Menu Grid
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive grid parameters
                  final screenWidth = constraints.maxWidth;
                  final crossAxisCount = screenWidth > 600 ? 3 : 2;
                  final spacing = screenWidth > 400 ? 16.0 : 12.0;
                  final aspectRatio = screenWidth > 400 ? 1.1 : 1.0;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                    children: [
                      _buildMenuCard(
                        'Kasir',
                        Icons.point_of_sale_rounded,
                        [Colors.red[400]!, Colors.red[600]!],
                        () => _navigateToKasir(),
                      ),
                      _buildMenuCard(
                        'Transaksi',
                        Icons.payment_rounded,
                        [Colors.green[400]!, Colors.green[600]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransaksiScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        'Data Santri',
                        Icons.people_rounded,
                        [Colors.blue[400]!, Colors.blue[600]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SantriListScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        'Data Barang',
                        Icons.inventory_2_rounded,
                        [Colors.orange[400]!, Colors.orange[600]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BarangListScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        'Data Karyawan',
                        Icons.badge_rounded,
                        [Colors.indigo[400]!, Colors.indigo[600]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KaryawanListScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        'Laporan',
                        Icons.analytics_rounded,
                        [Colors.purple[400]!, Colors.purple[600]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LaporanScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        'Pengaturan',
                        Icons.settings_rounded,
                        [Colors.grey[500]!, Colors.grey[700]!],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengaturanScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.1),
            gradientColors[1].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradientColors[0].withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: gradientColors[1],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToKasir() async {
    // Create a default/guest karyawan for direct access
    final guestKaryawan = Karyawan(
      id: null,
      nama: 'Kasir Guest',
      idPengguna: 'guest',
      password: 'guest',
      levelAkses: 'kasir',
      shift: 'all',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KasirScreen(karyawan: guestKaryawan),
      ),
    ).then((_) {
      // Refresh dashboard data when returning from kasir
      _loadDashboardData();
    });
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
