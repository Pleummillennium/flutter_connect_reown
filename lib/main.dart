import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppConnectReown',
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
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _lastConnectionState = false;
  String? _signature;
  String? _signedMessage;
  DateTime? _signedAt;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _initializeReownAppKit();
  }

  Future<void> _initializeReownAppKit() async {
    try {
      // Initialize Reown AppKit with Ape Chain
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'ca221e0cb470bd7c95a9e849d71c340b',
        metadata: const PairingMetadata(
          name: 'AppConnectReown',
          description: 'A Flutter wallet app using Reown AppKit',
          url: 'https://reown.com',
          icons: ['https://reown.com/favicon.ico'],
          redirect: Redirect(
            native: 'flutterrbhprivy://',
            universal: 'https://reown.com/exampleapp',
          ),
        ),
        optionalNamespaces: {
          'eip155': RequiredNamespace(
            chains: ['eip155:33139'], // Ape Chain only
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      await _appKitModal!.init();

      // Listen to session events
      _appKitModal!.addListener(_onModalUpdate);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Reown AppKit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Reown AppKit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
      }
    }
  }

  void _onModalUpdate() {
    final currentState = _appKitModal?.isConnected ?? false;

    // Only rebuild if connection state actually changed
    if (currentState != _lastConnectionState) {
      debugPrint('Modal updated - isConnected: $currentState');

      if (currentState) {
        debugPrint('Session: ${_appKitModal?.session}');
        final address = _getWalletAddress();
        debugPrint('Address: $address');

        // Auto-sign when connected
        if (address != null) {
          _autoSignOnConnect(address);
        }
      } else {
        // Clear signature when disconnected
        setState(() {
          _signature = null;
          _signedMessage = null;
          _signedAt = null;
        });
      }

      _lastConnectionState = currentState;
      setState(() {});
    }
  }

  // Auto-sign after connecting wallet
  Future<void> _autoSignOnConnect(String address) async {
    // Check if already signed
    final alreadySigned = await _checkIfAlreadySigned(address);

    if (!alreadySigned) {
      // Wait a bit for modal to close, then trigger sign
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _appKitModal?.isConnected == true) {
        _signMessage();
      }
    }
  }

  String? _getWalletAddress() {
    try {
      // Try to get address from session accounts
      final session = _appKitModal?.session;
      if (session != null) {
        // Get accounts from the session
        final accounts = session.getAccounts();
        if (accounts != null && accounts.isNotEmpty) {
          // Extract address from account string (format: "eip155:33139:0x...")
          final account = accounts.first;
          final parts = account.split(':');
          if (parts.length >= 3) {
            return parts[2];
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  // Generate SIWE (Sign-In With Ethereum) message
  String _generateSIWEMessage(String address) {
    final domain = 'appconnectreown.com';
    final uri = 'https://appconnectreown.com';
    final now = DateTime.now().toUtc();
    final issuedAt = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(now);
    final nonce = now.millisecondsSinceEpoch.toString();

    return '''$domain wants you to sign in with your Ethereum account:
$address

Welcome to AppConnectReown! Click "Sign" to authenticate.

URI: $uri
Version: 1
Chain ID: 33139
Nonce: $nonce
Issued At: $issuedAt''';
  }

  // Check if wallet has been signed before
  Future<bool> _checkIfAlreadySigned(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'signature_$address';
      final signatureData = prefs.getString(key);

      if (signatureData != null) {
        final data = json.decode(signatureData);
        setState(() {
          _signature = data['signature'];
          _signedMessage = data['message'];
          _signedAt = DateTime.parse(data['signedAt']);
        });
        debugPrint('Found existing signature for $address');
        return true;
      }
    } catch (e) {
      debugPrint('Error checking signature: $e');
    }
    return false;
  }

  // Save signature to storage
  Future<void> _saveSignature(String address, String signature, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'signature_$address';
      final data = {
        'signature': signature,
        'message': message,
        'signedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, json.encode(data));
      debugPrint('Signature saved for $address');
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  // Sign message with wallet
  Future<void> _signMessage() async {
    final address = _getWalletAddress();
    if (address == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No wallet address found')),
        );
      }
      return;
    }

    // Check if already signed
    final alreadySigned = await _checkIfAlreadySigned(address);
    if (alreadySigned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This wallet is already signed in!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSigning = true;
    });

    try {
      final message = _generateSIWEMessage(address);
      debugPrint('Signing message:\n$message');

      // Convert message to hex for personal_sign
      final messageBytes = utf8.encode(message);
      final messageHex = '0x${messageBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      // Request signature using personal_sign
      final signature = await _appKitModal!.request(
        topic: _appKitModal!.session!.topic,
        chainId: 'eip155:33139',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [messageHex, address],
        ),
      );

      debugPrint('Signature received: $signature');

      // Save signature
      await _saveSignature(address, signature.toString(), message);

      setState(() {
        _signature = signature.toString();
        _signedMessage = message;
        _signedAt = DateTime.now();
        _isSigning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error signing message: $e');
      setState(() {
        _isSigning = false;
      });

      // Disconnect wallet on sign failure
      await _appKitModal?.disconnect();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Sign-in Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Please connect your wallet again to sign in'),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_onModalUpdate);
    _appKitModal?.dispose();
    super.dispose();
  }

  Future<void> _connectWallet() async {
    try {
      await _appKitModal?.openModalView();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open wallet modal: $e')),
        );
      }
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      await _appKitModal?.disconnect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _appKitModal?.isConnected ?? false;
    final address = _getWalletAddress();

    debugPrint('=== BUILD ===');
    debugPrint('isConnected: $isConnected');
    debugPrint('address: $address');
    debugPrint('session: ${_appKitModal?.session}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AppConnectReown'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : isConnected && address != null
              ? _buildConnectedView(address)
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

              // Connect Wallet Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _connectWallet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet),
                      SizedBox(width: 12),
                      Text(
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

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView(String address) {
    // Shorten address for display
    final shortAddress = '${address.substring(0, 6)}...${address.substring(address.length - 4)}';

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar with Success Indicator
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.purple[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Address Display
            Text(
              shortAddress,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Connected Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Connected to ApeChain',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0.00 ETH',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$0.00 USD',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Send',
                    color: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Send feature coming soon!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.arrow_downward,
                    label: 'Receive',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receive feature coming soon!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.shopping_bag,
                    label: 'Buy',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buy feature coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Signing in progress
            if (_signature == null && _isSigning)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Signing in progress...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your wallet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

            // Signature Display
            if (_signature != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Authenticated',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Signed at: ${DateFormat('MMM dd, yyyy HH:mm').format(_signedAt!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signature:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_signature!.substring(0, 20)}...${_signature!.substring(_signature!.length - 20)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Wallet Address Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Wallet Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Address copied!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.copy, size: 16, color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Network Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.link, size: 20, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ApeChain',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Disconnect Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _disconnectWallet,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[200]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Disconnect Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
