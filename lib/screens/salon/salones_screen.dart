import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../providers/salones_provider.dart';
import 'salon_form.dart';

class SalonesScreen extends ConsumerWidget {
  const SalonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonesAsync = ref.watch(salonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salones'),
      ),
      body: salonesAsync.when(
        data: (salones) {
          if (salones.isEmpty) {
            return const Center(child: Text('No hay salones registrados.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: salones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final salon = salones[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(salon.nombre),
                  subtitle: Text(
                    'Mesas: ${salon.capacidadMesas}, Sillas: ${salon.capacidadSillas}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'editar') {
                        await showDialog(
                          context: context,
                          builder: (_) => SalonForm(
                            salon: salon,
                          ),
                        );
                      } else if (value == 'eliminar') {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('¿Eliminar salón?'),
                            content: const Text('Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await ref.read(salonesProvider.notifier).eliminarSalon(salon.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const SalonForm(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar salón'),
      ),
    );
  }
}