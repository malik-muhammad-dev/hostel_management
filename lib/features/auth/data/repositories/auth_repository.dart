import 'package:hostel_management/features/auth/data/datasource/auth_data_source.dart';

import '../models/app_user_model.dart';

class AuthRepository {
  final AuthDataSource dataSource;

  AuthRepository(this.dataSource);

  Future<AppUser?> getUserByUsername(String username) {
    return dataSource.getUserByUsername(username);
  }

  Future<void> addUser(AppUser user) {
    return dataSource.addUser(user);
  }

  Future<int> countUsers() {
    return dataSource.countUsers();
  }
}