import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/theme/app_colors.dart';

/// Layar penuh yang TIDAK BISA di-back/dismiss — sales WAJIB matikan
/// fake GPS dulu sebelum bisa lanjut pakai aplikasi sama sekali.
class GlobalFakeGpsBlocker extends StatefulWidget {
  final VoidCallback onCleared;
  const GlobalFakeGpsBlocker({super.key, required this.onCleared});

  @override
  State<GlobalFakeGpsBlocker> createState() => _GlobalFakeGpsBlockerState();
}

class _GlobalFakeGpsBlockerState extends State<GlobalFakeGpsBlocker> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 8));
      if (!pos.isMocked) {
        widget.onCleared();
        return;
      }
    } catch (_) {}
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF7A0C0C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Center(child: Text('✋', style: TextStyle(fontSize: 48))),
                ),
                const SizedBox(height: 24),
                const Text('Akses Diblokir', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Sistem mendeteksi lokasi palsu (fake GPS) aktif di perangkat ini. Matikan/nonaktifkan aplikasi fake GPS terlebih dahulu, lalu tekan tombol di bawah untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _checking ? null : _recheck,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF7A0C0C)),
                    child: _checking
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sudah Dimatikan, Cek Ulang', style: TextStyle(fontWeight: FontWeight.bold)),
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
