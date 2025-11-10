import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'services/privy_service.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String _authMethod = 'email'; // 'email' or 'sms'
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    _privyService.addListener(_onPrivyStateChanged);
  }

  @override
  void dispose() {
    _privyService.removeListener(_onPrivyStateChanged);
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onPrivyStateChanged() {
    setState(() {});
  }

  Future<void> _sendCode() async {
    if (_authMethod == 'email') {
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')),
        );
        return;
      }
      await _privyService.sendEmailCode(_emailController.text);
    } else {
      if (_phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number (E.164 format)')),
        );
        return;
      }
      await _privyService.sendSmsCode(_phoneController.text);
    }

    if (_privyService.error == null) {
      setState(() {
        _codeSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code sent to ${_authMethod == 'email' ? 'email' : 'phone'}')),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }

    if (_authMethod == 'email') {
      await _privyService.loginWithEmailCode(
        _emailController.text,
        _codeController.text,
      );
    } else {
      await _privyService.loginWithSmsCode(
        _phoneController.text,
        _codeController.text,
      );
    }

    if (_privyService.isAuthenticated && mounted) {
      setState(() {
        _codeSent = false;
        _codeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully logged in!')),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    await _privyService.loginWithOAuth(OAuthProvider.google);
  }

  Future<void> _loginWithApple() async {
    await _privyService.loginWithOAuth(OAuthProvider.apple);
  }

  Future<void> _createEthereumWallet() async {
    final wallet = await _privyService.createEthereumWallet();
    if (wallet != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ethereum wallet created: ${wallet.address}')),
      );
    }
  }

  Future<void> _createSolanaWallet() async {
    final wallet = await _privyService.createSolanaWallet();
    if (wallet != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solana wallet created: ${wallet.address}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privy Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_privyService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _privyService.logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _privyService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_privyService.error != null)
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
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
                              onPressed: _privyService.clearError,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_privyService.isAuthenticated)
                    _buildAuthenticatedView()
                  else
                    _buildLoginView(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'email', label: Text('Email')),
                    ButtonSegment(value: 'sms', label: Text('SMS')),
                  ],
                  selected: {_authMethod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _authMethod = newSelection.first;
                      _codeSent = false;
                      _codeController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_authMethod == 'email')
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_codeSent,
                  )
                else
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (E.164 format)',
                      hintText: '+14155552671',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !_codeSent,
                  ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _codeSent ? _verifyCode : _sendCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(_codeSent ? 'Verify Code' : 'Send Code'),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Back'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Social Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loginWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView() {
    final user = _privyService.user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.green.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('User ID: ${user.id}'),
                if (user.linkedAccounts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Linked Accounts:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...user.linkedAccounts.map((account) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• ${account.type}: ${account.address ?? account.email ?? account.phoneNumber ?? 'N/A'}'),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Embedded Wallets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createEthereumWallet,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Create Ethereum Wallet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _createSolanaWallet,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Create Solana Wallet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
