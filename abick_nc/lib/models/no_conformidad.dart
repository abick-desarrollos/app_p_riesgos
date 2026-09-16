/// Modelo de no conformidad.

class NoConformidad {
  final int id;
  final String numero;
  final String? titulo;
  final int proyectoId;
  final String proyectoNombre;
  final String tipo;
  final String fecha;
  final String? ubicacion;
  final String? responsable;
  final String descripcion;
  final String estado;
  final int localidadId;
  final String localidadNombre;

  NoConformidad({
    required this.id,
    required this.numero,
    this.titulo,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.tipo,
    required this.fecha,
    required this.ubicacion,
    required this.responsable,
    required this.descripcion,
    required this.estado,
    required this.localidadId,
    required this.localidadNombre,
  });

  factory NoConformidad.fromJson(Map<String, dynamic> json) {
    return NoConformidad(
      id: json['id'] as int,
      numero: json['numero'] as String,
      titulo: json['titulo'] as String?,
      proyectoId: json['proyecto_id'] as int,
      proyectoNombre: json['proyecto_nombre'] as String,
      tipo: json['tipo'] as String,
      fecha: json['fecha'] as String,
      ubicacion: json['ubicacion'] as String?,
      responsable: json['responsable'] as String?,
      descripcion: json['descripcion'] as String,
      estado: json['estado'] as String,
      localidadId: json['localidad_id'] as int,
      localidadNombre: json['localidad_nombre'] as String,
    );
  }

  /// Formatea la fecha del API (YYYY-MM-DD o ISO 8601) como dd/MM/yyyy.
  String get fechaFormateada {
    final datePart = fecha.split('T').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return fecha;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  /// Formatea una fecha string (YYYY-MM-DD o ISO 8601) como dd/MM/yyyy.
  static String formatearFecha(String fecha) {
    final datePart = fecha.split('T').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return fecha;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'titulo': titulo,
      'proyecto_id': proyectoId,
      'proyecto_nombre': proyectoNombre,
      'tipo': tipo,
      'fecha': fecha,
      'ubicacion': ubicacion,
      'responsable': responsable,
      'descripcion': descripcion,
      'estado': estado,
      'localidad_id': localidadId,
      'localidad_nombre': localidadNombre,
    };
  }
}
