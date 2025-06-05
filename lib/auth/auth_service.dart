import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registrar un nuevo usuario
  Future<User?> registerUser(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) {
        print("❌ Error: Usuario nulo tras crear en Auth");
        return null;
      }

      final user = AppUser(
        username: username,
        email: email,
        roleId: 1,
        cursos: [],
      );

      final userDocRef = _db.collection('users').doc(cred.user!.uid);

      // Guardamos el usuario
      await userDocRef.set(user.toMap());

      // Creamos la subcolección courses con documento id '0'
      print("✅ Usuario registrado en Auth y Firestore con curso por defecto");
      return cred.user;
    } catch (e, stacktrace) {
      print("❌ Error en registerUser: $e");
      print("📛 Stacktrace: $stacktrace");
      return null;
    }
  }

  // Iniciar sesión y obtener el usuario con datos completos
  Future<AppUser?> loginUser(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) {
        print("❌ Error: Usuario nulo tras login");
        return null;
      }

      DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        print("❌ No se encontró documento de usuario en Firestore");
        return null;
      }

      final appUser = AppUser.fromMap(doc.data()!);
      print("✅ Usuario logueado y datos recuperados: ${appUser.username}");
      return appUser;
    } catch (e) {
      print("❌ Error en loginUser: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
    print("👋 Sesión cerrada");
  }
}
