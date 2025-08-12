import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habitacion.dart';
import '../../models/establecimiento.dart';
import '../../providers/establecimiento_provider.dart';
import '../../providers/habitaciones_provider.dart';
import '../../providers/usuario_provider.dart';
import 'habitacion_form.dart';

class HabitacionesScreen extends ConsumerStatefulWidget {
  const HabitacionesScreen({super.key});

  @override
  ConsumerState<HabitacionesScreen> createState() => _HabitacionesScreenState();
}

class _HabitacionesScreenState extends ConsumerState<HabitacionesScreen> {
  String? establecimientoSeleccionado;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seleccionarEstablecimientoAutomatico();
  }

  Future<void> _seleccionarEstablecimientoAutomatico() async {
    final usuario = await ref.read(usuarioActualProvider.future);

    if (usuario.rolNombre?.toLowerCase() == 'gerente' && usuario.idEstablecimiento != null) {
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
        title: const Text('Gestión de Habitaciones'),
        backgroundColor: const Color(0xFF2D4059),
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFFAFAFA),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de selección de establecimiento
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

                  final usuario = ref.read(usuarioActualProvider);
                  if (usuario.asData?.value.rolNombre?.toLowerCase() == 'gerente' &&
                      usuario.asData?.value.idEstablecimiento != null) {
                    final est = establecimientos.firstWhere(
                        (e) => e.id == usuario.asData!.value.idEstablecimiento!,
                        orElse: () => Establecimiento(id: '', nombre: 'No disponible'));
                    return Text(
                      'Establecimiento: ${est.nombre}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D4059),
                      ),
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
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Selecciona un establecimiento'),
                    items: establecimientos.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          e.nombre,
                          style: const TextStyle(fontSize: 15),
                        ),
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
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),

            const SizedBox(height: 24),

            if (establecimientoSeleccionado != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón de nueva habitación
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
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
                            'Nueva Habitación',
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

                    // Lista de habitaciones
                    Expanded(
                      child: ref.watch(habitacionesProvider(establecimientoSeleccionado!)).when(
                        data: (habitaciones) {
                          if (habitaciones.isEmpty) {
                            return Center(
                              child: Text(
                                'No hay habitaciones registradas.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: habitaciones.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final hab = habitaciones[index];
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  title: Text(
                                    hab.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF2D4059),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Capacidad: ${hab.capacidad}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 22),
                                          color: const Color(0xFF2D4059),
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
                                          icon: const Icon(Icons.delete, size: 22),
                                          color: Colors.red[400],
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                  'Eliminar habitación',
                                                  style: TextStyle(
                                                    color: Color(0xFF2D4059),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: const Text(
                                                    '¿Estás seguro de eliminar esta habitación?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context, false),
                                                    child: const Text(
                                                      'Cancelar',
                                                      style: TextStyle(
                                                          color: Color(0xFF2D4059)),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red[400],
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(context, true),
                                                    child: const Text(
                                                      'Eliminar',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
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