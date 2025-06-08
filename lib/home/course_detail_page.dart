import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final courseRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId);
    final documentsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('documents');

    final examsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('exams');

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(courseName)),
        body: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: courseRef.snapshots(),
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

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profesor: $master',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Código del curso: $cd'),
                        const SizedBox(height: 6),
                        Text('Descripción:\n$description'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Documentos', icon: Icon(Icons.picture_as_pdf)),
                Tab(text: 'Exámenes', icon: Icon(Icons.assignment)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pestaña Documentos
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
                      if (docs.isEmpty)
                        return const Center(child: Text('No hay documentos'));

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

                  // Pestaña Exámenes con nota del usuario
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
                      if (exams.isEmpty)
                        return const Center(child: Text('No hay exámenes'));

                      return ListView.builder(
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final examData =
                              exams[index].data() as Map<String, dynamic>;
                          final examName = examData['name'] ?? 'Sin nombre';
                          final examId = exams[index].id;

                          return FutureBuilder<DocumentSnapshot>(
                            future: userId == null
                                ? Future.value(null)
                                : FirebaseFirestore.instance
                                      .collection('courses')
                                      .doc(courseId)
                                      .collection('exams')
                                      .doc(examId)
                                      .collection('students')
                                      .doc(userId)
                                      .get(),
                            builder: (context, snapshotNota) {
                              String qualificationText = 'Sin nota';
                              if (snapshotNota.connectionState ==
                                  ConnectionState.waiting) {
                                qualificationText = 'Cargando nota...';
                              } else if (snapshotNota.hasData &&
                                  snapshotNota.data!.exists) {
                                final studentData =
                                    snapshotNota.data!.data()
                                        as Map<String, dynamic>?;
                                final qualification =
                                    studentData?['qualification'];
                                if (qualification != null) {
                                  qualificationText = 'Nota: $qualification';
                                }
                              }

                              return ListTile(
                                leading: const Icon(Icons.description),
                                title: Text(examName),
                                subtitle: Text(qualificationText),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TestPage(
                                        courseId: courseId,
                                        examId: examId,
                                        examName: examName,
                                      ),
                                    ),
                                  );
                                },
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
