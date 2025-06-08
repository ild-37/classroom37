import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentFormPage extends StatefulWidget {
  final String courseId;
  final String? documentId; // null para agregar, no null para editar
  final String? initialName;
  final String? initialRoute;

  const DocumentFormPage({
    super.key,
    required this.courseId,
    this.documentId,
    this.initialName,
    this.initialRoute,
  });

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _routeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _routeController = TextEditingController(text: widget.initialRoute ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final docData = {
      'name': _nameController.text.trim(),
      'route': _routeController.text.trim(),
    };

    final documentsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('documents');

    try {
      if (widget.documentId == null) {
        // Crear nuevo documento con ID automático
        await documentsRef.add(docData);
      } else {
        // Actualizar documento existente
        await documentsRef.doc(widget.documentId).update(docData);
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar éxito
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar documento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.documentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Documento' : 'Agregar Documento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce un nombre' : null,
              ),
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(labelText: 'URL o ruta'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce una URL o ruta' : null,
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveDocument,
                      child: Text(isEditing ? 'Guardar cambios' : 'Agregar documento'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
