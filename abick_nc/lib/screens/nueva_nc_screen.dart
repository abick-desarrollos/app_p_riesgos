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
  final _tituloController = TextEditingController();
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
    _tituloController.dispose();
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
          'titulo': _tituloController.text.trim(),
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
                // HEADER transparente
                _buildHeader(),
                // Formulario scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          children: [
                            if (_ncIdCreado == null) ...[
                              // === FORMULARIO DE CREACIÓN ===
                              _buildFormCard(),
                            ] else ...[
                              // === SECCIÓN DE FOTOS ===
                              _buildFotoSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              _ncIdCreado != null ? 'NC $_ncIdCreado - Fotos' : 'Nueva No Conformidad',
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

  // ---- FORM CARD ----

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProyectoSelector(),
          const SizedBox(height: 12),
          _buildTituloField(),
          const SizedBox(height: 12),
          _buildTipoSelector(),
          const SizedBox(height: 12),
          _buildFechaSelector(),
          const SizedBox(height: 12),
          _buildUbicacionField(),
          const SizedBox(height: 12),
          _buildResponsableField(),
          const SizedBox(height: 12),
          _buildDescripcionField(),
          const SizedBox(height: 12),
          if (_error != null) _buildErrorBanner(_error!),
          const SizedBox(height: 4),
          _buildRegistrarButton(),
        ],
      ),
    );
  }

  // ---- FORM FIELD WIDGETS ----

  Widget _buildProyectoSelector() {
    if (_proyectos.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          labelText: 'Proyecto / Área',
          prefixIcon: Icons.business_outlined,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cargando proyectos...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(
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
      decoration: _inputDecoration(
        labelText: 'Proyecto / Área *',
        prefixIcon: Icons.business_outlined,
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

  Widget _buildTituloField() {
    return TextFormField(
      controller: _tituloController,
      decoration: _inputDecoration(
        labelText: 'Título de la no conformidad *',
        prefixIcon: Icons.title_outlined,
      ),
      maxLength: 150,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingrese el título de la no conformidad';
        if (value.length > 150) return 'El título no puede superar los 150 caracteres';
        return null;
      },
    );
  }

  Widget _buildTipoSelector() {
    return DropdownButtonFormField<String>(
      value: _tipoSeleccionado,
      decoration: _inputDecoration(
        labelText: 'Tipo *',
        prefixIcon: Icons.category_outlined,
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
        decoration: _inputDecoration(
          labelText: 'Fecha *',
          prefixIcon: Icons.calendar_today_outlined,
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
      decoration: _inputDecoration(
        labelText: 'Ubicación (opcional)',
        prefixIcon: Icons.location_on_outlined,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildResponsableField() {
    return TextFormField(
      controller: _responsableController,
      decoration: _inputDecoration(
        labelText: 'Responsable (opcional)',
        prefixIcon: Icons.person_outlined,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: _inputDecoration(
        labelText: 'Descripción *',
        prefixIcon: Icons.description_outlined,
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingrese la descripción';
        return null;
      },
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

  // ---- BANNER DE ERROR ----

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
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

  // ---- BOTÓN REGISTRAR ----

  Widget _buildRegistrarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : _guardar,
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
        child: _cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Registrar No Conformidad'),
      ),
    );
  }

  // ---- FOTOS SECTION WIDGETS ----

  Widget _buildFotoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotografías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
                borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Finalizar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
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
