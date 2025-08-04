import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'crear_cotizacion_habitacion_step4.dart'; // Ajusta ruta si es necesario

class PasoResumenHabitacionesPage extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const PasoResumenHabitacionesPage({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  double _calcularTotal(List<CotizacionHabitacion> habitaciones) {
    return habitaciones.fold(0, (sum, h) => sum + h.subtotal);
  }

  String _formatFecha(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Paso 3 - Resumen de habitaciones'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Agregar funcionalidad para agregar habitación si deseas
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar habitación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            if (habitaciones.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No se han agregado habitaciones.',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkBlue.withOpacity(0.7),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: habitaciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final h = habitaciones[index];
                    final subtotal = h.tarifa * h.cantidad * h.cantidadNoches;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.nombreHabitacion,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: darkBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: darkBlue),
                                const SizedBox(width: 6),
                                Text(
                                  'Fecha: ${_formatFecha(h.fechaIngreso)} - ${_formatFecha(h.fechaSalida)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: darkBlue.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Noches: ${h.cantidadNoches}',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkBlue.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: ${h.cantidad}',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkBlue.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Precio Unitario: Bs ${h.tarifa.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkBlue.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Subtotal: Bs ${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            if (habitaciones.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bs ${_calcularTotal(habitaciones).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            if (habitaciones.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasoConfirmarHabitacionPage(
                          idCotizacion: idCotizacion,
                          nombreCliente: nombreCliente,
                          ciCliente: ciCliente,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Confirmar habitaciones y continuar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
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