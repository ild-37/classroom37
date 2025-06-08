import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classroom37/documents/pdf_viewer_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom37/documents/test_page.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseId;
  final String courseName;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    print('CourseDetailPage: courseId=$courseId'); // Debug courseId

    final documentsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('documents');

    final examsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('exams');

    final courseDocRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseName),
          // No bottom: TabBar here
        ),
        body: Column(
          children: [
            // Desplegable con info del curso
            StreamBuilder<DocumentSnapshot>(
              stream: courseDocRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Error al cargar datos del curso'),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final master = data['master'] ?? 'Desconocido';
                final cd = data['cd']?.toString() ?? 'N/A';
                final description = data['description'] ?? 'Sin descripción';

                return ExpansionTile(
                  title: const Text('Información del curso'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text('Profesor: $master'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: Text('Código: $cd'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Descripción:\n$description',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                );
              },
            ),

            // TabBar justo debajo del desplegable
            const TabBar(
              tabs: [
                Tab(text: 'Documentos', icon: Icon(Icons.picture_as_pdf)),
                Tab(text: 'Exámenes', icon: Icon(Icons.assignment)),
              ],
            ),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: DOCUMENTOS
                  StreamBuilder<QuerySnapshot>(
                    stream: documentsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error al cargar documentos'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text('No hay documentos'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Sin nombre';
                          final route = data['route'];

                          if (route == null) return const SizedBox.shrink();

                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(name),
                            onTap: () {
                              if (route.toLowerCase().endsWith('.pdf')) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PdfViewerPage(url: route, title: name),
                                  ),
                                );
                              } else {
                                launchUrl(
                                  Uri.parse(route),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),

                  // TAB 2: EXÁMENES
                  StreamBuilder<QuerySnapshot>(
                    stream: examsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error al cargar exámenes'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final exams = snapshot.data!.docs;
                      if (exams.isEmpty) {
                        return const Center(child: Text('No hay exámenes'));
                      }

                      return ListView.builder(
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final data =
                              exams[index].data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Sin nombre';

                          return ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(name),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TestPage(
                                    courseId: courseId,
                                    examId: exams[index].id,
                                    examName: name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
