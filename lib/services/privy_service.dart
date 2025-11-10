import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivyUser {
  final String? id;
  final String? walletAddress;
  final String? email;

  PrivyUser({this.id, this.walletAddress, this.email});

  factory PrivyUser.fromJson(Map<String, dynamic> json) {
    return PrivyUser(
      id: json['id'],
      walletAddress: json['wallet']?['address'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletAddress': walletAddress,
      'email': email,
    };
  }
}

class PrivyService extends ChangeNotifier {
  static const String appId = 'cmhsxw209010cl50clkljmd4o';
  static const String appSecret = '21HZARwBzZeyopJ2t3RTh6eQ1zcyWbeNKpF3jW2CNyq9CWS4v4ryZ1793cBo3R3uHuB7r1uSpGmn7kHePQDNa2eF';

  PrivyUser? _user;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  PrivyUser? get user => _user;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WebViewController? _webViewController;

  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  void handleMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message);
      final event = data['event'];
      final eventData = data['data'];

      if (kDebugMode) {
        print('Privy Event: $event');
        print('Privy Data: $eventData');
      }

      switch (event) {
        case 'privy_ready':
          _isLoading = false;
          _error = null;
          notifyListeners();
          break;

        case 'login_started':
          _isLoading = true;
          _error = null;
          notifyListeners();
          break;

        case 'login_success':
          _isLoading = false;
          _isConnected = true;
          if (eventData['user'] != null) {
            _user = PrivyUser.fromJson(eventData['user']);
          }
          notifyListeners();
          break;

        case 'login_error':
          _isLoading = false;
          _error = eventData['error'] ?? 'Login failed';
          notifyListeners();
          break;

        case 'logout_success':
          _isLoading = false;
          _isConnected = false;
          _user = null;
          notifyListeners();
          break;

        case 'logout_error':
          _isLoading = false;
          _error = eventData['error'] ?? 'Logout failed';
          notifyListeners();
          break;

        case 'privy_error':
          _isLoading = false;
          _error = eventData['error'] ?? 'An error occurred';
          notifyListeners();
          break;

        case 'open_privy_login':
          // Handle opening Privy login in external browser or custom implementation
          if (kDebugMode) {
            print('Should open Privy login with App ID: ${eventData['appId']}');
          }
          break;

        default:
          if (kDebugMode) {
            print('Unknown event: $event');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message: $e');
      }
      _error = 'Error processing message';
      notifyListeners();
    }
  }

  Future<void> login() async {
    if (_webViewController != null) {
      final message = jsonEncode({'action': 'login'});
      await _webViewController!.runJavaScript(
        'handleFlutterMessage(\'$message\')',
      );
    }
  }

  Future<void> logout() async {
    if (_webViewController != null) {
      final message = jsonEncode({'action': 'logout'});
      await _webViewController!.runJavaScript(
        'handleFlutterMessage(\'$message\')',
      );
    }
  }

  Future<void> getUser() async {
    if (_webViewController != null) {
      final message = jsonEncode({'action': 'get_user'});
      await _webViewController!.runJavaScript(
        'handleFlutterMessage(\'$message\')',
      );
    }
  }

  void userConnected(PrivyUser user) {
    if (_webViewController != null) {
      final message = jsonEncode({
        'action': 'user_connected',
        'data': {'user': user.toJson()}
      });
      _webViewController!.runJavaScript(
        'handleFlutterMessage(\'$message\')',
      );
    }
  }

  void reset() {
    _user = null;
    _isConnected = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
