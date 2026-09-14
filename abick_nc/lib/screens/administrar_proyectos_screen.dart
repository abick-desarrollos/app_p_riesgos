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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Localidad
              DropdownButtonFormField<Localidad>(
                initialValue: localidadSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Localidad *',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                            _mostrarError('No se pudo conectar con el servidor');
                          }
                        }
                      },
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
      appBar: AppBar(
        title: const Text('Administrar Proyectos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Crear proyecto'),
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
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay proyectos registrados',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Presiona el botón + para crear uno',
                style: TextStyle(color: Colors.grey),
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

  Widget _buildProyectoCard(Proyecto proyecto) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarFormulario(proyecto: proyecto),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Estado activo/inactivo
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _activoColor(proyecto.activo),
                  shape: BoxShape.circle,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _activoColor(proyecto.activo).withValues(alpha: 0.1),
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
                tooltip:
                    proyecto.activo ? 'Desactivar' : 'Activar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
