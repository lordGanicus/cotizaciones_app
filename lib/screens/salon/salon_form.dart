import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../models/servicio_incluido.dart';
import '../../models/refrigerio.dart';
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

  Future<void> _seleccionarServicios() async {
    final servicios = ref.read(serviciosProvider).value ?? [];
    final seleccionados = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _SeleccionDialog<ServicioIncluido>(
        titulo: 'Seleccionar servicios incluidos',
        elementos: servicios,
        seleccionInicial: _serviciosSeleccionados,
        labelBuilder: (s) => s.nombre,
        descripcionBuilder: (s) => s.descripcion,
        idBuilder: (s) => s.id,
      ),
    );

    if (seleccionados != null) {
      setState(() {
        _serviciosSeleccionados = seleccionados;
      });
    }
  }

  Future<void> _seleccionarRefrigerios() async {
    final refrigerios = ref.read(refrigeriosProvider).value ?? [];
    final seleccionados = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _SeleccionDialog<Refrigerio>(
        titulo: 'Seleccionar refrigerios',
        elementos: refrigerios,
        seleccionInicial: _refrigeriosSeleccionados,
        labelBuilder: (r) => r.nombre,
        descripcionBuilder: (r) => r.descripcion,
        idBuilder: (r) => r.id,
      ),
    );

    if (seleccionados != null) {
      setState(() {
        _refrigeriosSeleccionados = seleccionados;
      });
    }
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
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
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
                ElevatedButton.icon(
                  onPressed: _seleccionarServicios,
                  icon: const Icon(Icons.miscellaneous_services),
                  label: const Text('Seleccionar servicios incluidos'),
                ),
                Text('${_serviciosSeleccionados.length} seleccionados'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _seleccionarRefrigerios,
                  icon: const Icon(Icons.fastfood),
                  label: const Text('Seleccionar refrigerios'),
                ),
                Text('${_refrigeriosSeleccionados.length} seleccionados'),
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

class _SeleccionDialog<T> extends StatefulWidget {
  final String titulo;
  final List<T> elementos;
  final Set<String> seleccionInicial;
  final String Function(T) labelBuilder;
  final String Function(T) descripcionBuilder;
  final String Function(T) idBuilder;

  const _SeleccionDialog({
    required this.titulo,
    required this.elementos,
    required this.seleccionInicial,
    required this.labelBuilder,
    required this.descripcionBuilder,
    required this.idBuilder,
  });

  @override
  State<_SeleccionDialog<T>> createState() => _SeleccionDialogState<T>();
}

class _SeleccionDialogState<T> extends State<_SeleccionDialog<T>> {
  late Set<String> seleccion;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    seleccion = {...widget.seleccionInicial};
  }

  @override
  Widget build(BuildContext context) {
    final elementosFiltrados = widget.elementos.where((e) {
      final texto = (widget.labelBuilder(e) + widget.descripcionBuilder(e)).toLowerCase();
      return texto.contains(_filtro.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _filtro = value),
            ),
            const SizedBox(height: 12),
            ...elementosFiltrados.map((e) {
              final id = widget.idBuilder(e);
              return CheckboxListTile(
                title: Text(widget.labelBuilder(e)),
                subtitle: Text(widget.descripcionBuilder(e)),
                value: seleccion.contains(id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      seleccion.add(id);
                    } else {
                      seleccion.remove(id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, seleccion),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
