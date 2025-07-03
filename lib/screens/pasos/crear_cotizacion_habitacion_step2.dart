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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);

    final totalCotizacion = habitaciones.fold<double>(
      0.0,
      (sum, hab) => sum + (hab.tarifa * hab.cantidadNoches * hab.cantidad),
    );

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 2 - Agregar Habitaciones'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Cliente: $nombreCliente\nCI: $ciCliente',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: habitaciones.isEmpty
                  ? const Center(child: Text('No hay habitaciones agregadas aún.'))
                  : ListView.builder(
                      itemCount: habitaciones.length,
                      itemBuilder: (context, index) {
                        final hab = habitaciones[index];
                        final subtotal = hab.tarifa * hab.cantidadNoches * hab.cantidad;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(hab.nombreHabitacion, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Cantidad: ${hab.cantidad}\n'
                              'Ingreso: ${_formatDate(hab.fechaIngreso)}\n'
                              'Salida: ${_formatDate(hab.fechaSalida)}\n'
                              'Noches: ${hab.cantidadNoches}\n'
                              'Tarifa: Bs ${hab.tarifa.toStringAsFixed(2)}',
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

            const SizedBox(height: 12),

            Text('Total: Bs ${totalCotizacion.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  label: const Text('Agregar Habitación'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botón continuar solo si hay habitaciones
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
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}