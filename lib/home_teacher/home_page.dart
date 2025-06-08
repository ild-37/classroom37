import 'package:classroom37/documents/pdf_viewer_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'package:classroom37/home/course_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _leaveCourse(String courseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Eliminar subcolección de exámenes del usuario
      final examsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('courses')
          .doc(courseId)
          .collection('exams')
          .get();

      for (final doc in examsSnapshot.docs) {
        final examId = doc.id;

        // Borrar /users/{uid}/courses/{courseId}/exams/{examId}
        await _db
            .collection('users')
            .doc(uid)
            .collection('courses')
            .doc(courseId)
            .collection('exams')
            .doc(examId)
            .delete();

        // Borrar /courses/{courseId}/exams/{examId}/students/{uid}
        await _db
            .collection('courses')
            .doc(courseId)
            .collection('exams')
            .doc(examId)
            .collection('students')
            .doc(uid)
            .delete();
      }

      // Borrar el curso del usuario
      await _db
          .collection('users')
          .doc(uid)
          .collection('courses')
          .doc(courseId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚪 Te has salido del curso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al salir del curso: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Scaffold(body: Center(child: Text('Usuario no autenticado')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 78, 2, 122),
        title: const Text(
          "Inicio",
          style: TextStyle(
            color: Color.fromARGB(244, 247, 245, 245),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            color: Color.fromARGB(244, 247, 245, 245),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Color.fromARGB(244, 247, 245, 245),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('users')
            .doc(uid)
            .collection('courses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data?.docs ?? [];

          if (courses.isEmpty) {
            return const Center(
              child: Text('No estás inscrito en ningún curso.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final courseDoc = courses[index];
              final courseData = courseDoc.data() as Map<String, dynamic>;
              final courseName = courseData['name'] ?? 'Curso sin nombre';

              return Dismissible(
                key: Key(courseDoc.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("¿Salir del curso?"),
                      content: const Text(
                        "Se eliminarán todos tus datos asociados a este curso.",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Cancelar"),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: const Text("Salir"),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await _leaveCourse(courseDoc.id);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  elevation: 6,
                  shadowColor: Colors.black54,
                  child: ListTile(
                    title: Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailPage(
                            courseId: courseDoc.id,
                            courseName: courseName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/join_course');
        },
        child: const Icon(Icons.add),
        tooltip: 'Unirse a un curso',
      ),
    );
  }
}
