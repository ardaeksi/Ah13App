import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../scaffold/ah13_login_background.dart';
import '../constants.dart';
import 'auth_provider.dart';
import 'outlined_title_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ah13_error_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _isLoadingRemembered = true;
  bool _showContent = false;

  static const _kRememberMe = 'auth.remember_me';
  static const _kRememberedEmail = 'auth.remembered_email';
  static const _kRememberedPassword = 'auth.remembered_password';

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
    _kickoffEntranceDelay();

    // If the user turns on Remember me, we keep the stored credentials in sync
    // as they type (purely local/front-end as requested).
    _emailController.addListener(_maybePersistRememberedLogin);
    _passwordController.addListener(_maybePersistRememberedLogin);
  }

  void _kickoffEntranceDelay() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showContent = true);
    });
  }

  void _maybePersistRememberedLogin() {
    if (!_rememberMe) return;
    // Fire-and-forget; errors are debugPrinted inside.
    _persistRememberedLoginIfNeeded();
  }

  Future<void> _loadRememberedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_kRememberMe) ?? false;
      if (!remember) return;

      final email = prefs.getString(_kRememberedEmail) ?? '';
      final password = prefs.getString(_kRememberedPassword) ?? '';
      _emailController.text = email;
      _passwordController.text = password;
      _rememberMe = true;
    } catch (e) {
      debugPrint('Failed to load remembered login: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRemembered = false);
    }
  }

  Future<void> _persistRememberedLoginIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberMe, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(_kRememberedEmail, _emailController.text.trim());
        await prefs.setString(_kRememberedPassword, _passwordController.text);
      } else {
        await prefs.remove(_kRememberedEmail);
        await prefs.remove(_kRememberedPassword);
      }
    } catch (e) {
      debugPrint('Failed to persist remembered login: $e');
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_maybePersistRememberedLogin);
    _passwordController.removeListener(_maybePersistRememberedLogin);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final success =
          await auth.login(_emailController.text, _passwordController.text);

      if (success && mounted) {
        await _persistRememberedLoginIfNeeded();
        context.go('/deeds');
      } else if (mounted) {
        final msg = auth.lastError;
        Ah13ErrorSnackBar.show(
          context,
          msg == null || msg.isEmpty ? 'Login failed. Please try again.' : msg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShow = _showContent && !_isLoadingRemembered;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topLogoHeight = (screenWidth * 0.22).clamp(84.0, 140.0);
    final mainLogoHeight = (screenWidth * 0.32).clamp(140.0, 240.0);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Ah13LoginBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: AnimatedOpacity(
                opacity: canShow ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: canShow ? Offset.zero : const Offset(0, 0.05),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(AppImages.ahLogo,
                              height: topLogoHeight, fit: BoxFit.contain)
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: -0.15, end: 0),
                      const SizedBox(height: 12),

                      // Logo/Title
                      Center(
                        child: Image.asset(
                          AppImages.ah13AppLogo,
                          height: mainLogoHeight,
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.2, end: 0),

                      SizedBox(
                        height: 4,
                        child: Ah13LoginBackground(child: const Text('Child')),
                      ),

                      Text(
                        'Register or Log-in Start Logging Your Deeds!',
                        style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 3,
                            fontSize: 20),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: -0.2, end: 0),

                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: Colors.white),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideX(begin: -0.05, end: 0),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: Colors.white),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            )
                                .animate()
                                .fadeIn(delay: 260.ms)
                                .slideX(begin: 0.05, end: 0),

                            const SizedBox(height: 20),

                            // Remember me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) async {
                                    setState(() => _rememberMe = v ?? false);
                                    await _persistRememberedLoginIfNeeded();
                                  },
                                  activeColor: AppColors.primary,
                                  checkColor: AppColors.white,
                                  side: BorderSide(
                                      color: AppColors.surfaceVariant
                                          .withValues(alpha: 0.9)),
                                ),
                                Expanded(
                                  child: Text(
                                    'Remember me',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideX(begin: -0.03, end: 0),

                            const SizedBox(height: 10),

                            // Gradient primary action button
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.black
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        auth.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Text('Log In'),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: 320.ms).scale(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders text with a slim outline for better contrast on busy backgrounds.
