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

  // Búsqueda y filtro
  final _buscarController = TextEditingController();
  int? _estadoFilter; // null = Todos, 1 = NUEVA, 2 = EN PROCESO, 3 = CERRADA
  bool _filtroActivo = false;

  @override
  void initState() {
    super.initState();
    _cargarNc();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  String _getQueryParams() {
    final params = <String>[];
    final q = _buscarController.text.trim();
    if (q.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(q)}');
    }
    if (_estadoFilter != null) {
      params.add('estado_id=$_estadoFilter');
    }
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  Future<void> _cargarNc() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final query = _getQueryParams();
      final data = await ApiService.get('/no-conformidades$query');
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
          _error = 'Error del servidor: ${e.message}';
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error al procesar los datos: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error inesperado: $e';
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filtroActivo = value.trim().isNotEmpty || _estadoFilter != null;
    });
    // Debounce simple: recargar al detener de escribir
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cargarNc();
    });
  }

  void _onEstadoFilterChanged(int? value) {
    setState(() {
      _estadoFilter = value;
      _filtroActivo = _buscarController.text.trim().isNotEmpty || value != null;
    });
    _cargarNc();
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

    return Column(
      children: [
        _buildSearchAndFilter(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _ncs.length,
            itemBuilder: (context, index) {
              final nc = _ncs[index];
              return _buildNcCard(nc);
            },
          ),
        ),
      ],
    );
  }

  // ---- SEARCH AND FILTER BAR ----

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _buscarController,
            decoration: _inputDecoration(
              labelText: 'Buscar por título o número...',
              prefixIcon: Icons.search,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          // Estado filter — horizontal chips
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEstadoChip(null, 'Todos'),
                            const SizedBox(width: 6),
                            _buildEstadoChip(1, 'Nueva'),
                            const SizedBox(width: 6),
                            _buildEstadoChip(2, 'En proceso'),
                            const SizedBox(width: 6),
                            _buildEstadoChip(3, 'Cerrada'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_filtroActivo)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _buscarController.clear();
                      _estadoFilter = null;
                      _filtroActivo = false;
                    });
                    _cargarNc();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- INPUT DECORATION ----

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: Colors.blue.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // ---- ESTADO CHIP ----

  Widget _buildEstadoChip(int? estadoId, String label) {
    final isSelected = _estadoFilter == estadoId;
    return GestureDetector(
      onTap: () => _onEstadoFilterChanged(isSelected ? null : estadoId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
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
                    // Título como elemento visual principal
                    Text(
                      nc.titulo ?? 'Sin título',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nc.numero} · ${nc.tipo}',
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
