import 'package:flutter/foundation.dart';
import 'package:privy_flutter/privy_flutter.dart';

class PrivyService extends ChangeNotifier {
  static const String appId = 'cmhsxw209010cl50clkljmd4o';
  static const String clientId = 'client-WY6SWUTN8yhzATNReKMneBZDnqLGAP7B8fodzRBEwVFmQ';

  late final Privy _privy;
  PrivyUser? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  PrivyUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Privy get privy => _privy;

  PrivyService() {
    _initialize();
  }

  void _initialize() {
    try {
      final config = PrivyConfig(
        appId: appId,
        appClientId: clientId,
      );
      _privy = Privy(config: config);
      _isInitialized = true;

      // Listen to authentication state changes
      _privy.user.listen((user) {
        _user = user;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize Privy: $e';
      if (kDebugMode) {
        print('Privy initialization error: $e');
      }
      notifyListeners();
    }
  }

  // Email authentication
  Future<void> sendEmailCode(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.email.sendCode(email);

      result.when(
        success: (_) {
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to send email code: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error sending email code: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmailCode(String email, String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.email.loginWithCode(
        email: email,
        code: code,
      );

      result.when(
        success: (user) {
          _user = user;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to login: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error logging in: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // SMS authentication
  Future<void> sendSmsCode(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.sms.sendCode(phoneNumber);

      result.when(
        success: (_) {
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to send SMS code: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error sending SMS code: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithSmsCode(String phoneNumber, String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.sms.loginWithCode(
        phoneNumber: phoneNumber,
        code: code,
      );

      result.when(
        success: (user) {
          _user = user;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to login: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error logging in: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // OAuth authentication
  Future<void> loginWithOAuth(OAuthProvider provider) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.oauth.login(provider);

      result.when(
        success: (user) {
          _user = user;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to login with OAuth: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error logging in with OAuth: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Embedded wallet operations
  Future<EmbeddedEthereumWallet?> createEthereumWallet() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.embeddedWallet.createEthereumWallet();

      EmbeddedEthereumWallet? wallet;
      result.when(
        success: (w) {
          wallet = w;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to create Ethereum wallet: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );

      return wallet;
    } catch (e) {
      _error = 'Error creating Ethereum wallet: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<EmbeddedSolanaWallet?> createSolanaWallet() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.embeddedWallet.createSolanaWallet();

      EmbeddedSolanaWallet? wallet;
      result.when(
        success: (w) {
          wallet = w;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to create Solana wallet: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );

      return wallet;
    } catch (e) {
      _error = 'Error creating Solana wallet: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _privy.logout();

      result.when(
        success: (_) {
          _user = null;
          _isLoading = false;
          notifyListeners();
        },
        failure: (exception) {
          _error = 'Failed to logout: ${exception.message}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error logging out: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
