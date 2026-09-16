import 'package:flutter/material.dart';
import '../models/fotografia.dart';
import '../models/no_conformidad.dart';
import '../screens/foto_visualizar_screen.dart';
import '../services/api_service.dart';

/// Pantalla de detalle de una no conformidad.
///
/// Muestra toda la información de la NC obtenida
/// de GET /no-conformidades/:id.

class DetalleNoConformidadScreen extends StatefulWidget {
  final NoConformidad nc;

  const DetalleNoConformidadScreen({super.key, required this.nc});

  @override
  State<DetalleNoConformidadScreen> createState() =>
      _DetalleNoConformidadScreenState();
}

class _DetalleNoConformidadScreenState
    extends State<DetalleNoConformidadScreen> {
  Map<String, dynamic>? _detalle;
  bool _cargando = true;
  bool _cambiandoEstado = false;
  String? _error;

  // Fotos
  List<Fotografia> _fotos = [];
  bool _fotosCargando = false;
  String? _fotosError;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data =
          await ApiService.get('/no-conformidades/${widget.nc.id}');
      if (mounted) {
        setState(() {
          _detalle = data as Map<String, dynamic>;
          _cargando = false;
        });
        _cargarFotos();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo cargar el detalle: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo conectar con el servidor';
        });
      }
    }
  }

  Future<void> _cargarFotos() async {
    setState(() {
      _fotosCargando = true;
      _fotosError = null;
    });

    try {
      final data = await ApiService.get(
        '/no-conformidades/${widget.nc.id}/fotos',
      );
      if (mounted) {
        final fotosList = data['fotografias'] as List;
        setState(() {
          _fotos = fotosList
              .map((e) => Fotografia.fromJson(e as Map<String, dynamic>))
              .toList();
          _fotosCargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _fotosCargando = false;
          _fotosError = 'No se pudo cargar las fotografías: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fotosCargando = false;
          _fotosError = 'No se pudo conectar con el servidor';
        });
      }
    }
  }

  Color _estadoColorMap(String estado) {
    switch (estado.toUpperCase()) {
      case 'NUEVA':
        return Colors.blue;
      case 'EN PROCESO':
        return Colors.orange;
      case 'CERRADA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String? _siguienteEstado(String estadoActual) {
    switch (estadoActual.toUpperCase()) {
      case 'NUEVA':
        return 'EN PROCESO';
      case 'EN PROCESO':
        return 'CERRADA';
      case 'CERRADA':
        return null;
      default:
        return null;
    }
  }

  Future<void> _cambiarEstado() async {
    final estadoActual = _detalle?['estado'] ?? widget.nc.estado;
    final siguiente = _siguienteEstado(estadoActual);
    if (siguiente == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Text(
          '¿Desea cambiar el estado de "$estadoActual" a "$siguiente"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _cambiandoEstado = true;
      _error = null;
    });

    try {
      final estadoMap = {
        'NUEVA': 1,
        'EN PROCESO': 2,
        'CERRADA': 3,
      };
      await ApiService.put(
        '/no-conformidades/${widget.nc.id}/estado',
        body: {'estado_id': estadoMap[siguiente]},
      );

      if (mounted) {
        setState(() {
          _cambiandoEstado = false;
        });
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cambiandoEstado = false;
          _error = 'No se pudo cambiar el estado: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cambiandoEstado = false;
          _error = 'No se pudo conectar con el servidor';
        });
      }
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
            child: Column(
              children: [
                // Header transparente
                _buildHeader(),
                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- HEADER ----

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // Flecha de regreso blanca
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          // Título centrado con número de NC
          Expanded(
            child: Text(
              '${widget.nc.numero} — ${widget.nc.titulo ?? 'Sin título'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Espacio simétrico para centrar el título
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ---- BODY ----

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarDetalle,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Usar datos del modelo si no se cargó detalle adicional
    final data = _detalle ?? widget.nc.toJson();
    final estado = data['estado'] ?? widget.nc.estado;
    final estadoColor = _estadoColorMap(estado);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta principal translúcida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado NC: número + badge estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['numero'] ?? widget.nc.numero,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estadoColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Título
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.title_outlined, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['titulo'] ?? widget.nc.titulo,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tipo
                _buildDetailRow(
                  icon: Icons.category_outlined,
                  label: 'Tipo',
                  value: data['tipo'] ?? widget.nc.tipo,
                ),
                const SizedBox(height: 14),

                // Proyecto
                _buildDetailRow(
                  icon: Icons.business_outlined,
                  label: 'Proyecto',
                  value: data['proyecto_nombre'] ?? widget.nc.proyectoNombre,
                ),
                const SizedBox(height: 14),

                // Fecha
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: NoConformidad.formatearFecha(
                    data['fecha'] ?? widget.nc.fecha,
                  ),
                ),
                const SizedBox(height: 14),

                // Ubicación (opcional)
                if ((data['ubicacion'] as String?)?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Ubicación',
                    value: data['ubicacion'],
                  ),
                  const SizedBox(height: 14),
                ],

                // Responsable (opcional)
                if ((data['responsable'] as String?)?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: Icons.person_outlined,
                    label: 'Responsable',
                    value: data['responsable'],
                  ),
                  const SizedBox(height: 14),
                ],

                // Descripción
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['descripcion'] ?? widget.nc.descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Cambiar estado (solo si no está CERRADA)
                if (_siguienteEstado(estado) != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cambiandoEstado ? null : _cambiarEstado,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _cambiandoEstado
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Cambiar estado'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sección de fotografías
          _buildFotosSection(),
        ],
      ),
    );
  }

  // ---- FOTOS SECTION ----

  Widget _buildFotosSection() {
    if (_fotosCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_fotosError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fotosError!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _cargarFotos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_fotos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back, color: Colors.blue.shade300),
            const SizedBox(width: 8),
            Text(
              'Sin fotografías',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fotografías (${_fotos.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _fotos.length,
            itemBuilder: (context, index) {
              final foto = _fotos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FotoVisualizarScreen(
                        foto: foto,
                        baseUrl: ApiService.baseUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      foto.urlCompleta(ApiService.baseUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---- DETAIL ROW ----

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
