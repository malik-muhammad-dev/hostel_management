import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop platforms (Linux/Windows/macOS) don't have native sqflite
  // support — they need the ffi-backed factory instead. Android/iOS use
  // the regular sqflite implementation automatically, so this only runs
  // when actually on desktop.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Maximize the window to fit the screen on launch instead of the
    // default fixed 1280x720 size.
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      // A small delay ensures the native window handle is fully ready
      // before maximizing — calling maximize() immediately can silently
      // fail on some Windows setups.
      await Future.delayed(const Duration(milliseconds: 200));
      await windowManager.maximize();
    });
  }

  runApp(const HostelManagementApp());
}