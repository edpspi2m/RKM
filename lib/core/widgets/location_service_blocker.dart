import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/theme/app_colors.dart';

/// Layar penuh yang muncul kalau GPS/Layanan Lokasi HP dalam keadaan MATI.
/// Aplikasi TIDAK BISA dipakai sama sekali sampai lokasi dinyalakan —
/// ini beda dari fake-GPS blocker (itu untuk lokasi PALSU, ini untuk
/// lokasi yang mati total).
class LocationServiceBlocker extends StatefulWidget {
  final VoidCallback onEnabled;
  const LocationServiceBlocker({super.key, required this.onEnabled});

  @override
  State<LocationServiceBlocker> createState() => _LocationServiceBlockerState();
}

class _LocationServiceBlockerState extends State<LocationServiceBlocker> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      widget.onEnabled();
      return;
    }
    setState(() => _checking = false);
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.location_off_outlined, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text('Lokasi Tidak Aktif', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Aplikasi RKM memerlukan layanan lokasi (GPS) untuk berjalan. Nyalakan GPS/Lokasi di pengaturan HP Anda, lalu tekan tombol di bawah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Buka Pengaturan Lokasi'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton(
                    onPressed: _checking ? null : _recheck,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), foregroundColor: Colors.white),
                    child: _checking
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sudah Dinyalakan, Cek Ulang'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
