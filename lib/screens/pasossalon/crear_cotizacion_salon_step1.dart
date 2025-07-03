import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/salon.dart';
import '../../../providers/salones_provider.dart';
import 'crear_cotizacion_salon_step2.dart'; // Importa el paso 2

class CrearCotizacionSalonStep1 extends ConsumerWidget {
  final String idEstablecimiento;

  const CrearCotizacionSalonStep1({
    super.key,
    required this.idEstablecimiento,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonesAsync = ref.watch(salonesProvider); // No pasamos parámetro
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 1: Seleccionar Salón'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: salonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar salones: $e')),
        data: (salones) {
          final salonesDelEstablecimiento = salones
              .where((s) => s.id.startsWith(idEstablecimiento)) // Aquí filtras los salones del establecimiento
              .toList();

          if (salonesDelEstablecimiento.isEmpty) {
            return const Center(child: Text('No hay salones disponibles.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salonesDelEstablecimiento.length,
            itemBuilder: (context, index) {
              final salon = salonesDelEstablecimiento[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salon.nombre, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Capacidad: ${salon.capacidadMesas} mesas, ${salon.capacidadSillas} sillas'),
                      const SizedBox(height: 8),
                      Text(salon.descripcion ?? '', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 24),
                      Text('Servicios incluidos:', style: Theme.of(context).textTheme.titleMedium),
                      ...salon.servicios.map((s) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check, color: Colors.green),
                            title: Text(s.nombre),
                          )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navegar al Paso 2, pasando el salón seleccionado
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CrearCotizacionSalonStep2(
                                salonSeleccionado: salon,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continuar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}