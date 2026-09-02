enum UserRole { admin, feeCollector }

class AppUser {
  final String? id;
  final String username;
  final String passwordHash;
  final UserRole role;

  const AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role.name,
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as String?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.values.byName(map['role'] as String),
    );
  }
}