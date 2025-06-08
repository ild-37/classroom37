import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_form_page.dart';

class TestEditorPage extends StatelessWidget {
  final String courseId;
  final String examId;

  const TestEditorPage({Key? key, required this.courseId, required this.examId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final testRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('exams')
        .doc(examId)
        .collection('test');

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Test')),
      body: StreamBuilder<QuerySnapshot>(
        stream: testRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar preguntas'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final doc = questions[index];
              final data = doc.data() as Map<String, dynamic>;

              final questionText = data['question'] ?? 'Sin pregunta';
              final answers = List<String>.from(data['answers'] ?? []);
              final correct = data['correct'] ?? 0;
              final number = data['number'] ?? index + 1;

              return ListTile(
                title: Text('P$number. $questionText'),
                subtitle: Text(
                  'Respuestas: ${answers.length}, Correcta: ${correct + 1}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionFormPage(
                            courseId: courseId,
                            examId: examId,
                            questionId: doc.id,
                            initialQuestion: questionText,
                            initialAnswers: answers,
                            initialCorrect: correct,
                            initialNumber: number, // ✅ nuevo campo
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      testRef.doc(doc.id).delete();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Borrar')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuestionFormPage(
                courseId: courseId,
                examId: examId,
              ),
            ),
          );
        },
      ),
    );
  }
}
