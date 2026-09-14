import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/proyecto.dart';
import '../services/api_service.dart';

/// Pantalla para registrar una nueva no conformidad.
///
/// Muestra un formulario con los campos requeridos y
/// permite agregar fotografías después de crear la NC.
/// El flujo es: crear NC → recibir id → seleccionar/subir fotos → volver al Home.

class NuevaNoConformidadScreen extends StatefulWidget {
  const NuevaNoConformidadScreen({super.key});

  @override
  State<NuevaNoConformidadScreen> createState() =>
      _NuevaNoConformidadScreenState();
}

class _NuevaNoConformidadScreenState extends State<NuevaNoConformidadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _responsableController = TextEditingController();

  // State
  List<Proyecto> _proyectos = [];
  Proyecto? _proyectoSeleccionado;
  String? _tipoSeleccionado;
  DateTime _fecha = DateTime.now();
  bool _cargando = false;
  String? _error;

  // Foto state
  int? _ncIdCreado;
  final List<XFile> _fotosSeleccionadas = [];
  bool _fotosCargando = false;
  String? _fotosError;
  final ImagePicker _picker = ImagePicker();

  // Opciones de tipo controladas por la app
  static const List<String> _tipos = [
    'Condición insegura',
    'Práctica insegura',
    'Incumplimiento',
    'Deficiencia',
    'No conformidad',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _cargarProyectos() async {
    try {
      final data = await ApiService.get('/proyectos');
      if (mounted) {
        setState(() {
          _proyectos = (data as List)
              .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
              .where((proyecto) => proyecto.activo)
              .toList();
          if (_proyectos.isNotEmpty) {
            _proyectoSeleccionado = _proyectos.first;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los proyectos: ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar con el servidor');
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  String get _fechaFormateada {
    return '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';
  }

  /// Toma una foto con la cámara.
  Future<void> _tomarFoto() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        _agregarFoto(XFile(xFile.path));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _fotosError = 'No se pudo acceder a la cámara');
      }
    }
  }

  /// Selecciona una foto desde la galería.
  Future<void> _seleccionarDeGaleria() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        _agregarFoto(XFile(xFile.path));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _fotosError = 'No se pudo acceder a la galería');
      }
    }
  }

  void _agregarFoto(XFile foto) {
    if (_fotosSeleccionadas.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 3 fotografías por no conformidad'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() {
      _fotosSeleccionadas.add(foto);
      _fotosError = null;
    });
  }

  void _eliminarFoto(int index) {
    setState(() {
      _fotosSeleccionadas.removeAt(index);
    });
  }

  Future<void> _subirFotos() async {
    if (_fotosSeleccionadas.isEmpty) return;
    if (_ncIdCreado == null) return;

    setState(() {
      _fotosCargando = true;
      _fotosError = null;
    });

    try {
      final files = _fotosSeleccionadas.map((f) => File(f.path)).toList();
      await ApiService.postFotos(
        '/no-conformidades/$_ncIdCreado/fotos',
        files: files,
      );

      if (mounted) {
        setState(() {
          _fotosCargando = false;
          _fotosSeleccionadas.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotografías subidas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _fotosCargando = false;
          _fotosError = 'Error al subir fotografías: ${e.message}';
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final decoded = await ApiService.post(
        '/no-conformidades',
        body: {
          'proyecto_id': _proyectoSeleccionado!.id,
          'tipo': _tipoSeleccionado,
          'fecha': '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}',
          'ubicacion': _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
          'responsable': _responsableController.text.trim().isEmpty ? null : _responsableController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
        },
      );

      if (mounted) {
        setState(() {
          _cargando = false;
          _ncIdCreado = decoded['no_conformidad']['id'] as int;
        });
        final numero = decoded['no_conformidad']['numero'] as String;
        _mostrarConfirmacion(numero);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = e.message;
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

  void _mostrarConfirmacion(String numero) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('No conformidad registrada'),
        content: Text(
          'La no conformidad $numero se ha creado correctamente.\n\n¿Desea agregar fotografías?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Omitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _fotosSeleccionadas.clear();
              });
            },
            child: const Text('Agregar fotos'),
          ),
        ],
      ),
    );
  }

  bool get _hayFotos => _fotosSeleccionadas.isNotEmpty;
  bool get _limiteAlcanzado => _fotosSeleccionadas.length >= 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ncIdCreado != null ? 'NC $_ncIdCreado - Fotos' : 'Nueva No Conformidad'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (_ncIdCreado == null) ...[
              // === FORMULARIO DE CREACIÓN ===
              _buildProyectoSelector(),
              const SizedBox(height: 16),
              _buildTipoSelector(),
              const SizedBox(height: 16),
              _buildFechaSelector(),
              const SizedBox(height: 16),
              _buildUbicacionField(),
              const SizedBox(height: 16),
              _buildResponsableField(),
              const SizedBox(height: 16),
              _buildDescripcionField(),
              const SizedBox(height: 16),
              if (_error != null) _buildErrorBanner(_error!),
              const SizedBox(height: 8),
              _buildRegistrarButton(),
            ] else ...[
              // === SECCIÓN DE FOTOS ===
              _buildFotoSection(),
            ],
          ],
        ),
      ),
    );
  }

  // ---- FORMULARIO WIDGETS ----

  Widget _buildProyectoSelector() {
    if (_proyectos.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Proyecto / Área',
          prefixIcon: const Icon(Icons.business_outlined),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cargando proyectos...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<Proyecto>(
      value: _proyectoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Proyecto / Área *',
        prefixIcon: const Icon(Icons.business_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _proyectos.map((proyecto) {
        return DropdownMenuItem(
          value: proyecto,
          child: Text(proyecto.nombre),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _proyectoSeleccionado = value);
      },
      validator: (value) {
        if (value == null) return 'Seleccione un proyecto';
        return null;
      },
    );
  }

  Widget _buildTipoSelector() {
    return DropdownButtonFormField<String>(
      value: _tipoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Tipo *',
        prefixIcon: const Icon(Icons.category_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _tipos.map((tipo) {
        return DropdownMenuItem(
          value: tipo,
          child: Text(tipo),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _tipoSeleccionado = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Seleccione un tipo';
        return null;
      },
    );
  }

  Widget _buildFechaSelector() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha *',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fechaFormateada),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionField() {
    return TextFormField(
      controller: _ubicacionController,
      decoration: InputDecoration(
        labelText: 'Ubicación (opcional)',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildResponsableField() {
    return TextFormField(
      controller: _responsableController,
      decoration: InputDecoration(
        labelText: 'Responsable (opcional)',
        prefixIcon: const Icon(Icons.person_outline),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: InputDecoration(
        labelText: 'Descripción *',
        prefixIcon: const Icon(Icons.description_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingrese la descripción';
        return null;
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : _guardar,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Registrar No Conformidad',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  // ---- FOTOS SECTION WIDGETS ----

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotografías',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_fotosSeleccionadas.length}/3 fotografías',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Miniaturas de fotos seleccionadas
        if (_hayFotos) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fotosSeleccionadas.length,
              itemBuilder: (context, index) {
                final foto = _fotosSeleccionadas[index];
                return _buildFotoThumbnail(foto, index);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botones para agregar fotos
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _limiteAlcanzado ? null : _tomarFoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _limiteAlcanzado ? null : _seleccionarDeGaleria,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Error de fotos
        if (_fotosError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fotosError!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // Botón subir fotos
        if (_hayFotos)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _fotosCargando ? null : _subirFotos,
              icon: _fotosCargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: _fotosCargando
                  ? const Text('Subiendo...')
                  : const Text('Subir fotografías'),
            ),
          ),

        const SizedBox(height: 16),

        // Botón terminar (siempre visible después de crear NC)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Finalizar',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFotoThumbnail(XFile foto, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(foto.path),
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _eliminarFoto(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
