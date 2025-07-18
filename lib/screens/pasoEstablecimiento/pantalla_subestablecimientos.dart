import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/Msubestablecimiento.dart';
import '../../providers/pestablecimiento.dart';
import 'form_subestablecimiento.dart';

class PantallaSubestablecimientos extends ConsumerWidget {
  final String idEstablecimiento;
  final String nombreEstablecimiento;

  const PantallaSubestablecimientos({
    super.key,
    required this.idEstablecimiento,
    required this.nombreEstablecimiento,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subestablecimientosAsync =
        ref.watch(subestablecimientosProvider(idEstablecimiento));

    return Scaffold(
      appBar: AppBar(title: Text('Subestablecimientos de $nombreEstablecimiento')),
      body: subestablecimientosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) => lista.isEmpty
            ? const Center(child: Text('No hay subestablecimientos registrados.'))
            : ListView.builder(
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final sub = lista[index];
                  return ListTile(
                    leading: sub.logotipo != null
                        ? Image.network(
                            sub.logotipo!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.apartment, size: 50),
                          )
                        : const Icon(Icons.apartment, size: 50),
                    title: Text(sub.nombre),
                    subtitle: Text(sub.membrete ?? 'Sin membrete'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => FormSubestablecimiento(
                              esEditar: true,
                              subestablecimiento: sub,
                              idEstablecimiento: idEstablecimiento,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _confirmarEliminar(context, ref, sub.id),
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
          builder: (_) => FormSubestablecimiento(
            esEditar: false,
            idEstablecimiento: idEstablecimiento,
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, String idSubestablecimiento) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('¿Eliminar subestablecimiento?'),
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
                                .read(
                                    subestablecimientosProvider(idEstablecimiento)
                                        .notifier)
                                .eliminarSubestablecimiento(idSubestablecimiento);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al eliminar: $e')),
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