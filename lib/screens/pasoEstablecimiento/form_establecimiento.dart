// lib/screens/pasoEstablecimiento/form_establecimiento.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/Mestablecimiento.dart';
import '../../providers/pestablecimiento.dart';
import '../../utils/cloudinary_upload.dart';

class FormEstablecimiento extends ConsumerStatefulWidget {
  final bool esEditar;
  final Establecimiento? establecimiento;

  const FormEstablecimiento({
    super.key,
    required this.esEditar,
    this.establecimiento,
  });

  @override
  ConsumerState<FormEstablecimiento> createState() => _FormEstablecimientoState();
}

class _FormEstablecimientoState extends ConsumerState<FormEstablecimiento> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _logotipoController;
  late TextEditingController _membreteController;

  bool _subiendoLogotipo = false;
  bool _subiendoMembrete = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.establecimiento?.nombre ?? '');
    _logotipoController = TextEditingController(text: widget.establecimiento?.logotipoUrl ?? '');
    _membreteController = TextEditingController(text: widget.establecimiento?.membreteUrl ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logotipoController.dispose();
    _membreteController.dispose();
    super.dispose();
  }

  Future<void> _subirImagen(bool esLogotipo) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      if (esLogotipo) {
        _subiendoLogotipo = true;
      } else {
        _subiendoMembrete = true;
      }
    });

    final url = await subirImagenCloudinary(pickedFile.path);

    if (url != null) {
      if (esLogotipo) {
        _logotipoController.text = url;
      } else {
        _membreteController.text = url;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la imagen')),
      );
    }

    setState(() {
      _subiendoLogotipo = false;
      _subiendoMembrete = false;
    });
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final logotipo = _logotipoController.text.trim().isEmpty ? null : _logotipoController.text.trim();
    final membrete = _membreteController.text.trim().isEmpty ? null : _membreteController.text.trim();

    try {
      if (widget.esEditar && widget.establecimiento != null) {
        await ref.read(establecimientosProvider.notifier).editarEstablecimiento(
              id: widget.establecimiento!.id,
              nombre: nombre,
              logotipoUrl: logotipo,
              membreteUrl: membrete,
            );
      } else {
        await ref.read(establecimientosProvider.notifier).agregarEstablecimiento(
              nombre: nombre,
              logotipoUrl: logotipo,
              membreteUrl: membrete,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.esEditar ? 'Editar Establecimiento' : 'Nuevo Establecimiento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),

              // Botón cargar logotipo
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Logotipo (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _subiendoLogotipo ? null : () => _subirImagen(true),
                icon: _subiendoLogotipo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: const Text('Cargar logotipo'),
              ),
              if (_logotipoController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _logotipoController.text,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              // Botón cargar membrete
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Membrete (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _subiendoMembrete ? null : () => _subirImagen(false),
                icon: _subiendoMembrete
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: const Text('Cargar membrete'),
              ),
              if (_membreteController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _membreteController.text,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}