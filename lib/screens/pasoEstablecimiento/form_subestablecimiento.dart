import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/Msubestablecimiento.dart';
import '../../providers/pestablecimiento.dart';

class FormSubestablecimiento extends ConsumerStatefulWidget {
  final bool esEditar;
  final Subestablecimiento? subestablecimiento;
  final String idEstablecimiento;

  const FormSubestablecimiento({
    super.key,
    required this.esEditar,
    this.subestablecimiento,
    required this.idEstablecimiento,
  });

  @override
  ConsumerState<FormSubestablecimiento> createState() => _FormSubestablecimientoState();
}

class _FormSubestablecimientoState extends ConsumerState<FormSubestablecimiento> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;

  // Ya no usamos controladores para URLs de imagen, porque se subirán dinámicamente
  String? _logotipoUrl;
  String? _membreteUrl;

  bool _subiendoImagenLogotipo = false;
  bool _subiendoImagenMembrete = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.subestablecimiento?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.subestablecimiento?.descripcion ?? '');
    _logotipoUrl = widget.subestablecimiento?.logotipo;
    _membreteUrl = widget.subestablecimiento?.membrete;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<String?> _subirImagen(File imagen) async {
    const cloudName = 'ds9subkxg';  // Tu cloud name
    const uploadPreset = 'flutter_unsigned_upload';  // Tu upload preset

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', imagen.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);
      return jsonResp['secure_url'] as String?;
    } else {
      return null;
    }
  }

  Future<void> _seleccionarYSubirImagen({required bool esLogotipo}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (pickedFile == null) return;

    setState(() {
      if (esLogotipo) {
        _subiendoImagenLogotipo = true;
      } else {
        _subiendoImagenMembrete = true;
      }
    });

    final url = await _subirImagen(File(pickedFile.path));

    if (url != null) {
      setState(() {
        if (esLogotipo) {
          _logotipoUrl = url;
        } else {
          _membreteUrl = url;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la imagen')),
      );
    }

    setState(() {
      if (esLogotipo) {
        _subiendoImagenLogotipo = false;
      } else {
        _subiendoImagenMembrete = false;
      }
    });
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim();

    try {
      if (widget.esEditar && widget.subestablecimiento != null) {
        await ref.read(subestablecimientosProvider(widget.idEstablecimiento).notifier).editarSubestablecimiento(
              id: widget.subestablecimiento!.id,
              nombre: nombre,
              descripcion: descripcion,
              logotipo: _logotipoUrl,
              membrete: _membreteUrl,
            );
      } else {
        await ref.read(subestablecimientosProvider(widget.idEstablecimiento).notifier).agregarSubestablecimiento(
              nombre: nombre,
              descripcion: descripcion,
              logotipo: _logotipoUrl,
              membrete: _membreteUrl,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Widget _mostrarImagenOPlaceholder(String? url, bool subiendo) {
    if (subiendo) {
      return const SizedBox(
          width: 80, height: 80, child: Center(child: CircularProgressIndicator()));
    }
    if (url != null && url.isNotEmpty) {
      return Image.network(url, width: 80, height: 80, fit: BoxFit.cover);
    }
    return const SizedBox(
      width: 80,
      height: 80,
      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.esEditar ? 'Editar Subestablecimiento' : 'Nuevo Subestablecimiento'),
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
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _mostrarImagenOPlaceholder(_logotipoUrl, _subiendoImagenLogotipo),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Subir Logotipo'),
                    onPressed: _subiendoImagenLogotipo
                        ? null
                        : () => _seleccionarYSubirImagen(esLogotipo: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _mostrarImagenOPlaceholder(_membreteUrl, _subiendoImagenMembrete),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Subir Membrete'),
                    onPressed: _subiendoImagenMembrete
                        ? null
                        : () => _seleccionarYSubirImagen(esLogotipo: false),
                  ),
                ],
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