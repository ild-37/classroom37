import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeRolePage extends StatefulWidget {
  const ChangeRolePage({super.key});

  @override
  State<ChangeRolePage> createState() => _ChangeRolePageState();
}

class _ChangeRolePageState extends State<ChangeRolePage> {
  final codeController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, int> roleMap = {'student': 1, 'teacher': 2, 'viewer': 3};

  String? _error;
  bool _loading = false;

  Future<void> _verifyCodeAndChangeRole() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final codeInput = int.tryParse(codeController.text.trim());
      if (codeInput == null) {
        setState(() {
          _error = "Introduce un código válido (número)";
          _loading = false;
        });
        return;
      }

      final query = await _db
          .collection('codes')
          .where('cd', isEqualTo: codeInput)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _error = "Código no encontrado";
          _loading = false;
        });
        return;
      }

      final codeData = query.docs.first.data();
      final roleName = codeData['name'] as String?;
      final roleId = roleMap[roleName];

      if (roleId == null) {
        setState(() {
          _error = "Rol no reconocido en base de datos";
          _loading = false;
        });
        return;
      }

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = "Usuario no autenticado";
          _loading = false;
        });
        return;
      }

      await _db.collection('users').doc(uid).update({'role_id': roleId});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rol actualizado correctamente')),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar Rol")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Introduce el código para cambiar tu rol:"),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Código"),
            ),
            const SizedBox(height: 20),
            const Text("Ejemplo: pon 11 para ser estudiante"),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCodeAndChangeRole,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Verificar y Cambiar Rol"),
            ),
          ],
        ),
      ),
    );
  }
}
