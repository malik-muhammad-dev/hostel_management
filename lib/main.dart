import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/logging/app_error_logger.dart';

void main() {
  // Both the entrypoint's own setup AND runApp() have to live inside the
  // SAME guarded zone — that's what lets runZonedGuarded's error handler
  // below catch an uncaught async error from anywhere in the app, not
  // just ones thrown synchronously during startup.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Before this, an error thrown while Flutter is building/laying
      // out/painting a widget printed a red-screen (debug) or just went
      // nowhere (release) — nothing was ever written down. This keeps
      // the exact same on-screen behavior (presentError still shows it)
      // and additionally records it, so a crash the client hits weeks
      // from now leaves a trace someone can actually go read.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppErrorLogger.log(
          'FlutterError',
          details.exception,
          details.stack,
        );
      };

      // Everything below can fail before the real app ever gets to
      // runApp() — most plausibly Supabase.initialize() with no
      // internet on launch. Without this try/catch, that failure would
      // just propagate out to runZonedGuarded's handler below, which
      // only logs to a file and returns — meaning NOTHING would ever
      // call runApp(), no window would ever appear, and the process
      // would sit there looking exactly like a hang, with zero way for
      // a non-technical person to know to go check a log file. Showing
      // an actual (if minimal) error screen is the difference between
      // "the app is broken, call Malik" and "the app never opens,
      // is my computer broken?"
      try {
        // Connects to Supabase once, at startup, before anything else
        // needs it. Every feature's SupabaseXDataSource reaches this
        // same client through Supabase.instance.client rather than
        // creating its own.
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );

        // Desktop platforms (Linux/Windows/macOS) don't have native
        // sqflite support — they need the ffi-backed factory instead.
        // Android/iOS use the regular sqflite implementation
        // automatically, so this only runs when actually on desktop.
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;

          // Maximize the window to fit the screen on launch instead of
          // the default fixed 1280x720 size.
          await windowManager.ensureInitialized();

          const windowOptions = WindowOptions(
            center: true,
            titleBarStyle: TitleBarStyle.normal,
          );

          windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();

            // A small delay ensures the native window handle is fully
            // ready before maximizing — calling maximize() immediately
            // can silently fail on some Windows setups.
            await Future.delayed(const Duration(milliseconds: 200));
            await windowManager.maximize();
          });
        }

        runApp(const HostelManagementApp());
      } catch (error, stackTrace) {
        AppErrorLogger.log('Startup failed', error, stackTrace);
        runApp(_StartupErrorApp(error: error));
      }
    },
    (error, stackTrace) {
      // Catches whatever FlutterError.onError above doesn't — an error
      // thrown from inside a Future/async gap with no try/catch of its
      // own (a missed one, or a genuinely unexpected failure). This is
      // the last line of defense before it would otherwise vanish with
      // nothing but a console nobody's watching.
      AppErrorLogger.log('Uncaught (runZonedGuarded)', error, stackTrace);
    },
  );
}

// =============================================================================
// STARTUP ERROR APP
//
// Only ever shown when the real app fails to even get as far as its
// first frame (see the try/catch around runApp() above) — a normal
// in-app error never reaches this. Deliberately minimal: no GetX, no
// Supabase, nothing that could itself fail the same way the real app
// just did.
// =============================================================================

class _StartupErrorApp extends StatelessWidget {
  final Object error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF9F7FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFF6C2B93),
                ),
                const SizedBox(height: 16),
                const Text(
                  "ONIMS couldn't start",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection, then close and '
                  'reopen the app. If this keeps happening, contact '
                  'support with the details below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF6C757D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}