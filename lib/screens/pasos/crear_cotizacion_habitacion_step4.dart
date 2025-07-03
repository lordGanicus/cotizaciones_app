import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'resumen_final_factura.dart';

class PasoConfirmarHabitacionPage extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const PasoConfirmarHabitacionPage({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  Future<void> _guardarEnSupabase(BuildContext context, WidgetRef ref) async {
    final supabase = Supabase.instance.client;
    final habitaciones = ref.read(cotizacionHabitacionProvider);

    if (habitaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una habitación antes de continuar')),
      );
      return;
    }

    try {
      for (final habitacion in habitaciones) {
        final total = habitacion.cantidad * habitacion.tarifa * habitacion.cantidadNoches;

        final detalles = {
          'nombre_habitacion': habitacion.nombreHabitacion,
          'cantidad': habitacion.cantidad,
          'fecha_ingreso': habitacion.fechaIngreso.toIso8601String(),
          'fecha_salida': habitacion.fechaSalida.toIso8601String(),
          'cantidad_noches': habitacion.cantidadNoches,
          'tarifa': habitacion.tarifa,
          'subtotal': total,
        };

        final descripcion =
            'Del ${DateFormat('dd/MM/yyyy').format(habitacion.fechaIngreso)} al ${DateFormat('dd/MM/yyyy').format(habitacion.fechaSalida)} - ${habitacion.cantidad} x ${habitacion.nombreHabitacion}';

        await supabase.from('items_cotizacion').insert({
          'id_cotizacion': idCotizacion,
          'servicio': 'Hab. ${habitacion.nombreHabitacion}',
          'unidad': 'Noche',
          'cantidad': habitacion.cantidad * habitacion.cantidadNoches,
          'precio_unitario': habitacion.tarifa,
          'descripcion': descripcion,
          'detalles': detalles,
        });
      }

      // Vaciar lista luego de guardar
      ref.read(cotizacionHabitacionProvider.notifier).limpiar();

      // Ir al resumen final
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResumenFinalPage(
              idCotizacion: idCotizacion,
              nombreCliente: nombreCliente,
              ciCliente: ciCliente,
            ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 4 - Confirmar habitaciones'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: habitaciones.isEmpty
                  ? const Center(child: Text('No se agregaron habitaciones.'))
                  : ListView.builder(
                      itemCount: habitaciones.length,
                      itemBuilder: (context, index) {
                        final h = habitaciones[index];
                        final subtotal = h.tarifa * h.cantidad * h.cantidadNoches;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(h.nombreHabitacion, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cantidad: ${h.cantidad}'),
                                Text('Ingreso: ${DateFormat('dd/MM/yyyy').format(h.fechaIngreso)}'),
                                Text('Salida: ${DateFormat('dd/MM/yyyy').format(h.fechaSalida)}'),
                                Text('Noches: ${h.cantidadNoches}'),
                                Text('Tarifa: Bs ${h.tarifa.toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: Text(
                              'Bs ${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _guardarEnSupabase(context, ref),
              icon: const Icon(Icons.save_alt),
              label: const Text('Guardar cotización'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
