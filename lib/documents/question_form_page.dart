import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionFormPage extends StatefulWidget {
  final String courseId;
  final String examId;
  final String? questionId;
  final String? initialQuestion;
  final List<String>? initialAnswers;
  final int? initialCorrect;
  final int? initialNumber;

  const QuestionFormPage({
    Key? key,
    required this.courseId,
    required this.examId,
    this.questionId,
    this.initialQuestion,
    this.initialAnswers,
    this.initialCorrect,
    this.initialNumber,
  }) : super(key: key);

  @override
  _QuestionFormPageState createState() => _QuestionFormPageState();
}

class _QuestionFormPageState extends State<QuestionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late List<TextEditingController> _answerControllers;
  int _correctIndex = 0;

  bool get isEditing => widget.questionId != null;

  @override
  void initState() {
    super.initState();

    _questionController = TextEditingController(
      text: widget.initialQuestion ?? '',
    );
    _answerControllers = List.generate(
      4,
      (index) => TextEditingController(
        text:
            (widget.initialAnswers != null &&
                widget.initialAnswers!.length > index)
            ? widget.initialAnswers![index]
            : '',
      ),
    );
    _correctIndex = widget.initialCorrect ?? 0;
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      final testRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('exams')
          .doc(widget.examId)
          .collection('test');

      try {
        if (isEditing) {
          final existingDoc = await testRef.doc(widget.questionId).get();
          final existingNumber = existingDoc.data()?['number'] ?? 0;

          final data = {
            'question': _questionController.text.trim(),
            'answers': _answerControllers.map((c) => c.text.trim()).toList(),
            'correct': _correctIndex,
            'number': existingNumber, // conserva el número
          };

          await testRef.doc(widget.questionId).update(data);
        } else {
          final snapshot = await testRef.get();
          final questionNumber = snapshot.docs.length + 1;

          final data = {
            'question': _questionController.text.trim(),
            'answers': _answerControllers.map((c) => c.text.trim()).toList(),
            'correct': _correctIndex,
            'number': questionNumber, // asigna nuevo número
          };

          await testRef.add(data);
        }

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar pregunta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Pregunta' : 'Nueva Pregunta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Pregunta'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce la pregunta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) {
                return TextFormField(
                  controller: _answerControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Respuesta ${index + 1}',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Introduce esta respuesta';
                    }
                    return null;
                  },
                );
              }),
              const SizedBox(height: 16),
              Text('Respuesta correcta:'),
              DropdownButton<int>(
                value: _correctIndex,
                items: List.generate(
                  4,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Respuesta ${index + 1}'),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _correctIndex = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveQuestion,
                child: Text(
                  isEditing ? 'Actualizar pregunta' : 'Crear pregunta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
