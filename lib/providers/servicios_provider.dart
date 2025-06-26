import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servicio_incluido.dart';

final supabase = Supabase.instance.client;

// Provider principal
final serviciosProvider = StateNotifierProvider<ServiciosNotifier, List<ServicioIncluido>>((ref) {
  return ServiciosNotifier();
});

class ServiciosNotifier extends StateNotifier<List<ServicioIncluido>> {
  ServiciosNotifier() : super([]) {
    cargarServicios();
  }

  Future<void> cargarServicios() async {
    final response = await supabase
        .from('servicios_incluidos')
        .select()
        .order('created_at', ascending: false);

    state = response
        .map((row) => ServicioIncluido.fromMap(row))
        .toList()
        .cast<ServicioIncluido>();
  }

  Future<void> agregarServicio(String nombre, String descripcion) async {
    final response = await supabase.from('servicios_incluidos').insert({
      'nombre_servicio': nombre,
      'descripcion': descripcion,
    }).select().single();

    final nuevo = ServicioIncluido.fromMap(response);
    state = [nuevo, ...state];
  }

  Future<void> editarServicio(String id, String nombre, String descripcion) async {
    await supabase.from('servicios_incluidos').update({
      'nombre_servicio': nombre,
      'descripcion': descripcion,
    }).eq('id', id);

    state = [
      for (final servicio in state)
        if (servicio.id == id)
          ServicioIncluido(
            id: id,
            nombre: nombre,
            descripcion: descripcion,
            createdAt: servicio.createdAt,
          )
        else
          servicio
    ];
  }

  Future<void> eliminarServicio(String id) async {
    await supabase.from('servicios_incluidos').delete().eq('id', id);
    state = state.where((servicio) => servicio.id != id).toList();
  }
}