import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habitacion.dart';
import '../../models/establecimiento.dart';
import '../../providers/establecimiento_provider.dart';
import '../../providers/habitaciones_provider.dart';
import 'habitacion_form.dart';

class HabitacionesScreen extends ConsumerStatefulWidget {
  const HabitacionesScreen({super.key});

  @override
  ConsumerState<HabitacionesScreen> createState() => _HabitacionesScreenState();
}

class _HabitacionesScreenState extends ConsumerState<HabitacionesScreen> {
  String? establecimientoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final establecimientosAsync = ref.watch(establecimientosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Habitaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            establecimientosAsync.when(
              data: (establecimientos) {
                if (establecimientos.isEmpty) {
                  return const Text('No hay establecimientos disponibles.');
                }

                return DropdownButtonFormField<String>(
                  value: establecimientoSeleccionado,
                  hint: const Text('Selecciona un establecimiento'),
                  items: establecimientos.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(e.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      establecimientoSeleccionado = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            if (establecimientoSeleccionado != null)
              Expanded(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final resultado = await showDialog<Habitacion>(
                          context: context,
                          builder: (_) => HabitacionForm(
                            idEstablecimiento: establecimientoSeleccionado!,
                          ),
                        );

                        if (resultado != null) {
                          ref
                              .read(habitacionesProvider(establecimientoSeleccionado!).notifier)
                              .cargarHabitaciones();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Habitación'),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ref.watch(habitacionesProvider(establecimientoSeleccionado!)).when(
                            data: (habitaciones) {
                              if (habitaciones.isEmpty) {
                                return const Text('No hay habitaciones registradas.');
                              }

                              return ListView.builder(
                                itemCount: habitaciones.length,
                                itemBuilder: (context, index) {
                                  final hab = habitaciones[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(hab.nombre),
                                      subtitle: Text('Capacidad: ${hab.capacidad}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () async {
                                              final resultado = await showDialog<Habitacion>(
                                                context: context,
                                                builder: (_) => HabitacionForm(
                                                  idEstablecimiento: establecimientoSeleccionado!,
                                                  habitacionExistente: hab,
                                                ),
                                              );
                                              if (resultado != null) {
                                                ref
                                                    .read(habitacionesProvider(
                                                            establecimientoSeleccionado!)
                                                        .notifier)
                                                    .cargarHabitaciones();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Eliminar habitación'),
                                                  content: const Text(
                                                      '¿Estás seguro de eliminar esta habitación?'),
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

                                              if (confirm == true) {
                                                await ref
                                                    .read(habitacionesProvider(
                                                            establecimientoSeleccionado!)
                                                        .notifier)
                                                    .eliminarHabitacion(hab.id);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}