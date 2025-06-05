class AppUser {
  final String username;
  final String email;
  final int roleId;
  final List<String> cursos;

  AppUser({
    required this.username,
    required this.email,
    required this.roleId,
    required this.cursos,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role_id': roleId,
      'cursos': cursos, // Asegúrate de que sea List<String>
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      roleId: map['role_id'] ?? 1,
      cursos: List<String>.from(map['cursos'] ?? []), // <- AQUÍ está el fix
    );
  }
}
