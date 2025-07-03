import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/salon.dart';
import '../../../models/refrigerio.dart';
import '../../../providers/cotizacion_salon_providers.dart';
import 'paso4_confirmacion_cotizacion.dart'; // Importar paso 4

class CrearCotizacionSalonStep3 extends ConsumerWidget {
  final Salon salonSeleccionado;

  const CrearCotizacionSalonStep3({
    super.key,
    required this.salonSeleccionado,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Refrigerio> refrigeriosSeleccionados = ref.watch(refrigeriosSeleccionadosProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final totalRefrigerios = refrigeriosSeleccionados.fold<double>(
      0,
      (sum, r) => sum + r.precioUnitario,
    );

    final serviciosIncluidos = salonSeleccionado.servicios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 3: Resumen de la Cotización'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salón seleccionado:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salonSeleccionado.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Capacidad mesas: ${salonSeleccionado.capacidadMesas}'),
                    Text('Capacidad sillas: ${salonSeleccionado.capacidadSillas}'),
                    if (salonSeleccionado.descripcion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Descripción: ${salonSeleccionado.descripcion}'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Servicios incluidos:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            serviciosIncluidos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No hay servicios incluidos para este salón.'),
                  )
                : Expanded(
                    child: ListView.separated(
                      itemCount: serviciosIncluidos.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final servicio = serviciosIncluidos[index];
                        return ListTile(
                          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                          title: Text(servicio.nombre),
                          subtitle: Text(servicio.descripcion),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),

            Text(
              'Refrigerios seleccionados:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            refrigeriosSeleccionados.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No se seleccionaron refrigerios.'),
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.separated(
                      itemCount: refrigeriosSeleccionados.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final refrigerio = refrigeriosSeleccionados[index];
                        return ListTile(
                          leading: const Icon(Icons.local_drink, color: Colors.blueAccent),
                          title: Text(refrigerio.nombre),
                          subtitle: Text(refrigerio.descripcion),
                          trailing: Text('Bs ${refrigerio.precioUnitario.toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 16),

            Text(
              'Total refrigerios: Bs ${totalRefrigerios.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a paso 4 confirmación
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Paso4ConfirmacionCotizacionPage(
                          idCotizacion: '1234', // Aquí pasa el ID real de la cotización si lo tienes
                          nombreCliente: 'Nombre Cliente', // Aquí el nombre real
                          ciCliente: '1234567', // Y el CI real
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
