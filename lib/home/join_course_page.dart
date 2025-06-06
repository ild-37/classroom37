import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinCoursePage extends StatefulWidget {
  const JoinCoursePage({super.key});

  @override
  State<JoinCoursePage> createState() => _JoinCoursePageState();
}

class _JoinCoursePageState extends State<JoinCoursePage> {
  final _codeController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _error;
  bool _loading = false;

  Future<void> _joinCourse() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final codeInput = int.tryParse(_codeController.text.trim());
      if (codeInput == null) {
        setState(() {
          _error = "Introduce un código válido (número)";
          _loading = false;
        });
        return;
      }

      // Buscar curso con cd igual al código ingresado
      final query = await _db
          .collection('courses')
          .where('cd', isEqualTo: codeInput)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _error = "Curso no encontrado con ese código";
          _loading = false;
        });
        return;
      }

      final courseDoc = query.docs.first;
      final courseId = courseDoc.id;
      final courseData = courseDoc.data();
      final courseName = courseData['name'] ?? "Curso sin nombre";

      final uid = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email ?? "sin-email@ejemplo.com";

      if (uid == null) {
        setState(() {
          _error = "Usuario no autenticado";
          _loading = false;
        });
        return;
      }

      final userCourseRef = _db
          .collection('users')
          .doc(uid)
          .collection('courses')
          .doc(courseId);

      // Comprobar si el usuario ya está inscrito en ese curso
      final userCourseSnapshot = await userCourseRef.get();
      if (userCourseSnapshot.exists) {
        setState(() {
          _error = '⚠️ Ya estás inscrito en este curso';
          _loading = false;
        });
        return;
      }

      // Añadir curso a la subcolección 'courses' del usuario
      await userCourseRef.set({
        'name': courseName,
        'qualification': 0,
        'completed': false,
      });

      // Añadir estudiante a todos los exámenes del curso
      final examsQuery = await _db
          .collection('courses')
          .doc(courseId)
          .collection('exams')
          .get();

      for (final examDoc in examsQuery.docs) {
        final studentsRef = _db
            .collection('courses')
            .doc(courseId)
            .collection('exams')
            .doc(examDoc.id)
            .collection('students');

        await studentsRef.add({'email': userEmail, 'qualification': 0});
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Curso "$courseName" añadido correctamente'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unirse a curso")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Introduce el código numérico del curso:"),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Código del curso"),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _joinCourse,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Unirse al curso"),
            ),
          ],
        ),
      ),
    );
  }
}
