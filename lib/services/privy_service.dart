import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:privy_flutter/privy_flutter.dart';

class PrivyService extends ChangeNotifier {
  static const String appId = 'cmhsxw209010cl50clkljmd4o';
  static const String clientId = 'client-WY6SWUTN8yhzATNReKMneBZDnqLGAP7B8fodzRBEwVFmQ';
  static const String appDomain = 'privy.io';
  static const String appUri = 'https://privy.io';

  late final Privy _privy;
  PrivyUser? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AuthState>? _authStateSubscription;

  PrivyUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Privy get privy => _privy;

  PrivyService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final config = PrivyConfig(
        appId: appId,
        appClientId: clientId,
      );
      _privy = Privy.init(config: config);

      // Get initial auth state
      final authState = await _privy.getAuthState();
      if (authState is Authenticated) {
        _user = authState.user;
      }

      // Listen to authentication state changes
      _authStateSubscription = _privy.authStateStream.listen((authState) {
        if (authState is Authenticated) {
          _user = authState.user;
        } else {
          _user = null;
        }
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize Privy: $e';
      if (kDebugMode) {
        print('Privy initialization error: $e');
      }
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _privy.logout();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error logging out: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // SIWE (Sign-In with Ethereum) methods
  Future<String?> generateSiweMessage({
    required String walletAddress,
    String chainId = '1',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final params = SiweMessageParams(
        appDomain: appDomain,
        appUri: appUri,
        chainId: chainId,
        walletAddress: walletAddress,
      );

      final result = await _privy.siwe.generateSiweMessage(params);

      String? message;
      result.fold(
        onSuccess: (msg) {
          message = msg;
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (exception) {
          _error = 'Failed to generate SIWE message: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );

      return message;
    } catch (e) {
      _error = 'Error generating SIWE message: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loginWithSiwe({
    required String message,
    required String signature,
    required String walletAddress,
    String chainId = '1',
    String? walletClientType,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final params = SiweMessageParams(
        appDomain: appDomain,
        appUri: appUri,
        chainId: chainId,
        walletAddress: walletAddress,
      );

      WalletLoginMetadata? metadata;
      if (walletClientType != null) {
        final clientType = _parseWalletClientType(walletClientType);
        if (clientType != null) {
          metadata = WalletLoginMetadata(
            walletClientType: clientType,
            connectorType: 'manual',
          );
        }
      }

      final result = await _privy.siwe.loginWithSiwe(
        message: message,
        signature: signature,
        params: params,
        metadata: metadata,
      );

      result.fold(
        onSuccess: (user) {
          _user = user;
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (exception) {
          _error = 'Failed to login with wallet: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error logging in with wallet: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  WalletClientType? _parseWalletClientType(String type) {
    switch (type.toLowerCase()) {
      case 'metamask':
        return WalletClientType.metamask;
      case 'okx':
        return WalletClientType.other; // OKX not in enum, use other
      case 'binance':
        return WalletClientType.binance;
      case 'coinbase':
        return WalletClientType.coinbaseWallet;
      case 'rainbow':
        return WalletClientType.rainbow;
      case 'trustwallet':
      case 'trust':
        return WalletClientType.trust;
      case 'zerion':
        return WalletClientType.zerion;
      default:
        return WalletClientType.other;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
