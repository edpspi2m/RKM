import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Layar penuh yang muncul SESAAT fake GPS terdeteksi — akun sudah
/// dikunci di server, jadi TIDAK ADA tombol "cek ulang" di sini lagi.
/// Satu-satunya jalan keluar adalah logout dan minta master membuka
/// akun lewat web admin.
class GlobalFakeGpsBlocker extends StatelessWidget {
  const GlobalFakeGpsBlocker({super.key});

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
                const Text('Akun Dikunci Otomatis', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Sistem mendeteksi upaya penggunaan lokasi palsu (fake GPS). Akun Anda telah dikunci dan admin telah diberi tahu. Hubungi manager/supervisor Anda untuk membuka kembali akun ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
