import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itemComida.dart';
import '../../providers/cotizacion_comida_provider.dart';
import 'crear_cotizacion_comida_step3.dart'; // Importa el paso 3 correcto

class CrearCotizacionComidaStep2 extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const CrearCotizacionComidaStep2({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  @override
  ConsumerState<CrearCotizacionComidaStep2> createState() =>
      _CrearCotizacionComidaStep2State();
}

class _CrearCotizacionComidaStep2State
    extends ConsumerState<CrearCotizacionComidaStep2> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  // Colores según paleta salones
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _agregarItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final descripcion = _descripcionController.text.trim();
      final cantidad = int.parse(_cantidadController.text.trim());
      final precioUnitario = double.parse(_precioController.text.trim());

      final nuevoItem = ItemComida(
        descripcion: descripcion,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
      );

      ref.read(cotizacionComidaProvider.notifier).agregarItem(nuevoItem);

      _descripcionController.clear();
      _cantidadController.clear();
      _precioController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ítem agregado'),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  void _irALaListaEditable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCotizacionComidaStep3(
          idCotizacion: widget.idCotizacion,
          idEstablecimiento: widget.idEstablecimiento,
          idUsuario: widget.idUsuario,
          idSubestablecimiento: widget.idSubestablecimiento,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Agregar Platos / Almuerzo o Desayunos'),
        backgroundColor: darkBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del plato o producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.restaurant_menu),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  if (value.trim().length < 3) {
                    return 'Ingrese una descripción válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La cantidad es obligatoria';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Ingrese una cantidad válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: InputDecoration(
                  labelText: 'Precio Unitario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final d = double.tryParse(value);
                  if (d == null || d <= 0) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _agregarItem,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Agregar Plato',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _irALaListaEditable,
                child: const Text(
                  'Ver lista de platos agregados',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: darkBlue.withOpacity(0.7)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: darkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
