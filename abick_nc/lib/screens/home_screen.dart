import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../storage/secure_storage.dart';
import 'administrar_proyectos_screen.dart';
import 'login_screen.dart';
import 'nueva_nc_screen.dart';
import 'mis_nc_screen.dart';

/// Pantalla Home de ABICK NC.
///
/// Muestra el usuario autenticado, su localidad
/// y las acciones principales: registrar una
/// nueva no conformidad, ver las existentes o
/// gestionar proyectos (administradores).

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _cerrarSesion() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/imagen app riesgos.jpeg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Capa azul sutil para mejorar legibilidad
          Positioned.fill(
            child: Container(
              color: Colors.blue.withValues(alpha: 0.35),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        child: Column(
                          children: [
                            // HEADER
                            _buildHeader(),
                            const SizedBox(height: 32),

                            // Tarjeta "Nueva No Conformidad"
                            _buildActionCard(
                              icon: Icons.add_circle_outline,
                              title: 'Nueva No Conformidad',
                              subtitle:
                                  'Registrar una nueva no conformidad',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NuevaNoConformidadScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tarjeta "Mis No Conformidades"
                            _buildActionCard(
                              icon: Icons.list,
                              title: 'Mis No Conformidades',
                              subtitle:
                                  'Ver las no conformidades registradas',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MisNoConformidadesScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tarjeta "Administrar Proyectos" (solo admin)
                            FutureBuilder<String?>(
                              future: SecureStorage.getUserRol(),
                              builder: (context, snapshot) {
                                final rol = snapshot.data;
                                if (rol != 'admin') {
                                  return const SizedBox.shrink();
                                }
                                return _buildActionCard(
                                  icon: Icons.settings_outlined,
                                  title: 'Administrar Proyectos',
                                  subtitle:
                                      'Gestionar proyectos y localidades',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdministrarProyectosScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Botón de cerrar sesión
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.logout,
                                      size: 20, color: Colors.red),
                                  label: const Text('Cerrar sesión',
                                      style: TextStyle(
                                          color: Colors.red)),
                                  onPressed: _cerrarSesion,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Bienvenido" + nombre en dos líneas
          FutureBuilder<String?>(
            future: SecureStorage.getUserName(),
            builder: (context, snapshot) {
              final nombre = snapshot.data ?? '';
              return Column(
                children: [
                  Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Localidad dinámica
          FutureBuilder<String?>(
            future: SecureStorage.getUserLocalidadNombre(),
            builder: (context, snapshot) {
              final locNombre = snapshot.data;
              return Text(
                locNombre != null && locNombre.isNotEmpty
                    ? locNombre
                    : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withValues(alpha: 0.82),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
