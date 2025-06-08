import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'course_detail_page.dart';

class HomeTeacher extends StatefulWidget {
  const HomeTeacher({super.key});

  @override
  State<HomeTeacher> createState() => _HomeTeacherState();
}

class _HomeTeacherState extends State<HomeTeacher> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _deleteCourse(String courseId) async {
    try {
      // Eliminar subcolecciones de documents
      final documents = await _db
          .collection('courses')
          .doc(courseId)
          .collection('documents')
          .get();
      for (final doc in documents.docs) {
        await doc.reference.delete();
      }

      // Eliminar exámenes y subcolección students
      final exams = await _db
          .collection('courses')
          .doc(courseId)
          .collection('exams')
          .get();
      for (final exam in exams.docs) {
        final students = await exam.reference.collection('students').get();
        for (final student in students.docs) {
          await student.reference.delete();
        }
        await exam.reference.delete();
      }

      // Borrar el curso
      await _db.collection('courses').doc(courseId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Curso eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al eliminar curso: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final email = _auth.currentUser?.email;

    if (email == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 77, 30),
        title: const Text(
          "Mis Cursos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
            .collection('courses')
            .where('master', isEqualTo: email)
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
            return const Center(child: Text('No has creado ningún curso.'));
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
                      title: const Text("¿Eliminar curso?"),
                      content: const Text(
                        "Esto eliminará todos los documentos y exámenes relacionados.",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Cancelar"),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: const Text("Eliminar"),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await _deleteCourse(courseDoc.id);
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
          Navigator.pushNamed(context, '/create_course');
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear nuevo curso',
      ),
    );
  }
}
