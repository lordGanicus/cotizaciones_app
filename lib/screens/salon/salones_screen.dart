import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../providers/salones_provider.dart';
import 'salon_form.dart';

class SalonesScreen extends ConsumerWidget {
  const SalonesScreen({super.key});

  final Color _azulOscuro = const Color(0xFF2D4059);
  final Color _verdeMenta = const Color(0xFF00B894);
  final Color _fondoClaro = const Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonesAsync = ref.watch(salonesProvider);

    return Scaffold(
      backgroundColor: _fondoClaro,
      appBar: AppBar(
        backgroundColor: _azulOscuro,
        title: const Text('Salones'),
        centerTitle: true,
        elevation: 4,
      ),
      body: salonesAsync.when(
        data: (salones) {
          if (salones.isEmpty) {
            return Center(
              child: Text(
                'No hay salones registrados.',
                style: TextStyle(color: _azulOscuro, fontSize: 16),
              ),
            );
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    salon.nombre,
                    style: TextStyle(
                      color: _azulOscuro,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Mesas: ${salon.capacidadMesas}, Sillas: ${salon.capacidadSillas}',
                    style: TextStyle(color: _azulOscuro.withOpacity(0.7)),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: _azulOscuro),
                    onSelected: (value) async {
                      if (value == 'editar') {
                        await showDialog(
                          context: context,
                          builder: (_) => SalonForm(salon: salon),
                        );
                      } else if (value == 'eliminar') {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '¿Eliminar salón?',
                              style: TextStyle(color: _azulOscuro),
                            ),
                            content: const Text('Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancelar', style: TextStyle(color: _azulOscuro)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _verdeMenta,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await ref.read(salonesProvider.notifier).eliminarSalon(salon.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Salón eliminado'),
                              backgroundColor: _verdeMenta,
                            ),
                          );
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
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _verdeMenta,
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
