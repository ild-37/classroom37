import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestPage extends StatefulWidget {
  final String courseId;
  final String examId;
  final String examName;

  const TestPage({
    super.key,
    required this.courseId,
    required this.examId,
    required this.examName,
  });

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Map<String, int> selectedAnswers = {}; // idPregunta -> índice seleccionado

  @override
  Widget build(BuildContext context) {
    final testRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('exams')
        .doc(widget.examId)
        .collection('test')
        .orderBy('number'); // Ordenamos por 'number'

    return Scaffold(
      appBar: AppBar(title: Text(widget.examName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: testRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final questions = snapshot.data!.docs;

          if (questions.isEmpty) {
            return const Center(
              child: Text('No hay preguntas en este examen.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...questions.map((q) {
                final data = q.data() as Map<String, dynamic>;
                final questionId = q.id;
                final questionNumber = data['number'] ?? '?';
                final question = data['question'] ?? 'Sin pregunta';
                final answers = List<String>.from(data['answers'] ?? []);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pregunta $questionNumber: $question',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(answers.length, (i) {
                          return RadioListTile<int>(
                            title: Text(answers[i]),
                            value: i,
                            groupValue: selectedAnswers[questionId],
                            onChanged: (value) {
                              setState(() {
                                selectedAnswers[questionId] = value!;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  int correct = 0;
                  for (var q in questions) {
                    final data = q.data() as Map<String, dynamic>;
                    final correctIndex = data['correct'];
                    final selected = selectedAnswers[q.id];
                    if (selected != null && selected == correctIndex) {
                      correct++;
                    }
                  }

                  final score = (correct / questions.length) * 10;
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario no autenticado')),
                    );
                    return;
                  }

                  final studentId = user.uid;
                  final firestore = FirebaseFirestore.instance;

                  try {
                    // Guardar en ruta pública del examen
                    await firestore
                        .collection('courses')
                        .doc(widget.courseId)
                        .collection('exams')
                        .doc(widget.examId)
                        .collection('students')
                        .doc(studentId)
                        .set({
                          'qualification': score,
                          'completed': true,
                        }, SetOptions(merge: true));

                    // Guardar en ruta privada del usuario
                    await firestore
                        .collection('users')
                        .doc(studentId)
                        .collection('courses')
                        .doc(widget.courseId)
                        .collection('exams')
                        .doc(widget.examId)
                        .set({
                          'qualification': score,
                          'completed': true,
                        }, SetOptions(merge: true));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error guardando resultado: $e')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Resultado"),
                      content: Text(
                        "Respuestas correctas: $correct de ${questions.length}\nNota: ${score.toStringAsFixed(2)} / 10",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("Terminar examen"),
              ),
            ],
          );
        },
      ),
    );
  }
}
