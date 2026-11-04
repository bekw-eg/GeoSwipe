import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) return;

    final success = await auth.register(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );

    if (!mounted) return;

    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (auth.errorMessage != null) ...[
            Container(
              key: const Key('register_error_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Display Name
          TextFormField(
            key: const Key('register_display_name_field'),
            controller: _displayNameController,
            enabled: !auth.isLoading,
            decoration: InputDecoration(
              labelText: 'Аты-жөні немесе лақап аты',
              hintText: 'Әлихан Бөкейхан',
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: AppColors.muted,
              ),
              filled: true,
              fillColor: AppColors.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.violet,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Аты-жөніңізді енгізіңіз';
              }
              if (value.trim().length < 2) {
                return 'Аты-жөні кемінде 2 таңбадан тұруы керек';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Username
          TextFormField(
            key: const Key('register_username_field'),
            controller: _usernameController,
            enabled: !auth.isLoading,
            decoration: InputDecoration(
              labelText: 'Пайдаланушы аты (логин)',
              hintText: 'alikhan99',
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.muted,
              ),
              filled: true,
              fillColor: AppColors.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.violet,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пайдаланушы атын енгізіңіз';
              }
              if (value.trim().length < 3) {
                return 'Логин кемінде 3 таңбадан тұруы керек';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                return 'Логинде тек латын әріптері, сандар және _ рұқсат';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Email
          TextFormField(
            key: const Key('register_email_field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !auth.isLoading,
            decoration: InputDecoration(
              labelText: 'Электрондық пошта (Email)',
              hintText: 'user@example.kz',
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.muted,
              ),
              filled: true,
              fillColor: AppColors.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.violet,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Электрондық поштаны енгізіңіз';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Жарамды email адресін көрсетіңіз (мысалы: user@example.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Password
          TextFormField(
            key: const Key('register_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !auth.isLoading,
            decoration: InputDecoration(
              labelText: 'Құпиясөз',
              hintText: 'Кемінде 6 таңба',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.muted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppColors.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.violet,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Құпиясөзді енгізіңіз';
              }
              if (value.length < 6) {
                return 'Құпиясөз кемінде 6 таңбадан тұруы керек';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Confirm Password
          TextFormField(
            key: const Key('register_confirm_password_field'),
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            enabled: !auth.isLoading,
            decoration: InputDecoration(
              labelText: 'Құпиясөзді растау',
              hintText: 'Құпиясөзді қайталаңыз',
              prefixIcon: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.muted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: AppColors.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.violet,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Құпиясөзді растаңыз';
              }
              if (value != _passwordController.text) {
                return 'Құпиясөздер бір-біріне сәйкес келмейді';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          // Register submit button
          FilledButton(
            key: const Key('register_submit_button'),
            onPressed: auth.isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.background,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Тіркелу',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Тіркелгенсіз бе?',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              TextButton(
                key: const Key('switch_to_login_button'),
                onPressed: widget.onSwitchToLogin,
                child: const Text(
                  'Жүйеге кіру',
                  style: TextStyle(
                    color: AppColors.violet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
