import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:password_strength_checker/password_strength_checker.dart'; // Import the package
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final passNotifier = ValueNotifier<PasswordStrength?>(null); // For password strength
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success;
      if (_isSignUp) {
        // Register new user
        success = await authProvider.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
      } else {
        // Login existing user
        success = await authProvider.login(
          _emailController.text,
          _passwordController.text,
        );
      }

      if (success && mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email address to receive a password reset link."),
            const SizedBox(height: 16),
            PawPalsTextField(
              label: "Email",
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains("@")) {
                  return "Please enter a valid email.";
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Send Link"),
            onPressed: () async {
              if (emailController.text.isNotEmpty && emailController.text.contains("@")) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.sendPasswordResetEmail(emailController.text);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset link sent to your email.")),
                );
              } else {
                // Optionally show an error within the dialog or just rely on field validator
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    _isLoading = authProvider.status == AuthStatus.authenticating;
    _errorMessage = authProvider.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    'assets/images/logo.png', // Use the new logo
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image can't be loaded
                      return const Center(
                        child: Text(
                          'PawPals',
                          style: TextStyle(
                            // Ensure AppColors.primary is defined in your AppTheme
                            // color: AppColors.primary, 
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  _isSignUp ? 'Sign Up' : 'Log In',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Error message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusM,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field (only for sign up)
                if (_isSignUp) ...[
                  PawPalsTextField(
                    label: 'Name',
                    hint: 'Enter your name',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (_isSignUp && (value == null || value.isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Trigger validation for the form on change
                      if (_formKey.currentState != null && _formKey.currentState!.mounted) {
                        _formKey.currentState!.validate();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                PawPalsTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Trigger validation for the form on change
                    if (_formKey.currentState != null && _formKey.currentState!.mounted) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                PawPalsTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isSignUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Trigger validation for the form on change
                    if (_formKey.currentState != null && _formKey.currentState!.mounted) {
                      _formKey.currentState!.validate();
                    }
                    // Update password strength notifier
                    if (_isSignUp) {
                      passNotifier.value = PasswordStrength.calculate(text: value);
                    }
                  },
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 8),
                  PasswordStrengthChecker(
                    strength: passNotifier,
                    // You can customize the appearance here if needed
                    // e.g., height: 10,
                    //       strengthColors: StrengthColors(
                    //         weak: Colors.red,
                    //         medium: Colors.orange,
                    //         strong: Colors.green,
                    //       ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 24), // Maintain spacing if not signing up
                ],

                // Submit button
                _isLoading
                    ? const CircularProgressIndicator()
                    : PawPalsButton(
                      text: _isSignUp ? 'Sign Up' : 'Log In',
                      onPressed: _submitForm,
                    ),
                const SizedBox(height: 16),

                // Toggle auth mode
                TextButton(
                  onPressed: _isLoading ? null : _toggleAuthMode,
                  child: Text(
                    _isSignUp
                        ? "Already have an account? Log In"
                        : "Don\'t have an account? Sign Up",
                  ),
                ),
                // Forgot Password Button (only in Log In mode)
                if (!_isSignUp)
                  TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text("Forgot Password?"),
                  ),
                const SizedBox(height: 16),

                // Continue with
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // TODO: Implement Google sign-in
                              },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.facebook, size: 32),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // TODO: Implement Facebook sign-in
                              },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.apple, size: 32),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // TODO: Implement Apple sign-in
                              },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
