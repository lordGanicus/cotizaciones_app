import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refrigerio.dart';

final supabase = Supabase.instance.client;

// Provider con AsyncNotifier para manejar estado AsyncValue<List<Refrigerio>>
final refrigeriosProvider = AsyncNotifierProvider<RefrigeriosNotifier, List<Refrigerio>>(() {
  return RefrigeriosNotifier();
});

class RefrigeriosNotifier extends AsyncNotifier<List<Refrigerio>> {
  @override
  Future<List<Refrigerio>> build() async {
    // Carga inicial al crear el provider
    return _fetchRefrigerios();
  }

  Future<List<Refrigerio>> _fetchRefrigerios() async {
    final response = await supabase
        .from('refrigerios')
        .select()
        .order('created_at', ascending: false);

    final lista = (response as List)
        .map((row) => Refrigerio.fromMap(row))
        .toList();

    return lista;
  }

  // Carga de datos que puede ser llamada desde UI para refrescar
  Future<void> cargarRefrigerios() async {
    // Actualizamos el estado al resultado de la carga
    state = const AsyncValue.loading();
    try {
      final lista = await _fetchRefrigerios();
      state = AsyncValue.data(lista);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> agregarRefrigerio(String nombre, String descripcion, double precio) async {
    final response = await supabase.from('refrigerios').insert({
      'nombre_refrigerio': nombre,
      'descripcion': descripcion,
      'precio_unitario': precio,
    }).select().single();

    final nuevo = Refrigerio.fromMap(response);

    final listaActual = state.value ?? [];
    // Insertamos al inicio
    state = AsyncValue.data([nuevo, ...listaActual]);
  }

  Future<void> editarRefrigerio(String id, String nombre, String descripcion, double precio) async {
    await supabase.from('refrigerios').update({
      'nombre_refrigerio': nombre,
      'descripcion': descripcion,
      'precio_unitario': precio,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((r) {
      if (r.id == id) {
        return Refrigerio(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          precioUnitario: precio,
          createdAt: r.createdAt,
        );
      }
      return r;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarRefrigerio(String id) async {
    await supabase.from('refrigerios').delete().eq('id', id);

    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((r) => r.id != id).toList());
  }
}