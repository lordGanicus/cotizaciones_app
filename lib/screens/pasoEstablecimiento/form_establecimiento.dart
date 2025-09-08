import 'dart:io';
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
  late TextEditingController _checkinController;
  late TextEditingController _checkoutController;

  bool _subiendoLogotipo = false;
  bool _subiendoMembrete = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? _logotipoPublicId;
  String? _membretePublicId;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.establecimiento?.nombre ?? '');
    _logotipoController =
        TextEditingController(text: widget.establecimiento?.logotipo ?? '');
    _membreteController =
        TextEditingController(text: widget.establecimiento?.membrete ?? '');
    _logotipoPublicId = widget.establecimiento?.logotipoPublicId;
    _membretePublicId = widget.establecimiento?.membretePublicId;

    // Nuevos campos con valores por defecto
    _checkinController = TextEditingController(
        text: widget.establecimiento?.checkin ?? '14:00');
    _checkoutController = TextEditingController(
        text: widget.establecimiento?.checkout ?? '12:00');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logotipoController.dispose();
    _membreteController.dispose();
    _checkinController.dispose();
    _checkoutController.dispose();
    super.dispose();
  }

  Future<void> _subirImagen(bool esLogotipo) async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      if (esLogotipo) {
        _subiendoLogotipo = true;
      } else {
        _subiendoMembrete = true;
      }
    });

    final resultado = await _cloudinaryService.subirImagen(pickedFile.path);

    if (resultado != null &&
        resultado['secure_url'] != null &&
        resultado['public_id'] != null) {
      final url = resultado['secure_url']!;
      final publicId = resultado['public_id']!;

      setState(() {
        if (esLogotipo) {
          _logotipoController.text = url;
          _logotipoPublicId = publicId;
        } else {
          _membreteController.text = url;
          _membretePublicId = publicId;
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen')),
        );
      }
    }

    setState(() {
      _subiendoLogotipo = false;
      _subiendoMembrete = false;
    });
  }

  Future<void> _seleccionarHora(TextEditingController controller) async {
    final timeParts = controller.text.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 14,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      controller.text =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final logotipo = _logotipoController.text.trim().isEmpty
        ? null
        : _logotipoController.text.trim();
    final membrete = _membreteController.text.trim().isEmpty
        ? null
        : _membreteController.text.trim();
    final checkin = _checkinController.text.trim();
    final checkout = _checkoutController.text.trim();

    try {
      if (widget.esEditar && widget.establecimiento != null) {
        await ref.read(establecimientosProvider.notifier).editarEstablecimiento(
              id: widget.establecimiento!.id,
              nombre: nombre,
              logotipo: logotipo,
              logotipoPublicId: _logotipoPublicId,
              membrete: membrete,
              membretePublicId: _membretePublicId,
              checkin: checkin,
              checkout: checkout,
            );
      } else {
        await ref.read(establecimientosProvider.notifier).agregarEstablecimiento(
              nombre: nombre,
              logotipo: logotipo,
              logotipoPublicId: _logotipoPublicId,
              membrete: membrete,
              membretePublicId: _membretePublicId,
              checkin: checkin,
              checkout: checkout,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.esEditar ? 'Editar Establecimiento' : 'Nuevo Establecimiento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),

              // Check-in
              TextFormField(
                controller: _checkinController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Horario Check-In'),
                onTap: () => _seleccionarHora(_checkinController),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingrese un horario' : null,
              ),
              const SizedBox(height: 16),

              // Check-out
              TextFormField(
                controller: _checkoutController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Horario Check-Out'),
                onTap: () => _seleccionarHora(_checkoutController),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingrese un horario' : null,
              ),
              const SizedBox(height: 16),

              // Logotipo
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Logotipo (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.network(_logotipoController.text,
                      height: 80, width: 80, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),

              // Membrete
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Membrete (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.network(_membreteController.text,
                      height: 80, width: 80, fit: BoxFit.cover),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
