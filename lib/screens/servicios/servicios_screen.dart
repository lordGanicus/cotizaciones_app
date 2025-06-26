import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/servicios_provider.dart';
import '../../models/servicio_incluido.dart';
import 'servicio_form.dart';

class ServiciosScreen extends ConsumerWidget {
  const ServiciosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicios = ref.watch(serviciosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios Incluidos'),
        centerTitle: true,
      ),
      body: servicios.isEmpty
          ? const Center(child: Text('No hay servicios registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: servicios.length,
              itemBuilder: (context, index) {
                final servicio = servicios[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(servicio.nombre),
                    subtitle: Text(servicio.descripcion),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => ServicioForm(servicio: servicio),
                          );
                        } else if (value == 'delete') {
                          _confirmarEliminacion(context, ref, servicio.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const ServicioForm(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar servicio?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(serviciosProvider.notifier).eliminarServicio(id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}