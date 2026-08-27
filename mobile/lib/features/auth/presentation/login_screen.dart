import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bakery Logo in cozy circular badge
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.biscuit, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textDark.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.bakery_dining_rounded,
                              size: 54,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title
                    Text(
                      'Bakery Sales',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle chip
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.buttercream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sage.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Msemmen & Trid Distribution',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // White Card with Inputs
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.biscuit, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your credentials to continue',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error alert if any
                          if (authState.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'e.g. admin',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryDark),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryDark),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 22),

                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Login',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Subtle clean footer
                    Text(
                      'Bakery Sales System • Developed by Ziad',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
