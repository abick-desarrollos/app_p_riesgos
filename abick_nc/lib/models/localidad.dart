/// Modelo de localidad.

class Localidad {
  final int id;
  final String nombre;

  Localidad({
    required this.id,
    required this.nombre,
  });

  factory Localidad.fromJson(Map<String, dynamic> json) {
    return Localidad(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }
}
