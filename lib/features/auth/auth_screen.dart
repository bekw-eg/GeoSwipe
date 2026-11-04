import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialIsRegister = false});

  final bool initialIsRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegister = widget.initialIsRegister;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // App Brand & Logo
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.violet.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.change_history_rounded,
                        size: 42,
                        color: AppColors.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Geo',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: AppColors.text,
                        ),
                        children: [
                          TextSpan(
                            text: 'Swipe',
                            style: TextStyle(color: AppColors.violet),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _isRegister
                          ? 'Жаңа аккаунт ашып, геометрияны бастаңыз'
                          : 'Прогресті сақтау және гео-квестке кіру',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Segmented Switcher (Login / Register)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const Key('auth_tab_login'),
                            onTap: () {
                              auth.clearError();
                              setState(() => _isRegister = false);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegister
                                    ? AppColors.violet
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Кіру',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: !_isRegister
                                      ? AppColors.background
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            key: const Key('auth_tab_register'),
                            onTap: () {
                              auth.clearError();
                              setState(() => _isRegister = true);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegister
                                    ? AppColors.violet
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Тіркелу',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _isRegister
                                      ? AppColors.background
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Active Form
                  SurfaceCard(
                    padding: const EdgeInsets.all(22),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isRegister
                          ? RegisterForm(
                              key: const ValueKey('register_form_view'),
                              onSwitchToLogin: () {
                                auth.clearError();
                                setState(() => _isRegister = false);
                              },
                            )
                          : LoginForm(
                              key: const ValueKey('login_form_view'),
                              onSwitchToRegister: () {
                                auth.clearError();
                                setState(() => _isRegister = true);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Guest mode button
                  Center(
                    child: TextButton.icon(
                      key: const Key('auth_guest_button'),
                      onPressed: () {
                        auth.continueAsGuest();
                      },
                      icon: const Icon(
                        Icons.person_search_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      label: const Text(
                        'Қонақ ретінде жалғастыру (Офлайн режим)',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
