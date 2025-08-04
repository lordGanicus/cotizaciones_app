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

  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

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
      String? idCliente;

      if (ciCliente.isNotEmpty) {
        final clientes = await supabase
            .from('clientes')
            .select('id')
            .eq('ci', ciCliente)
            .limit(1);

        if (clientes.isNotEmpty) {
          idCliente = clientes[0]['id'] as String;
        }
      }

      if (idCliente == null) {
        final clientesPorNombre = await supabase
            .from('clientes')
            .select('id')
            .eq('nombre_completo', nombreCliente)
            .limit(1);

        if (clientesPorNombre.isNotEmpty) {
          idCliente = clientesPorNombre[0]['id'] as String;
        }
      }

      if (idCliente == null) {
        final insertRes = await supabase.from('clientes').insert({
          'nombre_completo': nombreCliente,
          if (ciCliente.isNotEmpty) 'ci': ciCliente,
        }).select('id').single();

        idCliente = insertRes['id'] as String;
      }

      await supabase
          .from('cotizaciones')
          .update({'id_cliente': idCliente})
          .eq('id', idCotizacion);

      double totalCotizacion = 0.0;

      for (final habitacion in habitaciones) {
        final total = habitacion.cantidad * habitacion.tarifa * habitacion.cantidadNoches;
        totalCotizacion += total;

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
          'tipo': 'habitacion',
          'servicio': 'Hab. ${habitacion.nombreHabitacion}',
          'unidad': 'Noche',
          'cantidad': habitacion.cantidad * habitacion.cantidadNoches,
          'precio_unitario': habitacion.tarifa,
          'descripcion': descripcion,
          'detalles': detalles,
        });
      }

      await supabase
          .from('cotizaciones')
          .update({'total': totalCotizacion})
          .eq('id', idCotizacion);

      ref.read(cotizacionHabitacionProvider.notifier).limpiar();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResumenFinalCotizacionHabitacionPage(
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
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Paso 4 - Confirmar habitaciones'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: habitaciones.isEmpty
                  ? Center(
                      child: Text(
                        'No se agregaron habitaciones.',
                        style: TextStyle(
                          fontSize: 16,
                          color: darkBlue.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: habitaciones.length,
                      itemBuilder: (context, index) {
                        final h = habitaciones[index];
                        final subtotal = h.tarifa * h.cantidad * h.cantidadNoches;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(
                              h.nombreHabitacion,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: darkBlue),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cantidad: ${h.cantidad}', style: TextStyle(color: darkBlue.withOpacity(0.8))),
                                  Text('Ingreso: ${DateFormat('dd/MM/yyyy').format(h.fechaIngreso)}', style: TextStyle(color: darkBlue.withOpacity(0.8))),
                                  Text('Salida: ${DateFormat('dd/MM/yyyy').format(h.fechaSalida)}', style: TextStyle(color: darkBlue.withOpacity(0.8))),
                                  Text('Noches: ${h.cantidadNoches}', style: TextStyle(color: darkBlue.withOpacity(0.8))),
                                  Text('Tarifa: Bs ${h.tarifa.toStringAsFixed(2)}', style: TextStyle(color: darkBlue.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            trailing: Text(
                              'Bs ${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _guardarEnSupabase(context, ref),
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar cotización'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
