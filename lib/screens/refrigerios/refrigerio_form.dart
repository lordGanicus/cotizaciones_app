import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/refrigerio.dart';
import '../../providers/refrigerios_provider.dart';

class RefrigerioForm extends ConsumerStatefulWidget {
  final Refrigerio? refrigerio;

  const RefrigerioForm({super.key, this.refrigerio});

  @override
  ConsumerState<RefrigerioForm> createState() => _RefrigerioFormState();
}

class _RefrigerioFormState extends ConsumerState<RefrigerioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  bool _isLoading = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.refrigerio?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.refrigerio?.descripcion ?? '');
    _precioController = TextEditingController(
      text: widget.refrigerio?.precioUnitario.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Habilitar validación mientras se intenta guardar
    setState(() => _autoValidateMode = AutovalidateMode.always);

    if (!_formKey.currentState!.validate()) return;

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final precio = double.tryParse(_precioController.text.trim()) ?? 0;

    try {
      if (widget.refrigerio == null) {
        await ref.read(refrigeriosProvider.notifier).agregarRefrigerio(nombre, descripcion, precio);
      } else {
        await ref.read(refrigeriosProvider.notifier).editarRefrigerio(
              widget.refrigerio!.id,
              nombre,
              descripcion,
              precio,
            );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.refrigerio != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Refrigerio' : 'Agregar Refrigerio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio unitario'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0) return 'Ingrese un precio válido mayor que 0';
                  return null;
                },
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
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}