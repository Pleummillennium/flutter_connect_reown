import 'package:flutter/foundation.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WalletService extends ChangeNotifier {
  Web3App? _wcClient;
  EthereumAddress? _connectedAddress;
  String? _error;
  bool _isConnected = false;
  SessionData? _session;

  EthereumAddress? get connectedAddress => _connectedAddress;
  String? get error => _error;
  bool get isConnected => _isConnected;

  WalletService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize WalletConnect Web3App (for dApps)
      _wcClient = await Web3App.createInstance(
        projectId: '59cc1f3b89b7f1ddf96fb5cad7a7d898', // Default WalletConnect project ID
        metadata: const PairingMetadata(
          name: 'Privy Wallet Demo',
          description: 'Connect your wallet to Privy',
          url: 'https://privy.io',
          icons: ['https://privy.io/favicon.ico'],
        ),
      );

      _wcClient!.onSessionConnect.subscribe(_onSessionConnect);
      _wcClient!.onSessionDelete.subscribe(_onSessionDelete);
    } catch (e) {
      _error = 'Failed to initialize WalletConnect: $e';
      if (kDebugMode) {
        print('WalletConnect initialization error: $e');
      }
    }
  }

  void _onSessionConnect(SessionConnect? event) {
    if (event != null) {
      if (kDebugMode) {
        print('Session connected: ${event.session.topic}');
      }
      _session = event.session;

      // Get the connected address from the session
      final accounts = event.session.namespaces['eip155']?.accounts ?? [];
      if (accounts.isNotEmpty) {
        // Parse address from CAIP-10 format (eip155:1:0x...)
        final addressPart = accounts.first.split(':').last;
        _connectedAddress = EthereumAddress.fromHex(addressPart);
        _isConnected = true;
        notifyListeners();
      }
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    if (kDebugMode) {
      print('Session deleted');
    }
    _session = null;
    _connectedAddress = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<String?> connectWallet() async {
    try {
      _error = null;
      notifyListeners();

      if (_wcClient == null) {
        await _initialize();
        if (_wcClient == null) {
          _error = 'Failed to initialize WalletConnect';
          notifyListeners();
          return null;
        }
      }

      // Create connection
      final ConnectResponse response = await _wcClient!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1'], // Ethereum mainnet
            methods: [
              'eth_sendTransaction',
              'personal_sign',
              'eth_sign',
              'eth_signTypedData',
              'eth_signTypedData_v4',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final Uri? uri = response.uri;
      if (uri != null) {
        return uri.toString();
      }

      return null;
    } catch (e) {
      _error = 'Failed to connect wallet: $e';
      if (kDebugMode) {
        print('Wallet connection error: $e');
      }
      notifyListeners();
      return null;
    }
  }

  Future<String?> signMessage(String message) async {
    if (_connectedAddress == null || _session == null || _wcClient == null) {
      _error = 'No wallet connected';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();

      final signature = await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'eip155:1',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [message, _connectedAddress!.hex],
        ),
      );

      return signature as String;
    } catch (e) {
      _error = 'Failed to sign message: $e';
      if (kDebugMode) {
        print('Message signing error: $e');
      }
      notifyListeners();
      return null;
    }
  }

  Future<void> disconnectWallet() async {
    if (_session != null && _wcClient != null) {
      try {
        await _wcClient!.disconnectSession(
          topic: _session!.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Disconnect error: $e');
        }
      }
    }

    _connectedAddress = null;
    _isConnected = false;
    _session = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_wcClient != null) {
      _wcClient!.onSessionConnect.unsubscribe(_onSessionConnect);
      _wcClient!.onSessionDelete.unsubscribe(_onSessionDelete);
    }
    super.dispose();
  }
}
