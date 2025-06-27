import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/refrigerio.dart';
import '../../providers/refrigerios_provider.dart';
import 'refrigerio_form.dart';

class RefrigeriosScreen extends ConsumerWidget {
  const RefrigeriosScreen({super.key});

  void _mostrarFormulario(BuildContext context, WidgetRef ref, [Refrigerio? refrigerio]) {
    showDialog(
      context: context,
      builder: (_) => RefrigerioForm(refrigerio: refrigerio),
    );
  }

  void _confirmarEliminacion(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar refrigerio?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(refrigeriosProvider.notifier).eliminarRefrigerio(id);
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refrigeriosAsync = ref.watch(refrigeriosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refrigerios'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(refrigeriosProvider.notifier).cargarRefrigerios(),
            tooltip: 'Actualizar',
          )
        ],
      ),
      body: refrigeriosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (refrigerios) {
          if (refrigerios.isEmpty) {
            return const Center(child: Text('No hay refrigerios registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: refrigerios.length,
            itemBuilder: (context, index) {
              final r = refrigerios[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: ListTile(
                  title: Text(r.nombre),
                  subtitle: Text(
                    '${r.descripcion}\n\Bs.${r.precioUnitario.toStringAsFixed(2)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _mostrarFormulario(context, ref, r);
                      } else if (value == 'delete') {
                        _confirmarEliminacion(context, ref, r.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
