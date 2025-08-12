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
  // Colores del diseño
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D4059);
  static const Color textSecondary = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFE74C3C);

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> habitaciones = [];
  String? habitacionSeleccionadaId;

  int cantidad = 1;
  DateTime? fechaIngreso;
  DateTime? fechaSalida;
  double? tarifa;

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarHabitacionesUsuario();
  }

  Future<void> _cargarHabitacionesUsuario() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no logueado';

      final usuarioRes = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioRes['id_establecimiento'] as String;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
    if (habitacionSeleccionadaId == null || fechaIngreso == null || fechaSalida == null || tarifa == null || tarifa! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor complete todos los campos y tarifa válida'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: errorColor,
        ),
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
    final borderRadius = BorderRadius.circular(12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: lightBackground,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar habitación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    ),
                  )
                : error != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.1),
                          borderRadius: borderRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: errorColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                error!,
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              value: habitacionSeleccionadaId,
                              decoration: InputDecoration(
                                labelText: 'Tipo de habitación',
                                labelStyle: TextStyle(color: textSecondary),
                                floatingLabelStyle: TextStyle(color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: borderRadius,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: borderRadius,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: borderRadius,
                                  borderSide: BorderSide(
                                    color: primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: cardBackground,
                              ),
                              items: habitaciones
                                  .map((h) => DropdownMenuItem<String>(
                                        value: h['id'],
                                        child: Text(
                                          h['nombre'],
                                          style: const TextStyle(color: textPrimary),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => habitacionSeleccionadaId = v),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Cantidad de hab.',
                                      labelStyle: TextStyle(color: textSecondary),
                                      floatingLabelStyle: TextStyle(color: primaryGreen),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(
                                          color: primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: cardBackground,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      final val = int.tryParse(v);
                                      if (val != null && val > 0) {
                                        setState(() => cantidad = val);
                                      }
                                    },
                                    controller: TextEditingController(text: cantidad.toString()),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Tarifa (Bs por noche)',
                                      labelStyle: TextStyle(color: textSecondary),
                                      floatingLabelStyle: TextStyle(color: primaryGreen),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                        borderSide: BorderSide(
                                          color: primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: cardBackground,
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
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _seleccionarFechaIngreso,
                              borderRadius: borderRadius,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBackground,
                                  borderRadius: borderRadius,
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: fechaIngreso != null ? primaryGreen : textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      fechaIngreso != null
                                          ? DateFormat('dd/MM/yyyy').format(fechaIngreso!)
                                          : 'Fecha de ingreso',
                                      style: TextStyle(
                                        color: fechaIngreso != null ? textPrimary : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: fechaIngreso == null ? null : _seleccionarFechaSalida,
                              borderRadius: borderRadius,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBackground,
                                  borderRadius: borderRadius,
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: fechaSalida != null ? primaryGreen : textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      fechaSalida != null
                                          ? DateFormat('dd/MM/yyyy').format(fechaSalida!)
                                          : 'Fecha de salida',
                                      style: TextStyle(
                                        color: fechaSalida != null ? textPrimary : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (cantidadNoches > 0) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  borderRadius: borderRadius,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Noches: ',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      cantidadNoches.toString(),
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: darkBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _agregarHabitacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: borderRadius,
                    ),
                    elevation: 2,
                    shadowColor: primaryGreen.withOpacity(0.3),
                  ),
                  child: const Text('AGREGAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}