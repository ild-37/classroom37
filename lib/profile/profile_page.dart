import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'change_role_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          username = data['username'];
          email = data['email'];
          role = _getRoleName(data['role_id']);
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error cargando perfil: $e");
    }
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 1:
        return 'Estudiante';
      case 2:
        return 'Profesor';
      case 3:
        return 'Observador';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Nombre de usuario:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(username ?? ''),
                  const SizedBox(height: 16),
                  Text("Email:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(email ?? ''),
                  const SizedBox(height: 16),
                  Text("Rol:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(role ?? ''),
                  Row(
                    children: [
                      const Text(
                        "Rol:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(role ?? ''),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangeRolePage(),
                            ),
                          ).then(
                            (_) => _loadUserData(),
                          ); // Recargar datos al volver
                        },
                        child: const Text("Cambiar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
