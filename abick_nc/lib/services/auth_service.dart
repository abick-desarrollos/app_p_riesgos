/// Servicio de autenticación.
///
/// Gestiona el login, el cierre de sesión y el estado
/// de la sesión del usuario.

import '../models/user.dart';
import '../services/api_service.dart';
import '../storage/secure_storage.dart';

class AuthService {
  /// Inicia sesión con las credenciales proporcionadas.
  ///
  /// Devuelve el objeto [User] si las credenciales son correctas.
  /// Lanza [ApiException] si las credenciales son incorrectas
  /// o si hay un error de conexión.
  static Future<User> login(String usuario, String contrasena) async {
    final response = await ApiService.post(
      '/login',
      body: {
        'usuario': usuario,
        'contrasena': contrasena,
      },
    );

    final user = User.fromJson(response);
    final token = response['token'] as String;

    // Guardar token y datos del usuario de forma segura
    await SecureStorage.saveSession(
      token: token,
      userId: user.id,
      nombre: user.nombre,
      usuario: user.usuario,
      rol: user.rol,
      localidadId: user.localidadId,
      localidadNombre: user.localidadNombre,
    );

    return user;
  }

  /// Cierra la sesión actual.
  static Future<void> logout() async {
    await SecureStorage.clearSession();
  }

  /// Verifica si hay una sesión activa.
  static Future<bool> isLoggedIn() async {
    return SecureStorage.hasSession();
  }

  /// Obtiene el usuario autenticado a partir de los datos almacenados.
  static Future<User?> getAuthenticatedUser() async {
    final userId = await SecureStorage.getUserId();
    final nombre = await SecureStorage.getUserName();
    final username = await SecureStorage.getUsername();
    final rol = await SecureStorage.getUserRol();
    final localidadId = await SecureStorage.getUserLocalidadId();
    final localidadNombre = await SecureStorage.getUserLocalidadNombre();

    if (userId == null || nombre == null || username == null || rol == null || localidadId == null || localidadNombre == null) {
      return null;
    }

    return User(
      id: userId,
      nombre: nombre,
      usuario: username,
      rol: rol,
      localidadId: localidadId,
      localidadNombre: localidadNombre,
    );
  }
}
