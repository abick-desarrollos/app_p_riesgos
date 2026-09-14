import 'package:flutter/material.dart';
import '../models/fotografia.dart';

/// Pantalla para visualizar una fotografía a tamaño completo.

class FotoVisualizarScreen extends StatelessWidget {
  final Fotografia foto;
  final String baseUrl;

  const FotoVisualizarScreen({
    super.key,
    required this.foto,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotografía'),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            foto.urlCompleta(baseUrl),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
