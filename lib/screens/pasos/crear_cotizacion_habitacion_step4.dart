import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crear_cotizacion_habitacion_step1.dart';
import 'resumen_final_factura.dart';

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
            title: const Text('✅ Habitación registrada'),
            content: const Text('¿Qué deseas hacer ahora?'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PasoCantidadPage(
                        idCotizacion: idCotizacion,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar otra habitación'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
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
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver resumen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noches = _calcularNoches();
    final total = noches * cantidadHabitaciones * precioEspecial;
    final formato = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 4 - Confirmación'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de habitación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow('Tipo', 'Hab. $tipoHabitacion'),
            _infoRow('Cantidad', '$cantidadHabitaciones'),
            _infoRow('Ingreso', formato.format(fechaIngreso)),
            _infoRow('Salida', formato.format(fechaSalida)),
            _infoRow('Noches', '$noches'),
            _infoRow('Precio especial', 'Bs ${precioEspecial.toStringAsFixed(2)}'),
            const Divider(height: 32),
            _infoRow('Total estimado', 'Bs ${total.toStringAsFixed(2)}',
                bold: true, large: true),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _guardarEnBaseDeDatos(context),
              icon: const Icon(Icons.save_alt),
              label: const Text('Confirmar y guardar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _infoRow(String label, String value, {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: large ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
