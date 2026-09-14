/// Configuración de la aplicación ABICK NC.
///
/// La URL de la API se configura aquí para facilitar su
/// modificación entre entornos (desarrollo, staging, producción).
class AppConfig {
  /// URL de la API en modo desarrollo.
  ///
  /// Cambiar esta URL según el entorno:
  /// - Desarrollo local:  http://192.168.1.181:8080
  /// - Desarrollo remoto:  http://192.168.1.82:8080
  /// - Producción:        https://api.abick.com
  static const String apiBaseUrl = 'http://10.0.2.2:8080';
}
