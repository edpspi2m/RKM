import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class TrackingMapsView extends StatefulWidget {
  const TrackingMapsView({super.key});

  @override
  State<TrackingMapsView> createState() => _TrackingMapsViewState();
}

class _TrackingMapsViewState extends State<TrackingMapsView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().user?.id ?? '';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => setState(() => _isLoading = false)),
      )
      ..loadRequest(Uri.parse('https://admin2m.isreport.my.id/tracking_app.php?uid=$userId'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tracking Maps'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload())],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
