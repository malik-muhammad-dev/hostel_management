import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/app/binding/app_binding.dart';
import 'package:hostel_management/app/theme/app_theme.dart';

import '../features/splash/presentation/screens/splash_screen.dart';

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hostel Management',
      theme: AppTheme.lightTheme,
      initialBinding: AppBinding(),
      home: const SplashScreen(),
    );
  }
}