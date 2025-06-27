import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servicio_incluido.dart';

final supabase = Supabase.instance.client;

// Cambiamos a AsyncNotifier para manejar loading, error y datos automáticamente
final serviciosProvider = AsyncNotifierProvider<ServiciosNotifier, List<ServicioIncluido>>(() {
  return ServiciosNotifier();
});

class ServiciosNotifier extends AsyncNotifier<List<ServicioIncluido>> {
  @override
  Future<List<ServicioIncluido>> build() async {
    // Al construir, carga los servicios
    return cargarServicios();
  }

  Future<List<ServicioIncluido>> cargarServicios() async {
    final response = await supabase
        .from('servicios_incluidos')
        .select()
        .order('created_at', ascending: false);

    final lista = response
        .map<ServicioIncluido>((row) => ServicioIncluido.fromMap(row))
        .toList();

    state = AsyncData(lista);
    return lista;
  }

  Future<void> agregarServicio(String nombre, String descripcion) async {
    final response = await supabase.from('servicios_incluidos').insert({
      'nombre_servicio': nombre,
      'descripcion': descripcion,
    }).select().single();

    final nuevo = ServicioIncluido.fromMap(response);
    state = AsyncData([nuevo, ...state.value ?? []]);
  }

  Future<void> editarServicio(String id, String nombre, String descripcion) async {
    await supabase.from('servicios_incluidos').update({
      'nombre_servicio': nombre,
      'descripcion': descripcion,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((servicio) {
      if (servicio.id == id) {
        return ServicioIncluido(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          createdAt: servicio.createdAt,
        );
      }
      return servicio;
    }).toList();

    state = AsyncData(nuevaLista);
  }

  Future<void> eliminarServicio(String id) async {
    await supabase.from('servicios_incluidos').delete().eq('id', id);

    final listaActual = state.value ?? [];
    state = AsyncData(listaActual.where((servicio) => servicio.id != id).toList());
  }
}