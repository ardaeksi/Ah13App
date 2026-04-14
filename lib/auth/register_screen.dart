import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../scaffold/ah13_login_background.dart';
import 'auth_provider.dart';
import 'outlined_title_text.dart';
import 'ah13_error_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentsPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parentsPinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final success = await auth.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        parentsPin: _parentsPinController.text,
      );

      if (!mounted) return;

      if (success) {
        context.go('/deeds');
      } else {
        final msg = auth.lastError;
        Ah13ErrorSnackBar.show(
          context,
          msg == null || msg.isEmpty
              ? 'Registration failed. Please try again.'
              : msg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShow = _showContent;
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: auth.isLoading
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
          body: Ah13LoginBackground(
            child: Center(
              child: auth.isLoading
                  ? CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: AnimatedOpacity(
                          opacity: canShow ? 1 : 0,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          child: AnimatedSlide(
                            offset:
                                canShow ? Offset.zero : const Offset(0, 0.05),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedTitleText(
                                  text: 'Create Your AH13 Deeds Account',
                                  textStyle: AppTextStyles.displayMedium
                                      .copyWith(color: AppColors.white),
                                  outlineColor: AppColors.black,
                                  textAlign: TextAlign.center,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms)
                                    .slideY(begin: -0.2, end: 0),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.surfaceVariant),
                                  ),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: Icon(Icons.person_outline,
                                              color: Colors.white),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
                                      )
                                          .animate()
                                          .fadeIn(delay: 200.ms)
                                          .slideX(),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email_outlined,
                                              color: Colors.white),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        validator: (value) {
                                          final v = (value ?? '').trim();
                                          if (v.isEmpty) return 'Required';
                                          final emailOk = RegExp(
                                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                              .hasMatch(v);
                                          if (!emailOk)
                                            return 'Enter a valid email';
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 260.ms)
                                          .slideX(),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock_outline,
                                              color: Colors.white),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        validator: (value) {
                                          final v = (value ?? '');
                                          if (v.trim().isEmpty)
                                            return 'Required';
                                          if (v.length < 6)
                                            return 'Use at least 6 characters';
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 320.ms)
                                          .slideX(),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: TextFormField(
                                          controller: _parentsPinController,
                                          keyboardType: TextInputType.number,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: "Parent's PIN",
                                            hintText: '4 digits',
                                            prefixIcon: Icon(
                                                Icons.supervisor_account_outlined,
                                                color: Colors.white),
                                          ),
                                          style: const TextStyle(
                                              color: Colors.white),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(4)
                                          ],
                                          validator: (value) {
                                            final pin = (value ?? '').trim();
                                            if (pin.isEmpty) return 'Required';
                                            if (pin.length != 4)
                                              return 'PIN must be 4 digits';
                                            return null;
                                          },
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(delay: 360.ms)
                                          .slideX(),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          "Parents PIN should be set by Parent to confirm completed tasks. After each deed this password will be asked to parents to confirm the task, make sure you remember! You can reset this later from your account.",
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                          textAlign: TextAlign.left,
                                        ),
                                      ).animate().fadeIn(delay: 420.ms),
                                      const SizedBox(height: 20),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.black
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _handleRegister,
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
                                          child: const Text('Create Account'),
                                        ),
                                      ).animate().fadeIn(delay: 380.ms).scale(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
