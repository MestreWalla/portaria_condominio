import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../localizations/app_localizations.dart';
import 'package:flutter/services.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    await _loadSavedEmail();
    await _checkBiometricAvailability();
    await _loadBiometricPreference();
    await _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    setState(() {
      _hasCredentials = savedEmail != null && savedPassword != null;
    });
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    });
    
    if (_isBiometricEnabled && _isBiometricAvailable && _hasCredentials) {
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      debugPrint('Erro ao verificar biometria: $e');
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha email e senha antes de habilitar a biometria';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('password', _passwordController.text.trim());
    setState(() {
      _hasCredentials = true;
    });
  }

  Future<void> _toggleBiometric(bool? value) async {
    if (value == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Faça login primeiro antes de habilitar a biometria';
        });
        return;
      }
      await _saveCredentials();
    } else {
      await prefs.remove('password');
      setState(() {
        _hasCredentials = false;
      });
    }

    await prefs.setBool('isBiometricEnabled', value);
    setState(() {
      _isBiometricEnabled = value;
      _errorMessage = '';
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      if (!_isBiometricAvailable) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('biometric_not_available');
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');

      if (savedEmail == null || savedPassword == null) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('credentials_not_found');
          _hasCredentials = false;
          _isBiometricEnabled = false;
        });
        await prefs.setBool('isBiometricEnabled', false);
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: AppLocalizations.of(context).translate('biometric_auth_reason'),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        // Preenche os campos com as credenciais salvas
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
        await _handleLogin(savedEmail, savedPassword);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context).translate('biometric_auth_error')}: $e';
      });
    }
  }

  Future<void> _handleLogin([String? email, String? password]) async {
    // Se tiver email e senha fornecidos (login por biometria), não valida o formulário
    if (email != null && password != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final role = await _authController.signIn(email, password);

        if (role == 'morador' || role == 'portaria') {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context).translate('user_not_recognized');
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = '${AppLocalizations.of(context).translate('login_error')}: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Login normal com validação de formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userEmail = _emailController.text.trim();
      final userPassword = _passwordController.text.trim();

      final role = await _authController.signIn(userEmail, userPassword);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', userEmail);
      
      if (_isBiometricEnabled) {
        await prefs.setString('password', userPassword);
        setState(() {
          _hasCredentials = true;
        });
      }

      if (role == 'morador' || role == 'portaria') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('user_not_recognized');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context).translate('login_error')}: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 1),
                              Hero(
                                tag: 'logo',
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primaryContainer.withOpacity(0.2),
                                  ),
                                  child: Image.asset(
                                    'assets/img/logo.png',
                                    height: size.height * 0.15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                appLocalizations.translate('welcome'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appLocalizations.translate('login_to_continue'),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              _buildTextField(
                                controller: _emailController,
                                label: appLocalizations.translate('email'),
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return appLocalizations.translate('enter_email');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: appLocalizations.translate('password'),
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return appLocalizations.translate('enter_password');
                                  }
                                  return null;
                                },
                              ),
                              if (_errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildErrorMessage(),
                              ],
                              if (_isBiometricAvailable) ...[
                                const SizedBox(height: 16),
                                _buildBiometricSwitch(appLocalizations),
                              ],
                              const Spacer(flex: 2),
                              if (_isBiometricEnabled && _hasCredentials && !_isLoading)
                                _buildBiometricButton(colorScheme),
                              const SizedBox(height: 16),
                              _buildLoginButton(appLocalizations),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricSwitch(AppLocalizations appLocalizations) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(
          appLocalizations.translate('enable_biometric'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: _isBiometricEnabled,
        onChanged: _toggleBiometric,
        secondary: Icon(
          Icons.fingerprint,
          color: Theme.of(context).colorScheme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(ColorScheme colorScheme) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton.filled(
          icon: const Icon(Icons.fingerprint, size: 32),
          onPressed: _authenticateWithBiometrics,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations appLocalizations) {
    return FilledButton(
      onPressed: _isLoading ? null : () => _handleLogin(),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
      ),
      child: _isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Text(
              appLocalizations.translate('login_button'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
