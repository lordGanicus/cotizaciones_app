import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item_comida.dart';
import '../../providers/item_comida_provider.dart';

class AgregarItemComidaModal extends ConsumerStatefulWidget {
  const AgregarItemComidaModal({super.key});

  @override
  ConsumerState<AgregarItemComidaModal> createState() => _AgregarItemComidaModalState();
}

class _AgregarItemComidaModalState extends ConsumerState<AgregarItemComidaModal> {
  final _formKey = GlobalKey<FormState>();

  String _nombreProducto = '';
  int _cantidad = 1;
  double _precioUnitario = 0.0;

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final nuevoItem = ItemComida(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombreProducto: _nombreProducto,
        cantidad: _cantidad,
        precioUnitario: _precioUnitario,
      );

      ref.read(itemComidaProvider.notifier).agregarItem(nuevoItem);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar ítem de comida'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingrese el nombre' : null,
                onSaved: (value) => _nombreProducto = value!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese la cantidad';
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Cantidad debe ser mayor que 0';
                  return null;
                },
                onSaved: (value) => _cantidad = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Precio unitario (Bs)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el precio unitario';
                  final p = double.tryParse(value);
                  if (p == null || p < 0) return 'Precio debe ser positivo';
                  return null;
                },
                onSaved: (value) => _precioUnitario = double.parse(value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}