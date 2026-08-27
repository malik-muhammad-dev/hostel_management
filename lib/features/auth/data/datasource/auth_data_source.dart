import '../models/app_user_model.dart';

abstract class AuthDataSource {
  Future<AppUser?> getUserByUsername(String username);

  Future<void> addUser(AppUser user);

  Future<int> countUsers();
}