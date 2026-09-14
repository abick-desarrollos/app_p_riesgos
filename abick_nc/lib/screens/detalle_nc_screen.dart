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
      appBar: AppBar(
        title: Text(widget.nc.numero),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con número y estado
          Row(
            children: [
              Expanded(
                child: Text(
                  data['numero'] ?? widget.nc.numero,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _estadoColorMap(data['estado'] ?? widget.nc.estado)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['estado'] ?? widget.nc.estado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _estadoColorMap(
                        data['estado'] ?? widget.nc.estado),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tipo
          _buildDetailRow(
            icon: Icons.category_outlined,
            label: 'Tipo',
            value: data['tipo'] ?? widget.nc.tipo,
          ),
          const SizedBox(height: 16),

          // Proyecto
          _buildDetailRow(
            icon: Icons.business_outlined,
            label: 'Proyecto',
            value: data['proyecto_nombre'] ?? widget.nc.proyectoNombre,
          ),
          const SizedBox(height: 16),

          // Fecha
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: NoConformidad.formatearFecha(data['fecha'] ?? widget.nc.fecha),
          ),
          const SizedBox(height: 16),

          // Ubicación
          if ((data['ubicacion'] as String?)?.isNotEmpty == true) ...[
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: data['ubicacion'],
            ),
            const SizedBox(height: 16),
          ],

          // Responsable
          if ((data['responsable'] as String?)?.isNotEmpty == true) ...[
            _buildDetailRow(
              icon: Icons.person_outlined,
              label: 'Responsable',
              value: data['responsable'],
            ),
            const SizedBox(height: 16),
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
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['descripcion'] ?? widget.nc.descripcion,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Cambiar estado (solo si no está CERRADA)
          if (_siguienteEstado(data['estado'] ?? widget.nc.estado) != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cambiandoEstado ? null : _cambiarEstado,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    : const Text(
                        'Cambiar estado',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

          const SizedBox(height: 24),

          // Sección de fotografías
          _buildFotosSection(),
        ],
      ),
    );
  }

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.photo_camera_back, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Sin fotografías',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotografías (${_fotos.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
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
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
