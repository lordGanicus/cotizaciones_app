import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salon.dart';
import 'usuario_provider.dart'; 

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

// Filtro por subestablecimiento (consulta directa en Supabase)
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

// Obtener lista de IDs de subestablecimientos por establecimiento
final subestablecimientosPorEstablecimientoProvider =
    FutureProvider.family<List<String>, String>((ref, idEstablecimiento) async {
  final response = await supabase
      .from('subestablecimientos')
      .select('id')
      .eq('id_establecimiento', idEstablecimiento);

  final ids = (response as List).map((e) => e['id'] as String).toList();
  return ids;
});

// Filtro por establecimiento: filtra los salones con subestablecimientos relacionados
final salonesPorEstablecimientoProvider =
    FutureProvider.family<List<Salon>, String>((ref, idEstablecimiento) async {
  final idsSubestablecimientos = await ref
      .watch(subestablecimientosPorEstablecimientoProvider(idEstablecimiento).future);
  final todosSalones = await ref.read(salonesProvider.notifier).cargarSalones();

  return todosSalones
      .where((s) => idsSubestablecimientos.contains(s.idSubestablecimiento))
      .toList();
});

// Nuevo: Provider que filtra salones según el usuario logueado y su rol
final salonesFiltradosPorUsuarioProvider = FutureProvider<List<Salon>>((ref) async {
  try {
    final usuario = await ref.read(usuarioActualProvider.future);
    if (usuario == null) return [];

    // Obtener nombre del rol desde idRol (cachear o consultar tabla roles)
    final rolResponse = await supabase
        .from('roles')
        .select('nombre')
        .eq('id', usuario.idRol)
        .single();

    final rolNombre = (rolResponse as Map<String, dynamic>)['nombre']?.toLowerCase() ?? '';

    if (rolNombre == 'administrador') {
      final response = await supabase
          .from('salones')
          .select('id, id_subestablecimiento, nombre_salon, capacidad_mesas, capacidad_sillas, descripcion, created_at')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((e) => Salon.fromMap(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    if (usuario.idEstablecimiento != null) {
      final idsSubestablecimientos = await ref
          .read(subestablecimientosPorEstablecimientoProvider(usuario.idEstablecimiento!).future);

      if (idsSubestablecimientos.isEmpty) return [];

      // El filtro in con el método filter y string con paréntesis
      final filtroIds = idsSubestablecimientos.map((e) => "'$e'").join(',');

      final response = await supabase
          .from('salones')
          .select('id, id_subestablecimiento, nombre_salon, capacidad_mesas, capacidad_sillas, descripcion, created_at')
          .filter('id_subestablecimiento', 'in', '($filtroIds)')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((e) => Salon.fromMap(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return [];
  } catch (e, st) {
    print('Error en salonesFiltradosPorUsuarioProvider: $e\n$st');
    return [];
  }
});