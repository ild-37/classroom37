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

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      // Usuario no autenticado, mostrar mensaje o redirigir
      return Scaffold(body: Center(child: Text('Usuario no autenticado')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 78, 2, 122),
        title: const Text(
          "Inicio",
          style: const TextStyle(
            color: Color.fromARGB(244, 247, 245, 245),
            fontWeight: FontWeight.bold,
          ),
        ), // Negrita)
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
              final courseData = courses[index].data() as Map<String, dynamic>;
              final courseName = courseData['name'] ?? 'Curso sin nombre';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 6, // sombra más visible en la tarjeta
                shadowColor: Colors.black54, // color de la sombra
                child: ListTile(
                  title: Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue, // texto azul
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
                          courseId:
                              courses[index].id, // id del documento Firestore
                          courseName:
                              courseData['name'] ?? '', // nombre del curso
                        ),
                      ),
                    );
                  
                  },
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
