import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_shell.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

// =============================================================================
// AUTH GATE
//
// Shows LoginScreen until someone is signed in, then shows the real app.
// =============================================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (!authController.isLoggedIn) {
        return const LoginScreen();
      }
      return const AppShell();
    });
  }
}