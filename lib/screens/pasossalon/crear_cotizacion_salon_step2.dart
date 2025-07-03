import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/salon.dart';
import '../../../models/refrigerio.dart';
import '../../../providers/cotizacion_salon_providers.dart';
import 'paso3_resumen_salon.dart'; // Importa el paso 3 para navegar

class CrearCotizacionSalonStep2 extends ConsumerWidget {
  final Salon salonSeleccionado;

  const CrearCotizacionSalonStep2({
    super.key,
    required this.salonSeleccionado,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refrigeriosSeleccionados = ref.watch(refrigeriosSeleccionadosProvider);
    final notifier = ref.read(refrigeriosSeleccionadosProvider.notifier);

    final refrigerios = salonSeleccionado.refrigerios;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 2: Seleccionar Refrigerios'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refrigerios disponibles en el salón:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '"${salonSeleccionado.nombre}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            refrigerios.isEmpty
                ? Expanded(
                    child: Center(
                      child: Text(
                        'Este salón no tiene refrigerios disponibles.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.separated(
                      itemCount: refrigerios.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final refrigerio = refrigerios[index];
                        final seleccionado = refrigeriosSeleccionados.contains(refrigerio);

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            final actual = [...refrigeriosSeleccionados];
                            if (actual.contains(refrigerio)) {
                              actual.remove(refrigerio);
                            } else {
                              actual.add(refrigerio);
                            }
                            notifier.state = actual;
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: seleccionado ? 6 : 2,
                            shadowColor: seleccionado ? primaryColor.withOpacity(0.4) : Colors.black12,
                            color: seleccionado ? primaryColor.withOpacity(0.12) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    seleccionado ? Icons.check_circle : Icons.circle_outlined,
                                    color: seleccionado ? primaryColor : Colors.grey[400],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          refrigerio.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          refrigerio.descripcion,
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Precio: Bs ${refrigerio.precioUnitario.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: refrigerios.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CrearCotizacionSalonStep3(
                                salonSeleccionado: salonSeleccionado,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
