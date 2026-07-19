import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/otp_provider.dart';
import '../main_navigation_view.dart';

class OtpVerifyView extends StatefulWidget {
  final String username;
  const OtpVerifyView({super.key, required this.username});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  final TextEditingController _hiddenController = TextEditingController();
  final FocusNode _hiddenFocus = FocusNode();
  String _otp = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hiddenFocus.requestFocus());
  }

  @override
  void dispose() {
    _hiddenController.dispose();
    _hiddenFocus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _otp = value);
    if (value.length == 6) {
      FocusScope.of(context).unfocus();
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan 6 digit OTP terlebih dahulu')));
      return;
    }
    final otpProvider = context.read<OtpProvider>();
    final user = await otpProvider.verifyOtp(_otp);
    if (!mounted) return;

    if (user != null) {
      await context.read<AuthProvider>().loginWithToken(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainNavigationView()), (route) => false);
    } else {
      setState(() { _otp = ''; _hiddenController.clear(); });
      _hiddenFocus.requestFocus();
    }
  }

  Future<void> _handleResend() async {
    setState(() { _otp = ''; _hiddenController.clear(); });
    final ok = await context.read<OtpProvider>().resendOtp();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Kode OTP baru telah dikirim.' : 'Gagal mengirim ulang OTP.')));
    _hiddenFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final otpProvider = context.watch<OtpProvider>();
    final isVerifying = otpProvider.state == OtpState.verifying;
    final isExpired = otpProvider.secondsRemaining <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _hiddenFocus.requestFocus(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('Masukkan Kode OTP', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text('Kode 6 digit untuk "${widget.username}" dapat dilihat admin.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 28),

                // Kotak tampilan digit — TIDAK PAKAI TextField, jadi dijamin selalu terlihat.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final filled = index < _otp.length;
                        final isFocused = index == _otp.length;
                        return Container(
                          width: 44,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isFocused ? AppColors.primary : Colors.transparent, width: 2),
                          ),
                          child: Text(
                            filled ? _otp[index] : '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                          ),
                        );
                      }),
                    ),
                    // TextField sesungguhnya disembunyikan (transparan, ukuran 0), cuma menangkap keyboard.
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _hiddenController,
                          focusNode: _hiddenFocus,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: _onChanged,
                          decoration: const InputDecoration(counterText: ''),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    isExpired ? 'Kode kedaluwarsa' : 'Berlaku selama ${otpProvider.formattedCountdown}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isExpired ? AppColors.error : AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: otpProvider.state == OtpState.requestingOtp ? null : _handleResend,
                    child: Text(otpProvider.state == OtpState.requestingOtp ? 'Mengirim...' : 'Kirim Ulang Kode OTP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (otpProvider.state == OtpState.error && otpProvider.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Flexible(child: Text(otpProvider.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.action, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: isVerifying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verifikasi', style: TextStyle(fontWeight: FontWeight.w600)),
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
