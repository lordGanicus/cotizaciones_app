import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'seleccionar_habitacion_modal.dart';
import 'crear_cotizacion_habitacion_step3.dart';

class CrearCotizacionHabitacionStep2 extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const CrearCotizacionHabitacionStep2({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);

    final totalCotizacion = habitaciones.fold<double>(
      0.0,
      (sum, hab) => sum + (hab.tarifa * hab.cantidadNoches * hab.cantidad),
    );

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Paso 2 - Agregar Habitaciones'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cliente: $nombreCliente\nCI: $ciCliente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: habitaciones.isEmpty
                  ? Center(
                      child: Text(
                        'No hay habitaciones agregadas aún.',
                        style: TextStyle(
                          fontSize: 16,
                          color: darkBlue.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: habitaciones.length,
                      itemBuilder: (context, index) {
                        final hab = habitaciones[index];
                        final subtotal =
                            hab.tarifa * hab.cantidadNoches * hab.cantidad;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            title: Text(
                              hab.nombreHabitacion,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Cantidad: ${hab.cantidad}\n'
                                'Ingreso: ${_formatDate(hab.fechaIngreso)}\n'
                                'Salida: ${_formatDate(hab.fechaSalida)}\n'
                                'Noches: ${hab.cantidadNoches}\n'
                                'Tarifa: Bs ${hab.tarifa.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: darkBlue.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Text(
                              'Bs ${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            Divider(color: darkBlue.withOpacity(0.3), thickness: 1),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: darkBlue,
                    side: BorderSide(color: darkBlue.withOpacity(0.6)),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SeleccionarHabitacionModal(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar habitación'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (habitaciones.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasoResumenHabitacionesPage(
                          idCotizacion: idCotizacion,
                          nombreCliente: nombreCliente,
                          ciCliente: ciCliente,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Continuar'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}