class Fotografia {
  final int id;
  final int noConformidadId;
  final String archivoPath;
  final String createdAt;

  Fotografia({
    required this.id,
    required this.noConformidadId,
    required this.archivoPath,
    required this.createdAt,
  });

  factory Fotografia.fromJson(Map<String, dynamic> json) {
    return Fotografia(
      id: json['id'] as int,
      noConformidadId: json['no_conformidad_id'] as int,
      archivoPath: json['archivo_path'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  /// Devuelve la URL completa de la fotografía.
  String urlCompleta(String baseUrl) {
    return '$baseUrl/$archivoPath';
  }
}
