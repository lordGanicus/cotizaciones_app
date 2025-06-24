import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'crear_cotizacion_habitacion_step4.dart';

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
    final formato = DateFormat('dd/MM/yyyy');
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 3 - Precios y Resumen'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de la habitación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _itemResumen('Cliente', widget.nombreCliente),
            _itemResumen('CI / NIT', widget.ciCliente),
            _itemResumen('Habitación', widget.tipoHabitacion),
            _itemResumen('Cantidad', '${widget.cantidad}'),
            _itemResumen('Ingreso', formato.format(widget.fechaIngreso)),
            _itemResumen('Salida', formato.format(widget.fechaSalida)),
            _itemResumen('Noches', '$cantidadNoches'),
            const Divider(height: 32),
            const Text('Precios por noche',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _precioRegularController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Precio Regular',
                prefixText: 'Bs ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _precioEspecialController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Precio Especial',
                prefixText: 'Bs ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _continuar,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Siguiente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemResumen(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('$titulo:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 6, child: Text(valor)),
        ],
      ),
    );
  }
}
