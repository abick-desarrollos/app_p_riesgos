import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../storage/secure_storage.dart';
import 'administrar_proyectos_screen.dart';
import 'login_screen.dart';
import 'nueva_nc_screen.dart';
import 'mis_nc_screen.dart';

/// Pantalla Home de ABICK NC.
///
/// Muestra el nombre de la aplicación, el usuario
/// autenticado y las dos acciones principales:
/// registrar una nueva no conformidad o ver las
/// existentes.

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
      appBar: AppBar(
        title: const Text('ABICK NC'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SingleChildScrollView(
            child: Column(
              children: [
              // Nombre de la aplicación
              const Text(
                'ABICK NC',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),

              // Nombre del usuario autenticado
              FutureBuilder<String?>(
                future: SecureStorage.getUserName(),
                builder: (context, snapshot) {
                  final nombre = snapshot.data ?? '';
                  return Text(
                    'Bienvenido, $nombre',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),

              // Localidad del usuario
              FutureBuilder<String?>(
                future: SecureStorage.getUserLocalidadNombre(),
                builder: (context, snapshot) {
                  final locNombre = snapshot.data;
                  return Text(
                    locNombre != null && locNombre.isNotEmpty
                        ? 'Localidad: $locNombre'
                        : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Tarjeta "Nueva No Conformidad"
              _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Nueva No Conformidad',
                subtitle: 'Registrar una nueva no conformidad',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NuevaNoConformidadScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tarjeta "Mis No Conformidades"
              _buildActionCard(
                icon: Icons.list,
                title: 'Mis No Conformidades',
                subtitle: 'Ver las no conformidades registradas',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MisNoConformidadesScreen(),
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
                    subtitle: 'Gestionar proyectos y localidades',
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
              // Botón de cerrar sesión
              TextButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Cerrar sesión'),
                onPressed: _cerrarSesion,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
