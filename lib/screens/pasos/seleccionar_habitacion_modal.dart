import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeleccionarHabitacionModal extends ConsumerStatefulWidget {
  const SeleccionarHabitacionModal({super.key});

  @override
  ConsumerState<SeleccionarHabitacionModal> createState() => _SeleccionarHabitacionModalState();
}

class _SeleccionarHabitacionModalState extends ConsumerState<SeleccionarHabitacionModal> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> habitaciones = [];
  String? habitacionSeleccionadaId;

  int cantidad = 1;
  DateTime? fechaIngreso;
  DateTime? fechaSalida;
  double? tarifa;

  bool isLoading = true;
  String? error;

  late TextEditingController cantidadController;
  late TextEditingController tarifaController;

  @override
  void initState() {
    super.initState();
    cantidadController = TextEditingController(text: cantidad.toString());
    tarifaController = TextEditingController();
    _cargarHabitacionesUsuario();
  }

  @override
  void dispose() {
    cantidadController.dispose();
    tarifaController.dispose();
    super.dispose();
  }

  Future<void> _cargarHabitacionesUsuario() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no logueado';

      // Obtener id_establecimiento del usuario
      final usuarioRes = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioRes['id_establecimiento'] as String;

      // Traer habitaciones del establecimiento
      final habitacionesRes = await supabase
          .from('habitaciones')
          .select()
          .eq('id_establecimiento', idEstablecimiento);

      setState(() {
        habitaciones = List<Map<String, dynamic>>.from(habitacionesRes);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando habitaciones: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFechaIngreso() async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaIngreso ?? ahora,
      firstDate: ahora,
      lastDate: DateTime(ahora.year + 2),
    );
    if (picked != null) {
      setState(() {
        fechaIngreso = picked;
        if (fechaSalida != null && fechaSalida!.isBefore(picked)) {
          fechaSalida = null;
        }
      });
    }
  }

  Future<void> _seleccionarFechaSalida() async {
    if (fechaIngreso == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: fechaSalida ?? fechaIngreso!.add(const Duration(days: 1)),
      firstDate: fechaIngreso!,
      lastDate: DateTime(fechaIngreso!.year + 2),
    );
    if (picked != null) {
      setState(() {
        fechaSalida = picked;
      });
    }
  }

  int get cantidadNoches {
    if (fechaIngreso != null && fechaSalida != null) {
      return fechaSalida!.difference(fechaIngreso!).inDays;
    }
    return 0;
  }

  void _agregarHabitacion() {
    if (habitacionSeleccionadaId == null ||
        fechaIngreso == null ||
        fechaSalida == null ||
        tarifa == null ||
        tarifa! <= 0 ||
        cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos y tarifa válida')),
      );
      return;
    }

    final habitacion = habitaciones.firstWhere((h) => h['id'] == habitacionSeleccionadaId);
    final nombreHabitacion = habitacion['nombre'] as String;

    final cotizacion = CotizacionHabitacion(
      nombreHabitacion: nombreHabitacion,
      cantidad: cantidad,
      fechaIngreso: fechaIngreso!,
      fechaSalida: fechaSalida!,
      cantidadNoches: cantidadNoches,
      tarifa: tarifa!,
    );

    ref.read(cotizacionHabitacionProvider.notifier).agregarHabitacion(cotizacion);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('Agregar habitación a la cotización'),
      content: isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : error != null
              ? Text(error!)
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: habitacionSeleccionadaId,
                        decoration: InputDecoration(
                          labelText: 'Tipo de habitación',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: habitaciones
                            .map<DropdownMenuItem<String>>(
                              (h) => DropdownMenuItem<String>(
                                value: h['id'] as String,
                                child: Text(h['nombre'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => habitacionSeleccionadaId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cantidadController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final val = int.tryParse(v);
                                if (val != null && val > 0) {
                                  setState(() => cantidad = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tarifaController,
                              decoration: InputDecoration(
                                labelText: 'Tarifa (Bs por noche)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) {
                                final val = double.tryParse(v);
                                if (val != null && val > 0) {
                                  setState(() => tarifa = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text(fechaIngreso != null ? DateFormat('dd/MM/yyyy').format(fechaIngreso!) : 'Fecha de ingreso'),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _seleccionarFechaIngreso,
                        ),
                      ),
                      ListTile(
                        title: Text(fechaSalida != null ? DateFormat('dd/MM/yyyy').format(fechaSalida!) : 'Fecha de salida'),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: fechaIngreso == null ? null : _seleccionarFechaSalida,
                        ),
                      ),
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _agregarHabitacion,
          child: const Text('Agregar'),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
      ],
    );
  }
}