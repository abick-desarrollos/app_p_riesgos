/// Modelo de proyecto / área.

class Proyecto {
  final int id;
  final String nombre;
  final String? descripcion;
  final int localidadId;
  final bool activo;

  Proyecto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.localidadId,
    required this.activo,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    final activoRaw = json['activo'];
    final activo = activoRaw is bool
        ? activoRaw
        : activoRaw == 1 || activoRaw == true;

    return Proyecto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      localidadId: json['localidad_id'] as int? ?? 0,
      activo: activo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'localidad_id': localidadId,
      'activo': activo,
    };
  }
}
