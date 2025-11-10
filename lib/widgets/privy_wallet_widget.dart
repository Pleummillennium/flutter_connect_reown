import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/privy_service.dart';

class PrivyWalletWidget extends StatefulWidget {
  final PrivyService privyService;

  const PrivyWalletWidget({
    super.key,
    required this.privyService,
  });

  @override
  State<PrivyWalletWidget> createState() => _PrivyWalletWidgetState();
}

class _PrivyWalletWidgetState extends State<PrivyWalletWidget> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          widget.privyService.handleMessage(message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/html/privy.html');

    widget.privyService.setWebViewController(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
