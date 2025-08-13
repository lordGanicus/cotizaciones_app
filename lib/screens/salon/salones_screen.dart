import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../models/establecimiento.dart';
import '../../providers/establecimiento_provider.dart';
import '../../providers/salones_provider.dart';
import '../../providers/usuario_provider.dart';
import 'salon_form.dart';

class SalonesScreen extends ConsumerStatefulWidget {
  const SalonesScreen({super.key});

  @override
  ConsumerState<SalonesScreen> createState() => _SalonesScreenState();
}

class _SalonesScreenState extends ConsumerState<SalonesScreen> {
  String? establecimientoSeleccionado;

  final Color _azulOscuro = const Color(0xFF2D4059);
  final Color _verdeMenta = const Color(0xFF00B894);
  final Color _fondoClaro = const Color(0xFFFAFAFA);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seleccionarEstablecimientoAutomatico();
  }

  Future<void> _seleccionarEstablecimientoAutomatico() async {
    final usuario = await ref.read(usuarioActualProvider.future);

    if (usuario.idEstablecimiento != null &&
        usuario.idEstablecimiento!.isNotEmpty) {
      setState(() {
        establecimientoSeleccionado = usuario.idEstablecimiento!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final establecimientosAsync = ref.watch(establecimientosFiltradosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Salones'),
        backgroundColor: _azulOscuro,
        elevation: 4,
        centerTitle: true,
        actions: [
          // Botón de refrescar con texto "Actualizar"
          TextButton.icon(
            onPressed: () {
              // Refresca los providers
              ref.refresh(establecimientosFiltradosProvider);
              if (establecimientoSeleccionado != null) {
                ref.refresh(salonesPorEstablecimientoProvider(
                    establecimientoSeleccionado!));
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            label: const Text(
              'Actualizar',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: _fondoClaro,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown de establecimientos
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: establecimientosAsync.when(
                data: (establecimientos) {
                  if (establecimientos.isEmpty) {
                    return const Text(
                      'No hay establecimientos disponibles.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: establecimientoSeleccionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _fondoClaro,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Selecciona un establecimiento'),
                    items: establecimientos.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombre,
                            style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        establecimientoSeleccionado = value;
                      });
                    },
                    style: const TextStyle(color: Color(0xFF2D4059)),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 24),

            // Lista de salones
            if (establecimientoSeleccionado != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón de nuevo salón
                    ElevatedButton(
                      onPressed: () async {
                        final resultado = await showDialog<Salon>(
                          context: context,
                          builder: (_) => SalonForm(
                            idEstablecimientoInicial:
                                establecimientoSeleccionado!,
                          ),
                        );

                        if (resultado != null) {
                          ref.refresh(salonesPorEstablecimientoProvider(
                              establecimientoSeleccionado!));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verdeMenta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Nuevo Salón',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lista de salones
                    Expanded(
                      child: ref
                          .watch(salonesPorEstablecimientoProvider(
                              establecimientoSeleccionado!))
                          .when(
                            data: (salones) {
                              if (salones.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No hay salones registrados.',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16),
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: salones.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final salon = salones[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                      title: Text(
                                        salon.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF2D4059),
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Mesas: ${salon.capacidadMesas}, Sillas: ${salon.capacidadSillas}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14),
                                        ),
                                      ),
                                      trailing: SizedBox(
                                        width: 100,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 22),
                                              color: const Color(0xFF2D4059),
                                              onPressed: () async {
                                                final resultado =
                                                    await showDialog<Salon>(
                                                  context: context,
                                                  builder: (_) => SalonForm(
                                                    idEstablecimientoInicial:
                                                        establecimientoSeleccionado!,
                                                    salon: salon,
                                                  ),
                                                );

                                                if (resultado != null) {
                                                  ref.refresh(
                                                      salonesPorEstablecimientoProvider(
                                                          establecimientoSeleccionado!));
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 22),
                                              color: Colors.red[400],
                                              onPressed: () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: const Text(
                                                      'Eliminar salón',
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xFF2D4059),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    content: const Text(
                                                        '¿Estás seguro de eliminar este salón?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFF2D4059)),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red[
                                                                        400]),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                                    ],
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                    ),
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  await ref
                                                      .read(salonesProvider
                                                          .notifier)
                                                      .eliminarSalon(salon.id);
                                                  ref.refresh(
                                                      salonesPorEstablecimientoProvider(
                                                          establecimientoSeleccionado!));
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF00B894))),
                            error: (e, _) => Center(
                                child: Text('Error: $e',
                                    style: const TextStyle(color: Colors.red))),
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
