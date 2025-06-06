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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Documentos', icon: Icon(Icons.picture_as_pdf)),
              Tab(text: 'Exámenes', icon: Icon(Icons.assignment)),
            ],
          ),
        ),
        body: TabBarView(
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
                    final data = docs[index].data() as Map<String, dynamic>;
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
                  return const Center(child: Text('Error al cargar exámenes'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final exams = snapshot.data!.docs;
                print(
                  'Exámenes recibidos: ${exams.length}',
                ); // Debug cantidad exámenes

                if (exams.isEmpty) {
                  return const Center(child: Text('No hay exámenes'));
                }

                return ListView.builder(
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final data = exams[index].data() as Map<String, dynamic>;
                    print('Examen #$index: $data'); // Debug contenido examen

                    final name = data['name'] ?? 'Sin nombre';
                    final url = data['url'];

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
    );
  }
}
