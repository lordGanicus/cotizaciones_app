// lib/screens/pasossalon/crear_cotizacion_salon_step3.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'crear_cotizacion_salon_step4.dart';

class Paso3CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;  // <-- agregado

  const Paso3CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,  
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaSalones = ref.watch(cotizacionSalonProvider);

    if (listaSalones.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Cotización no iniciada')),
      );
    }

    final cotizacion = listaSalones[0];
    final List<ItemAdicional> adicionales = cotizacion.itemsAdicionales;

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 3: Ítems adicionales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧾 Ítems adicionales:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoAdicional(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (adicionales.isEmpty)
              const Text('No hay ítems adicionales agregados.'),
            ...adicionales.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(item.descripcion),
                  subtitle: Text('${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} Bs'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${item.subtotal.toStringAsFixed(2)} Bs'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final notifier = ref.read(cotizacionSalonProvider.notifier);
                          final nuevosAdicionales = List<ItemAdicional>.from(cotizacion.itemsAdicionales)
                            ..removeAt(index);

                          final salonActualizado = cotizacion.copyWith(
                            itemsAdicionales: nuevosAdicionales,
                          );

                          notifier.actualizarSalon(0, salonActualizado);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Paso4CotizacionSalonPage(
                      idCotizacion: idCotizacion,
                      idEstablecimiento: idEstablecimiento,
                      idUsuario: idUsuario,  // <-- paso aquí también
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente paso'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAdicional(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Agregar ítem adicional'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
                TextField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio unitario (Bs)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final desc = descController.text.trim();
                final cantidad = int.tryParse(cantidadController.text.trim()) ?? 0;
                final precio = double.tryParse(precioController.text.trim()) ?? 0;

                if (desc.isNotEmpty && cantidad > 0 && precio > 0) {
                  final notifier = ref.read(cotizacionSalonProvider.notifier);
                  final listaSalones = ref.read(cotizacionSalonProvider);
                  if (listaSalones.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  final cotizacion = listaSalones[0];
                  final nuevosAdicionales = List<ItemAdicional>.from(cotizacion.itemsAdicionales)
                    ..add(
                      ItemAdicional(
                        descripcion: desc,
                        cantidad: cantidad,
                        precioUnitario: precio,
                      ),
                    );

                  final salonActualizado = cotizacion.copyWith(
                    itemsAdicionales: nuevosAdicionales,
                  );

                  notifier.actualizarSalon(0, salonActualizado);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos correctamente.')),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
