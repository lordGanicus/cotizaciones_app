import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/models/salon.dart';
import '/providers/salones_provider.dart';
import '/providers/servicios_provider.dart';
import '/providers/refrigerios_provider.dart';
import 'package:cotizaciones_app/screens/salon/salon_form.dart';

class SalonesScreen extends ConsumerStatefulWidget {
  const SalonesScreen({super.key});

  @override
  ConsumerState<SalonesScreen> createState() => _SalonesScreenState();
}

class _SalonesScreenState extends ConsumerState<SalonesScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        ref.read(salonesProvider.notifier).cargarSalones(),
        ref.read(serviciosProvider.notifier).cargarServicios(),
        ref.read(refrigeriosProvider.notifier).cargarRefrigerios(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarFormulario([Salon? salon]) {
    showDialog(
      context: context,
      builder: (_) => SalonForm(salon: salon),
    );
  }

  void _confirmarEliminacion(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar salón?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(salonesProvider.notifier).eliminarSalon(id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salonesAsync = ref.watch(salonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          )
        ],
      ),
      body: Builder(builder: (context) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(child: Text('Error: $_error'));
        }
        return salonesAsync.when(
          data: (salones) {
            if (salones.isEmpty) {
              return const Center(child: Text('No hay salones registrados.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: salones.length,
              itemBuilder: (context, index) {
                final s = salones[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(s.nombre),
                    subtitle: Text(
                      'Mesas: ${s.capacidadMesas}, Sillas: ${s.capacidadSillas}\n'
                      'Servicios: ${s.servicios.map((e) => e.nombre).join(', ')}\n'
                      'Refrigerios: ${s.refrigerios.map((e) => e.nombre).join(', ')}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _mostrarFormulario(s);
                        } else if (value == 'delete') {
                          _confirmarEliminacion(s.id);
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
