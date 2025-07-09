import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/error_helper.dart';

// Mode debug untuk testing biometrik di emulator
const bool debugBiometricMode = false;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showBiometric = false;
  bool _biometricLoading = false;
  late SessionService _sessionService;
  BiometricService? _biometricService;
  AuthService? _authService;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _sessionService = await SessionService.init();
      _biometricService = await BiometricService.init();
      _authService = await AuthService.init();

      if (mounted) {
        setState(() {
          // Jika mode debug aktif, paksa tampilkan tombol biometrik untuk testing
          _showBiometric =
              debugBiometricMode ||
              (_biometricService?.isBiometricAvailable ?? false);
        });
      }

      // Log status biometrik
      debugPrint(
        'Biometric available: ${_biometricService?.isBiometricAvailable}',
      );
      debugPrint('Show biometric button: $_showBiometric');
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _biometricLoading = true);
    _clearError();

    try {
      final authenticated =
          debugBiometricMode || await _biometricService!.authenticate();

      if (authenticated) {
        // Check if there's a stored token and it's valid
        final token = _sessionService.getToken();
        if (token != null) {
          // Validate token with backend
          final isValid = await _sessionService.validateTokenWithBackend(token);
          if (isValid) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            // Token invalid, clear it and show error
            await _sessionService.clearSession();
            _setError('Sesi Anda telah berakhir. Silakan login kembali.');
          }
        } else {
          _setError('Tidak ada sesi tersimpan. Silakan login manual.');
        }
      } else {
        _setError('Autentikasi biometrik gagal');
      }
    } catch (e) {
      _setError('Gagal autentikasi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _biometricLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);

    // Check if it's a connection error
    if (message.contains('koneksi') || message.contains('Connection refused')) {
      ErrorHelper.showConnectionErrorDialog(context, message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _clearError() {
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final result = await _authService!.login(email, password);

        if (result['success']) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _setError(result['message']);
        }
      } catch (e) {
        _setError('Terjadi kesalahan: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 400 ? size.width * 0.18 : 28,
            vertical: 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Icon(
                    _showBiometric
                        ? (_biometricService!.hasFaceId
                              ? Icons.face
                              : Icons.fingerprint)
                        : Icons.lock,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Login Karyawan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple[900],
                  ),
                ),
                const SizedBox(height: 32),
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[800], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Jika biometrik tersedia, tampilkan tombol
                if (_showBiometric) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _biometricLoading
                          ? null
                          : _handleBiometricLogin,
                      icon: _biometricLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _biometricService!.hasFaceId
                                  ? Icons.face
                                  : Icons.fingerprint,
                              size: 28,
                            ),
                      label: Text(
                        _biometricService!.hasFaceId
                            ? 'Login dengan Face ID'
                            : 'Login dengan Fingerprint',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau login dengan email',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                // Form login email dan password
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!val.contains('@')) {
                        return 'Format email salah';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Password wajib diisi'
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
