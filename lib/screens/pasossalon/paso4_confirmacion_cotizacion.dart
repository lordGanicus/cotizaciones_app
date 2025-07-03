import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/salon.dart';
import '../../../models/refrigerio.dart';
import '../../../providers/cotizacion_salon_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Paso 5: Resumen final
import 'resumen_final_cotizacion_salon.dart';

class Paso4ConfirmacionCotizacionPage extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const Paso4ConfirmacionCotizacionPage({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Salon? salonSeleccionado = ref.watch(salonSeleccionadoProvider);
    final List<Refrigerio> refrigeriosSeleccionados = ref.watch(refrigeriosSeleccionadosProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (salonSeleccionado == null) {
      return const Scaffold(
        body: Center(child: Text('No se ha seleccionado un salón.')),
      );
    }

    final totalRefrigerios = refrigeriosSeleccionados.fold<double>(
      0,
      (sum, r) => sum + r.precioUnitario,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Cotización'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: $nombreCliente\nCI: $ciCliente',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Salón: ${salonSeleccionado.nombre}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Refrigerios seleccionados:', style: const TextStyle(fontWeight: FontWeight.bold)),
            refrigeriosSeleccionados.isEmpty
                ? const Text('No se seleccionaron refrigerios.')
                : Expanded(
                    child: ListView.separated(
                      itemCount: refrigeriosSeleccionados.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final r = refrigeriosSeleccionados[index];
                        return ListTile(
                          title: Text(r.nombre),
                          trailing: Text('Bs ${r.precioUnitario.toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 12),
            Text(
              'Total refrigerios: Bs ${totalRefrigerios.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
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
                  onPressed: () async {
                    final supabase = Supabase.instance.client;

                    try {
                      // Insertar ítems
                      for (final r in refrigeriosSeleccionados) {
                        await supabase.from('items_cotizacion_salon').insert({
                          'id_cotizacion': idCotizacion,
                          'id_refrigerio': r.id,
                          'cantidad': 1,
                          'precio_unitario': r.precioUnitario,
                          'subtotal': r.precioUnitario,
                          'detalles': {'tipo': 'refrigerio'},
                        });
                      }

                      // Limpiar selección
                      ref.read(refrigeriosSeleccionadosProvider.notifier).state = [];

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cotización guardada correctamente')),
                        );

                        // Navegar al Paso 5: Resumen final
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ResumenFinalCotizacionSalonPage(
                              idCotizacion: idCotizacion,
                              nombreCliente: nombreCliente,
                              ciCliente: ciCliente,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar cotización: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}