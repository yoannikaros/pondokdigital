import 'package:flutter/material.dart';
import '../backup_restore/backup_restore_screen.dart';
import 'reset_pin_screen.dart';
import 'pengaturan_limit_screen.dart';
import 'tentang_aplikasi_screen.dart';
import 'kebijakan_privasi_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingCard(
            'Backup & Restore',
            'Backup dan restore database',
            Icons.backup,
            () => _backupRestore(),
          ),
          _buildSettingCard(
            'Reset PIN Santri',
            'Reset PIN semua santri',
            Icons.lock_reset,
            () => _resetPinSantri(),
          ),
          _buildSettingCard(
            'Pengaturan Limit',
            'Atur limit transaksi default',
            Icons.settings,
            () => _pengaturanLimit(),
          ),
          _buildSettingCard(
            'Kebijakan Privasi',
            'Kebijakan penggunaan data aplikasi',
            Icons.privacy_tip,
            () => _kebijakanPrivasi(),
          ),
          _buildSettingCard(
            'Tentang Aplikasi',
            'Informasi aplikasi dan versi',
            Icons.info,
            () => _tentangAplikasi(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _backupRestore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackupRestoreScreen(),
      ),
    );
  }

  void _resetPinSantri() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResetPinScreen(),
      ),
    );
  }

void _pengaturanLimit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PengaturanLimitScreen(),
      ),
    );
  }
void _tentangAplikasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TentangAplikasiScreen(),
      ),
    );
  }
  void _kebijakanPrivasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KebijakanPrivasiScreen(),
      ),
    );
  }
}
