import 'package:flutter/material.dart';
import '../models/localidad.dart';
import '../models/proyecto.dart';
import '../services/api_service.dart';

/// Pantalla de administración de proyectos.
///
/// Solo visible para usuarios con rol admin.
/// Muestra la lista de todos los proyectos (incluyendo inactivos)
/// y permite crear, editar y activar/desactivar proyectos.

class AdministrarProyectosScreen extends StatefulWidget {
  const AdministrarProyectosScreen({super.key});

  @override
  State<AdministrarProyectosScreen> createState() =>
      _AdministrarProyectosScreenState();
}

class _AdministrarProyectosScreenState
    extends State<AdministrarProyectosScreen> {
  List<Proyecto> _proyectos = [];
  List<Localidad> _localidades = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final proyectosData = await ApiService.get('/proyectos');
      final localidadesData = await ApiService.get('/localidades');

      if (mounted) {
        setState(() {
          _proyectos = (proyectosData as List)
              .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
              .toList();
          _localidades = (localidadesData as List)
              .map((e) => Localidad.fromJson(e as Map<String, dynamic>))
              .toList();
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error al cargar datos: ${e.message}';
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

  void _mostrarFormulario({Proyecto? proyecto}) {
    final esEdicion = proyecto != null;
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: esEdicion ? proyecto.nombre : '');
    final descripcionController = TextEditingController(
      text: esEdicion ? (proyecto.descripcion ?? '') : '',
    );
    Localidad? localidadSeleccionada;

    if (_localidades.isNotEmpty) {
      if (esEdicion) {
        localidadSeleccionada = _localidades.firstWhere(
          (l) => l.id == proyecto.localidadId,
          orElse: () => _localidades.first,
        );
      } else {
        localidadSeleccionada = _localidades.first;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    esEdicion ? 'Editar Proyecto' : 'Nuevo Proyecto',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Nombre
                  TextFormField(
                    controller: nombreController,
                    decoration: _inputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icons.business_outlined,
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Ingrese el nombre del proyecto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción (opcional)
                  TextFormField(
                    controller: descripcionController,
                    decoration: _inputDecoration(
                      labelText: 'Descripción (opcional)',
                      prefixIcon: Icons.description_outlined,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Localidad
                  DropdownButtonFormField<Localidad>(
                    initialValue: localidadSeleccionada,
                    decoration: _inputDecoration(
                      labelText: 'Localidad *',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                    items: _localidades.map((loc) {
                      return DropdownMenuItem(
                        value: loc,
                        child: Text(loc.nombre),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      localidadSeleccionada = valor;
                    },
                    validator: (value) {
                      if (value == null) return 'Seleccione una localidad';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (localidadSeleccionada == null) return;

                            Navigator.of(context).pop();

                            try {
                              if (esEdicion) {
                                await ApiService.put(
                                  '/proyectos/${proyecto.id}',
                                  body: {
                                    'nombre': nombreController.text.trim(),
                                    'descripcion':
                                        descripcionController.text.trim().isEmpty
                                            ? null
                                            : descripcionController.text.trim(),
                                    'localidad_id': localidadSeleccionada!.id,
                                  },
                                );
                              } else {
                                await ApiService.post(
                                  '/proyectos',
                                  body: {
                                    'nombre': nombreController.text.trim(),
                                    'descripcion':
                                        descripcionController.text.trim().isEmpty
                                            ? null
                                            : descripcionController.text.trim(),
                                    'localidad_id': localidadSeleccionada!.id,
                                  },
                                );
                              }

                              if (mounted) {
                                _cargarDatos();
                              }
                            } on ApiException catch (e) {
                              if (mounted) {
                                _mostrarError('Error al guardar: ${e.message}');
                              }
                            } catch (_) {
                              if (mounted) {
                                _mostrarError(
                                    'No se pudo conectar con el servidor');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(esEdicion ? 'Guardar' : 'Crear'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActivo(Proyecto proyecto) async {
    try {
      await ApiService.put(
        '/proyectos/${proyecto.id}',
        body: {'activo': !proyecto.activo},
      );
      if (mounted) {
        setState(() {
          final index = _proyectos.indexOf(proyecto);
          if (index != -1) {
            _proyectos[index] = Proyecto(
              id: proyecto.id,
              nombre: proyecto.nombre,
              descripcion: proyecto.descripcion,
              localidadId: proyecto.localidadId,
              activo: !proyecto.activo,
            );
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        _mostrarError('Error al cambiar estado: ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        _mostrarError('No se pudo conectar con el servidor');
      }
    }
  }

  String _nombreLocalidad(int localidadId) {
    final loc = _localidades.firstWhere(
      (l) => l.id == localidadId,
      orElse: () => Localidad(id: 0, nombre: ''),
    );
    return loc.nombre;
  }

  Color _activoColor(bool activo) {
    return activo ? Colors.green : Colors.red;
  }

  String _activoTexto(bool activo) {
    return activo ? 'Activo' : 'Inactivo';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Crear proyecto'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
              'Administrar Proyectos',
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
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_proyectos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined,
                  size: 48, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              Text(
                'No hay proyectos registrados',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Presiona el botón + para crear uno',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _proyectos.length,
      itemBuilder: (context, index) {
        final proyecto = _proyectos[index];
        return _buildProyectoCard(proyecto);
      },
    );
  }

  // ---- PROYECTO CARD ----

  Widget _buildProyectoCard(Proyecto proyecto) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white.withValues(alpha: 0.82),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarFormulario(proyecto: proyecto),
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
                  color: _activoColor(proyecto.activo),
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
                      proyecto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _nombreLocalidad(proyecto.localidadId),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _activoColor(proyecto.activo).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _activoTexto(proyecto.activo),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _activoColor(proyecto.activo),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón activar/desactivar
              IconButton(
                icon: Icon(
                  proyecto.activo
                      ? Icons.toggle_on
                      : Icons.toggle_off,
                  color: _activoColor(proyecto.activo),
                ),
                onPressed: () => _toggleActivo(proyecto),
                tooltip: proyecto.activo ? 'Desactivar' : 'Activar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- DECORACIÓN CONSISTENTE PARA CAMPOS ----

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
