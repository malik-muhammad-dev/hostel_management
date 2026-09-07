import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _errorMessage = ''.obs;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    final error = await controller.login(
      _usernameController.text,
      _passwordController.text,
    );

    _errorMessage.value = error ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showHeroPanel = constraints.maxWidth >= 820;

          return Row(
            children: [
              // Roughly 40/60 — branding panel on the left, login form
              // clearly the larger, primary side on the right. (Originally
              // this had no flex at all here, which silently defaulted to
              // flex:1 against the form's flex:4 — a 20/80 split so lopsided
              // it clipped this panel's own content. Widened enough to hold
              // its content properly, while keeping the form as the bigger
              // side.)
              if (showHeroPanel) const Expanded(flex: 4, child: _HeroPanel()),
              Expanded(
                flex: showHeroPanel ? 6 : 1,
                child: _FormPanel(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  errorMessage: _errorMessage,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onSubmit: () => _submit(controller),
                  controller: controller,
                  showBrandLockup: !showHeroPanel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// HERO PANEL — the institutional side. Deliberately atmospheric: a purple
// gradient with faint seal-like circles, the crest, and a short line of
// context grounded in what this system actually does.
// =============================================================================

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
      ),
      child: Stack(
        children: [
          // Faint decorative circles — a quiet nod to the seal motif,
          // not a literal pattern.
          Positioned(
            top: -90,
            right: -70,
            child: _softCircle(260, 0.08),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: _softCircle(320, 0.06),
          ),
          Positioned(
            bottom: 90,
            right: 40,
            child: _softCircle(70, 0.10),
          ),

          // Wrapped in a scroll view that only ever kicks in on a short
          // window — a plain Column here would try to center within
          // whatever height it's given and throw a render overflow the
          // moment the window got shorter than the content (logo +
          // title + description). ConstrainedBox(minHeight: ...) keeps
          // the original centered look on any normal-sized window; it
          // only starts scrolling once there's genuinely not enough
          // room, instead of erroring.
          Padding(
            padding: const EdgeInsets.all(56),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.png'),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'HOSTEL MANAGEMENT SYSTEM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: AppColors.accentGold.withValues(alpha: 0.95),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          // Was a hard-coded 340 — wider than the panel
                          // itself could ever get before the flex-ratio
                          // fix above, and still worth guarding: this
                          // caps at 340 on a roomy window but never asks
                          // for more than the panel actually has, so it
                          // can't overflow the panel's right edge again.
                          width: constraints.maxWidth < 340
                              ? constraints.maxWidth
                              : 340,
                          child: Text(
                            'A single, secure record for every student\'s stay in the hostel, with all the details about their '
                            'admissions, fees, and daily hostel operations in one place.',
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.55,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 56,
            right: 16,
            bottom: 40,
            // Previously had no `right`, so this had no width limit at
            // all — on the narrow panel this used to render as (before
            // the flex fix above) it ran straight past the panel's own
            // right edge and got clipped there, instead of wrapping.
            // Anchoring both sides means it now wraps to a second line
            // if the panel is ever narrow again, rather than disappearing
            // off the edge.
            child: Text(
              'Obaid Noor Institute of Medical & Science',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// =============================================================================
// FORM PANEL
// =============================================================================

class _FormPanel extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final RxString errorMessage;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final AuthController controller;
  final bool showBrandLockup;

  const _FormPanel({
    required this.usernameController,
    required this.passwordController,
    required this.errorMessage,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.controller,
    required this.showBrandLockup,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBrandLockup) ...[
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Sign in to manage hostel records',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                decoration: _fieldDecoration(hint: 'Enter your username'),
                onSubmitted: (_) => onSubmit(),
              ),

              const SizedBox(height: 18),

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _fieldDecoration(hint: 'Enter your password')
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),

              Obx(() {
                if (errorMessage.value.isEmpty) {
                  return const SizedBox(height: 24);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage.value,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.isLoading.value ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
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

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}