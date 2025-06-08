import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<int> _generateUniqueCode() async {
    final random = Random();
    int code;
    bool exists;

    do {
      code = 1000 + random.nextInt(9000);
      final query = await _db
          .collection('courses')
          .where('cd', isEqualTo: code)
          .limit(1)
          .get();
      exists = query.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final masterEmail = _auth.currentUser?.email;

    if (masterEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido obtener el usuario.')),
      );
      return;
    }

    try {
      final code = await _generateUniqueCode();

      final courseRef = _db.collection('courses').doc();

      await courseRef.set({
        'id': courseRef.id,
        'name': name,
        'description': description,
        'cd': code,
        'master': masterEmail,
      });

      // Crear colecciones vacías para documentos y exámenes (opcional)
      await courseRef.collection('documents').doc('init').set({});
      await courseRef.collection('exams').doc('init').set({});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso creado correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear el curso: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del curso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce un nombre'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce una descripción'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _createCourse,
                child: const Text('Crear curso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
