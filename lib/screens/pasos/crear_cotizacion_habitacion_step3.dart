import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'crear_cotizacion_habitacion_step4.dart';
import 'seleccionar_habitacion_modal.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 3 - Resumen de habitaciones'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SeleccionarHabitacionModal(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar habitación'),
            ),
            const SizedBox(height: 16),

            habitaciones.isEmpty
                ? const Text('No se han agregado habitaciones.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: habitaciones.length,
                      itemBuilder: (context, index) {
                        final hab = habitaciones[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              hab.nombreHabitacion,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${hab.cantidad} habs · ${hab.cantidadNoches} noches\n'
                              'Ingreso: ${_formatDate(hab.fechaIngreso)} · Salida: ${_formatDate(hab.fechaSalida)}\n'
                              'Tarifa: Bs ${hab.tarifa.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              'Bs ${hab.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            isThreeLine: true,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 16),

            if (habitaciones.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'Bs ${_calcularTotal(habitaciones).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            if (habitaciones.isNotEmpty)
              ElevatedButton.icon(
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}