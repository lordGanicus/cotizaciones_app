import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'crear_cotizacion_habitacion_step4.dart'; // Importa el paso 4

class PasoResumenPage extends StatefulWidget {
  final String idCotizacion;
  final int cantidad;
  final String tipoHabitacion;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final String nombreCliente;
  final String ciCliente;

  const PasoResumenPage({
    super.key,
    required this.idCotizacion,
    required this.cantidad,
    required this.tipoHabitacion,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.nombreCliente,
    required this.ciCliente,
  });

  @override
  State<PasoResumenPage> createState() => _PasoResumenPageState();
}

class _PasoResumenPageState extends State<PasoResumenPage> {
  late final TextEditingController _precioRegularController;
  late final TextEditingController _precioEspecialController;

  @override
  void initState() {
    super.initState();
    _precioRegularController = TextEditingController();
    _precioEspecialController = TextEditingController();
  }

  @override
  void dispose() {
    _precioRegularController.dispose();
    _precioEspecialController.dispose();
    super.dispose();
  }

  int get cantidadNoches =>
      widget.fechaSalida.difference(widget.fechaIngreso).inDays;

  double get precioRegular =>
      double.tryParse(_precioRegularController.text) ?? 0.0;

  double get precioEspecial =>
      double.tryParse(_precioEspecialController.text) ?? 0.0;

  void _continuar() {
    if (precioRegular <= 0 || precioEspecial <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese precios válidos mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasoConfirmarPage(
          idCotizacion: widget.idCotizacion,
          cantidadHabitaciones: widget.cantidad,
          tipoHabitacion: widget.tipoHabitacion,
          fechaIngreso: widget.fechaIngreso,
          fechaSalida: widget.fechaSalida,
          precioRegular: precioRegular,
          precioEspecial: precioEspecial,
          nombreCliente: widget.nombreCliente,
          ciCliente: widget.ciCliente,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formato = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 3: Resumen y Precios')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Cotización: ${widget.idCotizacion}'),
            Text('Cliente: ${widget.nombreCliente}'),
            Text('CI: ${widget.ciCliente}'),
            const SizedBox(height: 8),
            Text('Tipo de habitación: ${widget.tipoHabitacion}'),
            Text('Cantidad de habitaciones: ${widget.cantidad}'),
            Text('Ingreso: ${formato.format(widget.fechaIngreso)}'),
            Text('Salida: ${formato.format(widget.fechaSalida)}'),
            Text('Noches: $cantidadNoches'),
            const Divider(height: 32),
            TextField(
              controller: _precioRegularController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio Regular (por noche)',
                prefixText: 'Bs ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _precioEspecialController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio Especial (por noche)',
                prefixText: 'Bs ',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _continuar,
              child: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}