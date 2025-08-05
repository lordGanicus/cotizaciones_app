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

  // Colores del diseño
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D4059);
  static const Color textSecondary = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFE74C3C);

  Future<void> _guardarEnSupabase(BuildContext context, WidgetRef ref) async {
    final supabase = Supabase.instance.client;
    final habitaciones = ref.read(cotizacionHabitacionProvider);

    if (habitaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Agrega al menos una habitación antes de continuar'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: errorColor,
        ),
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
          SnackBar(
            content: Text('Error al guardar: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);
    final total = habitaciones.fold(0.0, (sum, h) => sum + (h.tarifa * h.cantidad * h.cantidadNoches));

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Confirmar Habitaciones',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Lista de habitaciones o estado vacío
            if (habitaciones.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hotel,
                        size: 48,
                        color: darkBlue.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay habitaciones para confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Regresa al paso anterior para agregar',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Resumen de Habitaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: habitaciones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final h = habitaciones[index];
                          final subtotal = h.tarifa * h.cantidad * h.cantidadNoches;

                          return Container(
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      h.nombreHabitacion,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Bs ${subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Fechas',
                                  '${DateFormat('dd/MM/yyyy').format(h.fechaIngreso)} - ${DateFormat('dd/MM/yyyy').format(h.fechaSalida)}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailRow(
                                        Icons.nights_stay,
                                        'Noches',
                                        h.cantidadNoches.toString(),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailRow(
                                        Icons.king_bed,
                                        'Cantidad',
                                        h.cantidad.toString(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.attach_money,
                                  'Tarifa por noche',
                                  'Bs ${h.tarifa.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (habitaciones.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: darkBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Bs ${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Botón de guardar
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _guardarEnSupabase(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: primaryGreen.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_alt, size: 20),
                    SizedBox(width: 8),
                    Text('GUARDAR COTIZACIÓN'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryGreen,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}