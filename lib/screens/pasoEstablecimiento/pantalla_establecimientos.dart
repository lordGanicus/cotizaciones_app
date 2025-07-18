import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/Mestablecimiento.dart';
import '../../providers/pestablecimiento.dart';
import 'form_establecimiento.dart';
import 'pantalla_subestablecimientos.dart';

class PantallaEstablecimientos extends ConsumerWidget {
  const PantallaEstablecimientos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final establecimientosAsync = ref.watch(establecimientosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Establecimientos')),
      body: establecimientosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) => ListView.builder(
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final est = lista[index];
            return ListTile(
              leading: est.logotipoUrl != null
                  ? Image.network(
                      est.logotipoUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.business, size: 50),
                    )
                  : const Icon(Icons.business, size: 50),
              title: Text(est.nombre),
              subtitle: Text(est.membreteUrl ?? 'Sin membrete'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaSubestablecimientos(
                      idEstablecimiento: est.id,
                      nombreEstablecimiento: est.nombre,
                    ),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => FormEstablecimiento(
                        esEditar: true,
                        establecimiento: est,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmarEliminar(context, ref, est.id),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const FormEstablecimiento(esEditar: false),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, String idEstablecimiento) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('¿Eliminar establecimiento?'),
              content: const Text('Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          setState(() => _isDeleting = true);
                          try {
                            await ref
                                .read(establecimientosProvider.notifier)
                                .eliminarEstablecimiento(idEstablecimiento);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error al eliminar: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => _isDeleting = false);
                          }
                        },
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}