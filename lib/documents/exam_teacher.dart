import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_editor_page.dart';

class ExamFormPage extends StatefulWidget {
  final String courseId;
  final String? examId; // null para crear, no null para editar
  final String? initialName;

  const ExamFormPage({
    Key? key,
    required this.courseId,
    this.examId,
    this.initialName,
  }) : super(key: key);

  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool get isEditing => widget.examId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
  }

  Future<void> _saveExam() async {
    if (_formKey.currentState!.validate()) {
      final examsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('exams');

      final data = {
        'name': _nameController.text.trim(),
        // Puedes añadir otros campos aquí
      };

      try {
        if (isEditing) {
          await examsRef.doc(widget.examId).update(data);
        } else {
          await examsRef.add(data);
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar examen: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Examen' : 'Nuevo Examen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del examen',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExam,
                child: Text(isEditing ? 'Actualizar' : 'Crear'),
              ),

              // Solo mostramos botón de gestionar test si el examen ya existe (modo edición)
              if (isEditing) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.quiz),
                  label: const Text('Gestionar Test'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestEditorPage(
                          courseId: widget.courseId,
                          examId: widget.examId!,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
