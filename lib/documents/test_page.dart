import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestPage extends StatefulWidget {
  final String courseId;
  final String examId;
  final String examName;
  final String studentId; // <-- Añadido aquí

  const TestPage({
    Key? key,
    required this.courseId,
    required this.examId,
    required this.examName,
    required this.studentId, // <-- añadido en el constructor
  }) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _questions = [];
  Map<String, int> _selectedAnswers = {};
  bool _loading = true;
  bool _submitted = false;
  int _score = 0;

  late String _userId;
  late String? _userEmail;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
        Navigator.of(context).pop();
      });
      return;
    }
    _userId = user.uid;
    _userEmail = user.email;
    print(
      'TestPage para usuario UID: $_userId, email: $_userEmail, studentId: ${widget.studentId}',
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await _db
          .collection('courses')
          .doc(widget.courseId)
          .collection('exams')
          .doc(widget.examId)
          .collection('test')
          .orderBy('number')
          .get();

      setState(() {
        _questions = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando preguntas: $e')));
    }
  }

  Future<void> _saveScore(double scoreOutOf10) async {
    final String courseId = widget.courseId;
    final String examId = widget.examId;

    try {
      // Guardar nota en /users/{userId}/courses/{courseId}/exams/{examId}
      await _db
          .collection('users')
          .doc(_userId)
          .collection('courses')
          .doc(courseId)
          .collection('exams')
          .doc(examId)
          .set({
            'score': scoreOutOf10,
            'email': _userEmail,
          }, SetOptions(merge: true));

      // Guardar nota en /courses/{courseId}/exams/{examId}/students/{userId}
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('exams')
          .doc(examId)
          .collection('students')
          .doc(_userId)
          .set({
            'score': scoreOutOf10,
            'email': _userEmail,
          }, SetOptions(merge: true));

      print('Nota guardada correctamente: $scoreOutOf10');
    } catch (e) {
      print('Error guardando nota: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando nota: $e')));
    }
  }

  void _submitTest() async {
    int score = 0;
    for (var question in _questions) {
      final String qId = question['id'];
      final correctIndex = question['correct'];
      if (_selectedAnswers[qId] == correctIndex) {
        score++;
      }
    }

    double scoreOutOf10 = (_questions.isNotEmpty)
        ? (score / _questions.length) * 10
        : 0;

    setState(() {
      _score = score;
      _submitted = true;
    });

    await _saveScore(scoreOutOf10);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_submitted) {
      double scoreOutOf10 = (_questions.isNotEmpty)
          ? (_score / _questions.length) * 10
          : 0;

      return Scaffold(
        appBar: AppBar(title: Text(widget.examName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Has terminado el examen.'),
              Text('Puntuación: $_score / ${_questions.length}'),
              Text('Nota sobre 10: ${scoreOutOf10.toStringAsFixed(2)}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.examName)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length + 1,
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: _selectedAnswers.length == _questions.length
                    ? _submitTest
                    : null,
                child: const Text('Terminar'),
              ),
            );
          }

          final question = _questions[index];
          final qId = question['id'] as String;
          final questionText = question['question'] as String;
          final answers = List<String>.from(question['answers']);
          final questionNumber = question['number'] as int? ?? index;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pregunta ${questionNumber + 1}: $questionText',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.generate(answers.length, (i) {
                    return RadioListTile<int>(
                      title: Text(answers[i]),
                      value: i,
                      groupValue: _selectedAnswers[qId],
                      onChanged: (value) {
                        setState(() {
                          _selectedAnswers[qId] = value!;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
