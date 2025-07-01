import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habitacion.dart';
import '../../providers/habitaciones_provider.dart';

class HabitacionForm extends ConsumerStatefulWidget {
  final String idEstablecimiento;
  final Habitacion? habitacionExistente;

  const HabitacionForm({
    super.key,
    required this.idEstablecimiento,
    this.habitacionExistente,
  });

  @override
  ConsumerState<HabitacionForm> createState() => _HabitacionFormState();
}

class _HabitacionFormState extends ConsumerState<HabitacionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _capacidadController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.habitacionExistente?.nombre ?? '');
    _capacidadController = TextEditingController(
        text: widget.habitacionExistente?.capacidad.toString() ?? '');
    _descripcionController =
        TextEditingController(text: widget.habitacionExistente?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _capacidadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.habitacionExistente != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar habitación' : 'Nueva habitación'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
              ),
              TextFormField(
                controller: _capacidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacidad'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese la capacidad';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Capacidad inválida';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
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
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final nombre = _nombreController.text.trim();
              final capacidad = int.parse(_capacidadController.text.trim());
              final descripcion = _descripcionController.text.trim().isEmpty
                  ? null
                  : _descripcionController.text.trim();

              if (esEdicion) {
                await ref
                    .read(habitacionesProvider(widget.idEstablecimiento).notifier)
                    .editarHabitacion(
                      widget.habitacionExistente!.id,
                      nombre,
                      capacidad,
                      descripcion,
                    );
              } else {
                await ref
                    .read(habitacionesProvider(widget.idEstablecimiento).notifier)
                    .agregarHabitacion(nombre, capacidad, descripcion);
              }

              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
