/// Modelo de usuario autenticado.

class User {
  final int id;
  final String nombre;
  final String usuario;
  final String rol;
  final int localidadId;
  final String localidadNombre;

  User({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.localidadId,
    required this.localidadNombre,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      usuario: json['usuario'] as String,
      rol: json['rol'] as String,
      localidadId: json['localidad_id'] as int,
      localidadNombre: json['localidad_nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'usuario': usuario,
      'rol': rol,
      'localidad_id': localidadId,
      'localidad_nombre': localidadNombre,
    };
  }
}
