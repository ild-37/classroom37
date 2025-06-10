import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classroom37/documents/pdf_viewer_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom37/documents/test_page.dart';
import 'package:classroom37/documents/document_teacher.dart';
import 'package:classroom37/documents/exam_teacher.dart';

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
    final documentsRef = courseRef.collection('documents');
    final examsRef = courseRef.collection('exams');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(courseName)),
        body: Column(
          children: [
            // Información del curso justo después del AppBar
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
                  // TAB 1: DOCUMENTOS
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Documento'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DocumentFormPage(courseId: courseId),
                                ),
                              ).then((added) {
                                if (added == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Documento agregado'),
                                    ),
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: documentsRef.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('Error al cargar documentos'),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Center(
                                child: Text('No hay documentos'),
                              );
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['name'] ?? 'Sin nombre';
                                final route = data['route'];

                                if (route == null)
                                  return const SizedBox.shrink();

                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(name),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DocumentFormPage(
                                              courseId: courseId,
                                              documentId: doc.id,
                                              initialName: data['name'],
                                              initialRoute: data['route'],
                                            ),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        FirebaseFirestore.instance
                                            .collection('courses')
                                            .doc(courseId)
                                            .collection('documents')
                                            .doc(doc.id)
                                            .delete();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (route.toLowerCase().endsWith('.pdf')) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfViewerPage(
                                            url: route,
                                            title: name,
                                          ),
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
                      ),
                    ],
                  ),

                  // TAB 2: EXÁMENES
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Examen'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExamFormPage(courseId: courseId),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: examsRef.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('Error al cargar exámenes'),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final exams = snapshot.data!.docs;
                            if (exams.isEmpty) {
                              return const Center(
                                child: Text('No hay exámenes'),
                              );
                            }

                            return ListView.builder(
                              itemCount: exams.length,
                              itemBuilder: (context, index) {
                                final exam = exams[index];
                                final data =
                                    exam.data() as Map<String, dynamic>;
                                final name = data['name'] ?? 'Sin nombre';

                                return ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(name),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ExamFormPage(
                                              courseId: courseId,
                                              examId: exam.id,
                                              initialName: data['name'],
                                            ),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        FirebaseFirestore.instance
                                            .collection('courses')
                                            .doc(courseId)
                                            .collection('exams')
                                            .doc(exam.id)
                                            .delete();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TestPage(
                                          courseId: courseId,
                                          examId: exam.id,
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
                      ),
                    ],
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
