import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habitacion.dart';

final supabase = Supabase.instance.client;

/// Este es el provider que acepta un ID de establecimiento y maneja el estado asincrónico
final habitacionesProvider = AsyncNotifierProviderFamily<HabitacionesNotifier, List<Habitacion>, String>(
  HabitacionesNotifier.new,
);

/// Usamos FamilyAsyncNotifier para recibir parámetros
class HabitacionesNotifier extends FamilyAsyncNotifier<List<Habitacion>, String> {
  late final String idEstablecimiento;

  @override
  Future<List<Habitacion>> build(String idEstablecimientoParam) async {
    idEstablecimiento = idEstablecimientoParam;
    return _fetchHabitaciones();
  }

  Future<List<Habitacion>> _fetchHabitaciones() async {
    final response = await supabase
        .from('habitaciones')
        .select()
        .eq('id_establecimiento', idEstablecimiento)
        .order('created_at', ascending: false);

    final data = response as List;
    return data.map((e) => Habitacion.fromMap(e)).toList();
  }

  Future<void> cargarHabitaciones() async {
    state = const AsyncValue.loading();
    try {
      final lista = await _fetchHabitaciones();
      state = AsyncValue.data(lista);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> agregarHabitacion(String nombre, int capacidad, String? descripcion) async {
    final response = await supabase.from('habitaciones').insert({
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'capacidad': capacidad,
      'descripcion': descripcion,
    }).select().single();

    final nuevo = Habitacion.fromMap(response);
    final listaActual = state.value ?? [];
    state = AsyncValue.data([nuevo, ...listaActual]);
  }

  Future<void> editarHabitacion(String id, String nombre, int capacidad, String? descripcion) async {
    await supabase.from('habitaciones').update({
      'nombre': nombre,
      'capacidad': capacidad,
      'descripcion': descripcion,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((h) {
      if (h.id == id) {
        return Habitacion(
          id: id,
          idEstablecimiento: idEstablecimiento,
          nombre: nombre,
          capacidad: capacidad,
          descripcion: descripcion,
          createdAt: h.createdAt,
        );
      }
      return h;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarHabitacion(String id) async {
    await supabase.from('habitaciones').delete().eq('id', id);
    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((h) => h.id != id).toList());
  }
}