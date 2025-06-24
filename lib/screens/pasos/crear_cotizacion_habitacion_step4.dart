import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crear_cotizacion_habitacion_step1.dart'; // Para agregar otra habitación
import 'resumen_final_factura.dart'; // Este será el Paso 5

class PasoConfirmarPage extends StatelessWidget {
  final String idCotizacion;
  final int cantidadHabitaciones;
  final String tipoHabitacion;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final double precioRegular;
  final double precioEspecial;
  final String nombreCliente;
  final String ciCliente;

  const PasoConfirmarPage({
    super.key,
    required this.idCotizacion,
    required this.cantidadHabitaciones,
    required this.tipoHabitacion,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.precioRegular,
    required this.precioEspecial,
    required this.nombreCliente,
    required this.ciCliente,
  });

  int _calcularNoches() {
    return fechaSalida.difference(fechaIngreso).inDays;
  }

  Future<void> _guardarEnBaseDeDatos(BuildContext context) async {
    final noches = _calcularNoches();
    final supabase = Supabase.instance.client;

    final descripcion =
        'Reserva del ${DateFormat('dd-MM-yy').format(fechaIngreso)} al ${DateFormat('dd-MM-yy').format(fechaSalida)}';

    final detalles = {
      "fecha_ingreso": fechaIngreso.toIso8601String(),
      "fecha_salida": fechaSalida.toIso8601String(),
      "precio_regular": precioRegular,
      "precio_especial": precioEspecial,
      "tipo": tipoHabitacion,
      "noches": noches,
      "cantidad_habitaciones": cantidadHabitaciones,
    };

    final total = noches * cantidadHabitaciones * precioEspecial;

    try {
      await supabase.from('items_cotizacion').insert({
        'id_cotizacion': idCotizacion,
        'servicio': 'Hab. $tipoHabitacion',
        'unidad': 'Noche',
        'cantidad': noches * cantidadHabitaciones,
        'precio_unitario': precioEspecial,
        'descripcion': descripcion,
        'detalles': detalles,
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Habitación registrada'),
            content: const Text('¿Qué deseas hacer ahora?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra diálogo
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PasoCantidadPage(
                        idCotizacion: idCotizacion,
                        // Si PasoCantidadPage no tiene estos parámetros, comentalos o elimínalos
                        // nombreCliente: nombreCliente,
                        // ciCliente: ciCliente,
                      ),
                    ),
                  );
                },
                child: const Text('Agregar otra habitación'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra diálogo
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ResumenFinalPage(
                        idCotizacion: idCotizacion,
                        nombreCliente: nombreCliente,
                        ciCliente: ciCliente,
                      ),
                    ),
                  );
                },
                child: const Text('Ver resumen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noches = _calcularNoches();
    final total = noches * cantidadHabitaciones * precioEspecial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar habitación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Tipo: Hab. $tipoHabitacion'),
            Text('Cantidad: $cantidadHabitaciones'),
            Text('Desde: ${DateFormat('dd-MM-yyyy').format(fechaIngreso)}'),
            Text('Hasta: ${DateFormat('dd-MM-yyyy').format(fechaSalida)}'),
            Text('Noches: $noches'),
            Text('Precio especial por noche: Bs ${precioEspecial.toStringAsFixed(2)}'),
            Text('Total: Bs ${total.toStringAsFixed(2)}'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _guardarEnBaseDeDatos(context),
              icon: const Icon(Icons.save),
              label: const Text('Confirmar y guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
