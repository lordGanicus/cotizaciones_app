import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../providers/salones_provider.dart';
import '../../providers/servicios_provider.dart';
import '../../providers/refrigerios_provider.dart';

class SalonForm extends ConsumerStatefulWidget {
  final Salon? salon;
  const SalonForm({super.key, this.salon});

  @override
  ConsumerState<SalonForm> createState() => _SalonFormState();
}

class _SalonFormState extends ConsumerState<SalonForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _capMesasController;
  late TextEditingController _capSillasController;
  late TextEditingController _descripcionController;

  Set<String> _serviciosSeleccionados = {};
  Set<String> _refrigeriosSeleccionados = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final salon = widget.salon;

    _nombreController = TextEditingController(text: salon?.nombre ?? '');
    _capMesasController = TextEditingController(text: salon?.capacidadMesas.toString() ?? '');
    _capSillasController = TextEditingController(text: salon?.capacidadSillas.toString() ?? '');
    _descripcionController = TextEditingController(text: salon?.descripcion ?? '');

    _serviciosSeleccionados = salon?.servicios.map((s) => s.id).toSet() ?? {};
    _refrigeriosSeleccionados = salon?.refrigerios.map((r) => r.id).toSet() ?? {};
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _capMesasController.dispose();
    _capSillasController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final nombre = _nombreController.text.trim();
    final capacidadMesas = int.tryParse(_capMesasController.text.trim()) ?? 0;
    final capacidadSillas = int.tryParse(_capSillasController.text.trim()) ?? 0;
    final descripcion = _descripcionController.text.trim();

    try {
      if (widget.salon == null) {
        await ref.read(salonesProvider.notifier).agregarSalon(
          nombre,
          capacidadMesas,
          capacidadSillas,
          descripcion.isEmpty ? null : descripcion,
          _serviciosSeleccionados.toList(),
          _refrigeriosSeleccionados.toList(),
        );
      } else {
        await ref.read(salonesProvider.notifier).editarSalon(
          widget.salon!.id,
          nombre,
          capacidadMesas,
          capacidadSillas,
          descripcion.isEmpty ? null : descripcion,
          _serviciosSeleccionados.toList(),
          _refrigeriosSeleccionados.toList(),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviciosAsync = ref.watch(serviciosProvider);
    final refrigeriosAsync = ref.watch(refrigeriosProvider);

    return AbsorbPointer(
      absorbing: _isLoading,
      child: AlertDialog(
        title: Text(widget.salon == null ? 'Agregar Salón' : 'Editar Salón'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del salón'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capMesasController,
                  decoration: const InputDecoration(labelText: 'Capacidad de mesas'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final num = int.tryParse(value ?? '');
                    if (num == null || num < 0) return 'Ingrese un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capSillasController,
                  decoration: const InputDecoration(labelText: 'Capacidad de sillas'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final num = int.tryParse(value ?? '');
                    if (num == null || num < 0) return 'Ingrese un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                serviciosAsync.when(
                  data: (servicios) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Servicios incluidos', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...servicios.map((servicio) => CheckboxListTile(
                            title: Text(servicio.nombre),
                            subtitle: Text(servicio.descripcion),
                            value: _serviciosSeleccionados.contains(servicio.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _serviciosSeleccionados.add(servicio.id);
                                } else {
                                  _serviciosSeleccionados.remove(servicio.id);
                                }
                              });
                            },
                          )),
                      const SizedBox(height: 12),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error cargando servicios: $e')),
                ),
                refrigeriosAsync.when(
                  data: (refrigerios) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Refrigerios', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...refrigerios.map((r) => CheckboxListTile(
                            title: Text(r.nombre),
                            subtitle: Text(r.descripcion),
                            value: _refrigeriosSeleccionados.contains(r.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _refrigeriosSeleccionados.add(r.id);
                                } else {
                                  _refrigeriosSeleccionados.remove(r.id);
                                }
                              });
                            },
                          )),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error cargando refrigerios: $e')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _guardar,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}