import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_error_logger.dart';
import '../../data/models/app_user_model.dart';
import '../../data/repositories/auth_repository.dart';

// =============================================================================
// AUTH CONTROLLER
//
// - `currentUser` is the session state — null means "not logged in".
// - Session is in-memory only (not persisted across app restarts). Given
//   this is a single desktop machine used by staff during working hours,
//   requiring login again after a full app restart is an acceptable
//   trade-off for the time available, and it's the safer default anyway.
// - `bootstrapDefaultAdmin()` creates a starting admin account the very
//   first time the app runs against an empty `users` table — otherwise
//   nobody could ever log in. The default password MUST be changed after
//   first login; there is currently no "change password" screen, so if
//   that's needed before handoff, it should be added before delivery.
// =============================================================================

class AuthController extends GetxController {
  final AuthRepository repository;

  AuthController(this.repository);

  final currentUser = Rxn<AppUser>();
  final isLoading = false.obs;

  static const _defaultAdminUsername = 'admin';
  static const _defaultAdminPassword = 'admin123';

  static const _defaultFeeCollectorUsername = 'feecollector';
  static const _defaultFeeCollectorPassword = 'fee123';

  bool get isLoggedIn => currentUser.value != null;
  bool get isAdmin => currentUser.value?.role == UserRole.admin;
  bool get isFeeCollector => currentUser.value?.role == UserRole.feeCollector;

  @override
  void onInit() {
    super.onInit();
    bootstrapDefaultAdmin();
  }

  Future<void> bootstrapDefaultAdmin() async {
    try {
      final count = await repository.countUsers();
      if (count > 0) return;

      final adminHash = BCrypt.hashpw(_defaultAdminPassword, BCrypt.gensalt());

      // `id` is a client-generated UUID — the `users.id` column has no
      // AUTOINCREMENT to assign one on insert, so it must be set before
      // this ever reaches the datasource.
      await repository.addUser(
        AppUser(
          id: const Uuid().v4(),
          username: _defaultAdminUsername,
          passwordHash: adminHash,
          role: UserRole.admin,
        ),
      );

      final feeCollectorHash = BCrypt.hashpw(
        _defaultFeeCollectorPassword,
        BCrypt.gensalt(),
      );

      await repository.addUser(
        AppUser(
          id: const Uuid().v4(),
          username: _defaultFeeCollectorUsername,
          passwordHash: feeCollectorHash,
          role: UserRole.feeCollector,
        ),
      );

      debugPrint(
        '[DEBUG] Bootstrapped default accounts — '
        'admin: $_defaultAdminUsername / $_defaultAdminPassword, '
        'fee collector: $_defaultFeeCollectorUsername / $_defaultFeeCollectorPassword '
        '(change both before handing the app to the client).',
      );
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] bootstrapDefaultAdmin failed: $e');
      AppErrorLogger.log(
        'AuthController.bootstrapDefaultAdmin',
        e,
        stackTrace,
      );
    }
  }

  /// Returns null on success, or an error message to display.
  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Please enter both username and password.';
    }

    try {
      isLoading.value = true;

      final user = await repository.getUserByUsername(username.trim());

      if (user == null) {
        return 'Invalid username or password.';
      }

      final matches = BCrypt.checkpw(password, user.passwordHash);

      if (!matches) {
        return 'Invalid username or password.';
      }

      currentUser.value = user;
      return null;
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] login failed: $e');
      AppErrorLogger.log('AuthController.login', e, stackTrace);
      return 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    currentUser.value = null;
  }
}