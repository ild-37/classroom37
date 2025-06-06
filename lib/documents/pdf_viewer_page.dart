import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    final filename = widget.url.split('/').last;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');

    try {
      if (!(await file.exists())) {
        final response = await http.get(Uri.parse(widget.url));
        await file.writeAsBytes(response.bodyBytes);
      }
      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al descargar PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: localPath == null ? null : () {
              // Puedes implementar guardar localmente o compartir
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF descargado en: $localPath')));
            },
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : PDFView(filePath: localPath!),
    );
  }
}
