import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop platforms (Linux/Windows/macOS) don't have native sqflite
  // support — they need the ffi-backed factory instead. Android/iOS use
  // the regular sqflite implementation automatically, so this only runs
  // when actually on desktop.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const HostelManagementApp());
}