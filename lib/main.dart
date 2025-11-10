import 'package:flutter/material.dart';
import 'services/privy_service.dart';
import 'widgets/privy_wallet_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Privy Wallet Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PrivyWalletPage(),
    );
  }
}

class PrivyWalletPage extends StatefulWidget {
  const PrivyWalletPage({super.key});

  @override
  State<PrivyWalletPage> createState() => _PrivyWalletPageState();
}

class _PrivyWalletPageState extends State<PrivyWalletPage> {
  final PrivyService _privyService = PrivyService();

  @override
  void initState() {
    super.initState();
    _privyService.addListener(_onPrivyStateChanged);
  }

  @override
  void dispose() {
    _privyService.removeListener(_onPrivyStateChanged);
    super.dispose();
  }

  void _onPrivyStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privy Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_privyService.isConnected)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _privyService.logout();
              },
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_privyService.error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _privyService.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _privyService.reset();
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_privyService.isConnected && _privyService.user != null)
            Container(
              width: double.infinity,
              color: Colors.green.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Wallet Connected',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (_privyService.user!.walletAddress != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Address:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _privyService.user!.walletAddress!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: PrivyWalletWidget(privyService: _privyService),
          ),
        ],
      ),
    );
  }
}
