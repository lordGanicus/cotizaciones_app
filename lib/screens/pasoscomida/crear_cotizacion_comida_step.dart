import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/item_comida.dart';
import '../../providers/item_comida_provider.dart';
import 'agregar_item_comida_modal.dart';
import 'resumen_final_factura.dart';

class CrearCotizacionComidaStep extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const CrearCotizacionComidaStep({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemComidaProvider);
    final total = ref.watch(itemComidaProvider.notifier).calcularTotal();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotización de Comida'),
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
              child: items.isEmpty
                  ? const Center(child: Text('No se han agregado ítems de comida.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            title: Text(item.nombreProducto,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Cantidad: ${item.cantidad}\nPrecio unitario: Bs ${item.precioUnitario.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              'Bs ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            isThreeLine: true,
                            leading: CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Text('${index + 1}',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Eliminar ítem'),
                                  content: Text('¿Eliminar "${item.nombreProducto}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(itemComidaProvider.notifier).eliminarItem(item.id);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: Bs ${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AgregarItemComidaModal(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar ítem'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agrega al menos un ítem antes de continuar'),
                          ),
                        );
                        return;
                      }

                      try {
                        final supabase = Supabase.instance.client;

                        for (final item in items) {
                          await supabase.from('items_cotizacion').insert({
                            'id_cotizacion': idCotizacion,
                            'servicio': item.nombreProducto,
                            'cantidad': item.cantidad,
                            'precio_unitario': item.precioUnitario,
                            'detalles': {
                              'tipo': 'comida',
                            },
                          });
                        }

                        ref.read(itemComidaProvider.notifier).limpiarItems();

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResumenFinalComidaPage(
                                idCotizacion: idCotizacion,
                                nombreCliente: nombreCliente,
                                ciCliente: ciCliente,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar los ítems: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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