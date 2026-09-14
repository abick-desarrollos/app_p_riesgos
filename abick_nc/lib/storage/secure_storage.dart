/// Almacenamiento seguro de tokens usando flutter_secure_storage.
///
/// El JWT se almacena en el almacenamiento seguro del sistema
/// operativo (Keychain en iOS, Keystore en Android).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = const FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUsername = 'user_username';
  static const _keyUserRol = 'user_rol';
  static const _keyUserLocalidadId = 'user_localidad_id';
  static const _keyUserLocalidadNombre = 'user_localidad_nombre';

  /// Guarda el token JWT y los datos del usuario.
  static Future<void> saveSession({
    required String token,
    required int userId,
    required String nombre,
    required String usuario,
    required String rol,
    required int localidadId,
    required String localidadNombre,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyUserName, value: nombre);
    await _storage.write(key: _keyUsername, value: usuario);
    await _storage.write(key: _keyUserRol, value: rol);
    await _storage.write(key: _keyUserLocalidadId, value: localidadId.toString());
    await _storage.write(key: _keyUserLocalidadNombre, value: localidadNombre);
  }

  /// Obtiene el token JWT almacenado.
  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  /// Obtiene el ID del usuario almacenado.
  static Future<int?> getUserId() async {
    final value = await _storage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Obtiene el nombre del usuario almacenado.
  static Future<String?> getUserName() async {
    return _storage.read(key: _keyUserName);
  }

  /// Obtiene el nombre de usuario almacenado.
  static Future<String?> getUsername() async {
    return _storage.read(key: _keyUsername);
  }

  /// Obtiene el rol del usuario almacenado.
  static Future<String?> getUserRol() async {
    return _storage.read(key: _keyUserRol);
  }

  /// Obtiene el ID de localidad del usuario almacenado.
  static Future<int?> getUserLocalidadId() async {
    final value = await _storage.read(key: _keyUserLocalidadId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Obtiene el nombre de localidad del usuario almacenado.
  static Future<String?> getUserLocalidadNombre() async {
    return _storage.read(key: _keyUserLocalidadNombre);
  }

  /// Elimina toda la sesión (cierre de sesión).
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyUserRol);
    await _storage.delete(key: _keyUserLocalidadId);
    await _storage.delete(key: _keyUserLocalidadNombre);
  }

  /// Verifica si existe una sesión activa.
  static Future<bool> hasSession() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }
}
