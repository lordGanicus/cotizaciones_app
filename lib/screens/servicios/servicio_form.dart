// lib/screens/servicios/servicio_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/servicio_incluido.dart';
import '../../providers/servicios_provider.dart';

class ServicioForm extends ConsumerStatefulWidget {
  final ServicioIncluido? servicio;

  const ServicioForm({super.key, this.servicio});

  @override
  ConsumerState<ServicioForm> createState() => _ServicioFormState();
}

class _ServicioFormState extends ConsumerState<ServicioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.servicio?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.servicio?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    final serviciosNotifier = ref.read(serviciosProvider.notifier);

    try {
      if (widget.servicio == null) {
        await serviciosNotifier.agregarServicio(nombre, descripcion);
      } else {
        await serviciosNotifier.editarServicio(widget.servicio!.id, nombre, descripcion);
      }

      Navigator.pop(context); // Cierra el dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.servicio != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esEdicion ? 'Editar Servicio' : 'Nuevo Servicio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _guardar,
                  child: _cargando
                      ? const CircularProgressIndicator()
                      : Text(esEdicion ? 'Guardar cambios' : 'Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}