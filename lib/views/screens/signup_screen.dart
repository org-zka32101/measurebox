import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全てのフィールドを入力してください')),
      );
      return;
    }

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが一致しません')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは6文字以上です')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).signup(
            email: email,
            password: password,
            displayName: name,
          );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サインアップに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.signup),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Name Field
              Text(
                'お名前',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: '田中太郎',
                  enabled: !authState.isLoading,
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              Text(
                AppStrings.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  enabled: !authState.isLoading,
                ),
              ),
              const SizedBox(height: 24),

              // Password Field
              Text(
                AppStrings.password,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  enabled: !authState.isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Confirm Field
              Text(
                AppStrings.passwordConfirm,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmController,
                obscureText: !_isPasswordConfirmVisible,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  enabled: !authState.isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordConfirmVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordConfirmVisible =
                            !_isPasswordConfirmVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Signup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      authState.isLoading ? null : _handleSignup,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(AppStrings.signup),
                ),
              ),
              const SizedBox(height: 16),

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.haveAccount,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pop(),
                      child: Text(
                        AppStrings.loginHere,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Error display
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      border: Border.all(color: errorColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${AppStrings.errorTitle}: ${authState.error}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: errorColor,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
