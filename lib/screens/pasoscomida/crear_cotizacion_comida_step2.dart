import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itemComida.dart';
import '../../providers/cotizacion_comida_provider.dart';
import 'crear_cotizacion_comida_step3.dart';

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

  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  bool _intercambiarColores = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Capitaliza automáticamente la primera letra de la descripción
  String _capitalizarDescripcion(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  void _agregarItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final descripcionRaw = _descripcionController.text.trim();
      final descripcion = _capitalizarDescripcion(descripcionRaw);

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

      setState(() {
        _intercambiarColores = !_intercambiarColores;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plato guardado'),
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
    final guardarColor = _intercambiarColores ? darkBlue : primaryGreen;
    final verListaColor = _intercambiarColores ? primaryGreen : darkBlue;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Agregar platos / almuerzo o desayunos'),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  if (value.trim().length < 3) {
                    return 'Ingrese una descripción válida';
                  }
                  final texto = value.trim();
                  // Validación más flexible
                  if (!RegExp(r'^[A-Za-zÁÉÍÓÚÑáéíóúñ0-9\s.,()\-\/]+$').hasMatch(texto)) {
                    return 'La descripción contiene caracteres no permitidos';
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La cantidad es obligatoria';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Ingrese una cantidad válida mayor a cero';
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
                  prefixIcon: const Icon(Icons.monetization_on),
                  prefixText: 'BS ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final d = double.tryParse(value);
                  if (d == null || d <= 0) {
                    return 'Ingrese un precio válido mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _agregarItem,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: guardarColor,
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
                  backgroundColor: verListaColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
