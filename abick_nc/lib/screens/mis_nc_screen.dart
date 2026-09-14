import 'package:flutter/material.dart';
import '../models/no_conformidad.dart';
import '../services/api_service.dart';
import 'detalle_nc_screen.dart';

/// Pantalla que muestra la lista de no conformidades del usuario.
///
/// Realiza GET /no-conformidades y muestra:
/// - indicador de carga mientras obtiene datos
/// - mensaje de error con botón de reintentar
/// - lista vacía cuando no hay NC registradas
/// - detalle de cada NC al tocarla

class MisNoConformidadesScreen extends StatefulWidget {
  const MisNoConformidadesScreen({super.key});

  @override
  State<MisNoConformidadesScreen> createState() =>
      _MisNoConformidadesScreenState();
}

class _MisNoConformidadesScreenState extends State<MisNoConformidadesScreen> {
  List<NoConformidad> _ncs = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNc();
  }

  Future<void> _cargarNc() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await ApiService.get('/no-conformidades');
      if (mounted) {
        final lista = (data as List)
            .map((e) => NoConformidad.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _ncs = lista;
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudieron cargar las NC: ${e.message}';
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
                // Listado
                Expanded(
                  child: _buildBody(),
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
          // Título centrado
          Expanded(
            child: Text(
              'Mis No Conformidades',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
                onPressed: _cargarNc,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ncs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              Text(
                'No hay no conformidades registradas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _ncs.length,
      itemBuilder: (context, index) {
        final nc = _ncs[index];
        return _buildNcCard(nc);
      },
    );
  }

  // ---- NC CARD ----

  Widget _buildNcCard(NoConformidad nc) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white.withValues(alpha: 0.82),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetalleNoConformidadScreen(nc: nc),
            ),
          );
          if (changed == true && mounted) {
            _cargarNc();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Indicador lateral de estado
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _estadoColorMap(nc.estado),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nc.numero,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nc.tipo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Localidad: ${nc.localidadNombre}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              // Fecha y estado badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nc.fechaFormateada,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _estadoColorMap(nc.estado).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nc.estado,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _estadoColorMap(nc.estado),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
