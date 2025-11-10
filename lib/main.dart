import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'services/privy_service.dart';
import 'services/wallet_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Privy Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WalletPage(),
    );
  }
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final PrivyService _privyService = PrivyService();
  final WalletService _walletService = WalletService();

  @override
  void initState() {
    super.initState();
    _privyService.addListener(_onPrivyStateChanged);
    _walletService.addListener(_onWalletStateChanged);
  }

  @override
  void dispose() {
    _privyService.removeListener(_onPrivyStateChanged);
    _walletService.removeListener(_onWalletStateChanged);
    super.dispose();
  }

  void _onPrivyStateChanged() {
    setState(() {});
  }

  void _onWalletStateChanged() {
    setState(() {});
  }

  Future<void> _showWalletSelectionModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalletSelectionModal(
        privyService: _privyService,
        walletService: _walletService,
      ),
    );
  }

  String _getAccountDisplayValue(LinkedAccounts account) {
    switch (account) {
      case EmbeddedEthereumWalletAccount():
        return account.address;
      case EmbeddedSolanaWalletAccount():
        return account.address;
      case ExternalWalletAccount():
        return account.address;
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privy'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _privyService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _privyService.isAuthenticated
              ? _buildConnectedView()
              : _buildDisconnectedView(),
    );
  }

  Widget _buildDisconnectedView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[700]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Log in or sign up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 48),

              // Connect Wallet Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showWalletSelectionModal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      const Text(
                        'Connect wallet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Terms
              Text(
                'By connecting, you agree to the Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    final user = _privyService.user;
    if (user == null) return const SizedBox.shrink();

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Connected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // User Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User ID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (user.linkedAccounts.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Wallets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...user.linkedAccounts.map((account) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                size: 18,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getAccountDisplayValue(account),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _getAccountDisplayValue(account)),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied!')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Disconnect Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _walletService.disconnectWallet();
                  await _privyService.logout();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Disconnect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletSelectionModal extends StatefulWidget {
  final PrivyService privyService;
  final WalletService walletService;

  const _WalletSelectionModal({
    required this.privyService,
    required this.walletService,
  });

  @override
  State<_WalletSelectionModal> createState() => _WalletSelectionModalState();
}

class _WalletSelectionModalState extends State<_WalletSelectionModal> {
  bool _isConnecting = false;
  String? _wcUri;

  @override
  void initState() {
    super.initState();
    widget.walletService.addListener(_onWalletStateChanged);
  }

  @override
  void dispose() {
    widget.walletService.removeListener(_onWalletStateChanged);
    super.dispose();
  }

  void _onWalletStateChanged() {
    if (widget.walletService.isConnected && _wcUri != null) {
      _authenticateWithSiwe();
    }
  }

  Future<void> _connectWallet() async {
    setState(() {
      _isConnecting = true;
    });

    final wcUri = await widget.walletService.connectWallet();

    if (wcUri != null) {
      setState(() {
        _wcUri = wcUri;
      });
    } else {
      setState(() {
        _isConnecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize connection')),
        );
      }
    }
  }

  Future<void> _authenticateWithSiwe() async {
    final walletAddress = widget.walletService.connectedAddress;
    if (walletAddress == null) return;

    final siweMessage = await widget.privyService.generateSiweMessage(
      walletAddress: walletAddress.hex,
    );

    if (siweMessage == null) {
      setState(() {
        _isConnecting = false;
      });
      return;
    }

    final signature = await widget.walletService.signMessage(siweMessage);

    if (signature == null) {
      setState(() {
        _isConnecting = false;
      });
      return;
    }

    await widget.privyService.loginWithSiwe(
      message: siweMessage,
      signature: signature,
      walletAddress: walletAddress.hex,
    );

    if (mounted) {
      Navigator.pop(context);
      if (widget.privyService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connect a wallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with one of available wallet providers',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              if (_isConnecting && _wcUri != null)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Waiting for wallet connection...'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _wcUri!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickLaunchChip('MetaMask', _wcUri!),
                        _buildQuickLaunchChip('Trust', _wcUri!),
                        _buildQuickLaunchChip('Rainbow', _wcUri!),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildWalletOption(
                      name: 'MetaMask',
                      icon: Icons.account_balance_wallet,
                      color: Colors.orange,
                      onTap: _connectWallet,
                    ),
                    const SizedBox(height: 12),
                    _buildWalletOption(
                      name: 'Trust Wallet',
                      icon: Icons.shield,
                      color: Colors.blue,
                      onTap: _connectWallet,
                    ),
                    const SizedBox(height: 12),
                    _buildWalletOption(
                      name: 'Coinbase Wallet',
                      icon: Icons.currency_bitcoin,
                      color: Colors.blue[700]!,
                      onTap: _connectWallet,
                    ),
                    const SizedBox(height: 12),
                    _buildWalletOption(
                      name: 'Rainbow',
                      icon: Icons.gradient,
                      color: Colors.purple,
                      onTap: _connectWallet,
                    ),
                    const SizedBox(height: 12),
                    _buildWalletOption(
                      name: 'WalletConnect',
                      icon: Icons.qr_code,
                      color: Colors.blue,
                      onTap: _connectWallet,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletOption({
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isConnecting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLaunchChip(String name, String wcUri) {
    return ActionChip(
      avatar: const Icon(Icons.open_in_new, size: 14),
      label: Text(name, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        final url = 'wc:$wcUri';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
