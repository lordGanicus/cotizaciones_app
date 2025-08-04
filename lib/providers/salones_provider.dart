import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salon.dart';

final supabase = Supabase.instance.client;

final salonesProvider = AsyncNotifierProvider<SalonesNotifier, List<Salon>>(() {
  return SalonesNotifier();
});

class SalonesNotifier extends AsyncNotifier<List<Salon>> {
  @override
  Future<List<Salon>> build() async {
    return cargarSalones();
  }

  Future<List<Salon>> cargarSalones() async {
    try {
      final response = await supabase
          .from('salones')
          .select()
          .order('created_at', ascending: false);

      final lista = (response as List)
          .map((map) => Salon.fromMap(map as Map<String, dynamic>))
          .toList();

      state = AsyncData(lista);
      return lista;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> agregarSalon(
    String nombre,
    int capacidadMesas,
    int capacidadSillas,
    String? descripcion,
    String idSubestablecimiento,
  ) async {
    try {
      await supabase.from('salones').insert({
        'nombre_salon': nombre,
        'capacidad_mesas': capacidadMesas,
        'capacidad_sillas': capacidadSillas,
        'descripcion': descripcion,
        'id_subestablecimiento': idSubestablecimiento,
      });

      await cargarSalones();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> editarSalon(
    String id,
    String nombre,
    int capacidadMesas,
    int capacidadSillas,
    String? descripcion,
    String idSubestablecimiento,
  ) async {
    try {
      await supabase.from('salones').update({
        'nombre_salon': nombre,
        'capacidad_mesas': capacidadMesas,
        'capacidad_sillas': capacidadSillas,
        'descripcion': descripcion,
        'id_subestablecimiento': idSubestablecimiento,
      }).eq('id', id);

      await cargarSalones();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> eliminarSalon(String id) async {
    try {
      await supabase.from('salones').delete().eq('id', id);
      final listaActual = state.value ?? [];
      state = AsyncData(listaActual.where((salon) => salon.id != id).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// ✅ Filtro por subestablecimiento (actualizado: directo desde Supabase)
final salonesPorSubestablecimientoProvider =
    FutureProvider.family<List<Salon>, String>((ref, idSubestablecimiento) async {
  final response = await supabase
      .from('salones')
      .select()
      .eq('id_subestablecimiento', idSubestablecimiento)
      .order('created_at', ascending: false);

  final lista = (response as List)
      .map((e) => Salon.fromMap(e as Map<String, dynamic>))
      .toList();

  return lista;
});

// ✅ Obtener IDs de subestablecimientos por establecimiento
final subestablecimientosPorEstablecimientoProvider =
    FutureProvider.family<List<String>, String>((ref, idEstablecimiento) async {
  final response = await supabase
      .from('subestablecimientos')
      .select('id')
      .eq('id_establecimiento', idEstablecimiento);

  final ids = (response as List).map((e) => e['id'] as String).toList();
  return ids;
});

// ✅ Filtro por establecimiento (requiere tener relación subestablecimiento - establecimiento)
final salonesPorEstablecimientoProvider =
    FutureProvider.family<List<Salon>, String>((ref, idEstablecimiento) async {
  final idsSubestablecimientos = await ref
      .watch(subestablecimientosPorEstablecimientoProvider(idEstablecimiento).future);
  final todosSalones = await ref.read(salonesProvider.notifier).cargarSalones();

  return todosSalones
      .where((s) => idsSubestablecimientos.contains(s.idSubestablecimiento))
      .toList();
});
