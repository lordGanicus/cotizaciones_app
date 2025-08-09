import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/Mestablecimiento.dart';
import '../models/Msubestablecimiento.dart';
import '../utils/cloudinary_upload.dart';
import 'usuario_provider.dart';
final supabase = Supabase.instance.client;

final establecimientosProvider =
    AsyncNotifierProvider<EstablecimientosNotifier, List<Establecimiento>>(
  EstablecimientosNotifier.new,
);

class EstablecimientosNotifier extends AsyncNotifier<List<Establecimiento>> {
  @override
  Future<List<Establecimiento>> build() async {
    return cargarEstablecimientos();
  }

  Future<List<Establecimiento>> cargarEstablecimientos() async {
    state = const AsyncValue.loading();
    try {
      final response = await supabase
          .from('establecimientos')
          .select()
          .order('nombre');

      final data = response as List;
      final lista = data
          .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(lista);
      return lista;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> agregarEstablecimiento({
    required String nombre,
    String? logotipo,
    String? logotipoPublicId,
    String? membrete,
    String? membretePublicId,
  }) async {
    final response = await supabase.from('establecimientos').insert({
      'nombre': nombre,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    }).select().single();

    final nuevo = Establecimiento.fromMap(response);
    final listaActual = state.value ?? [];
    state = AsyncValue.data([nuevo, ...listaActual]);
  }

  Future<void> editarEstablecimiento({
    required String id,
    required String nombre,
    String? logotipo,
    String? logotipoPublicId,
    String? membrete,
    String? membretePublicId,
  }) async {
    await supabase.from('establecimientos').update({
      'nombre': nombre,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((e) {
      if (e.id == id) {
        return Establecimiento(
          id: id,
          nombre: nombre,
          logotipo: logotipo,
          logotipoPublicId: logotipoPublicId,
          membrete: membrete,
          membretePublicId: membretePublicId,
        );
      }
      return e;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarEstablecimiento(String id) async {
    final establecimiento = state.value?.firstWhere((e) => e.id == id);
    if (establecimiento != null) {
      if (establecimiento.logotipoPublicId != null) {
        await CloudinaryService().eliminarImagen(establecimiento.logotipoPublicId!);
      }
      if (establecimiento.membretePublicId != null) {
        await CloudinaryService().eliminarImagen(establecimiento.membretePublicId!);
      }
    }

    await supabase.from('establecimientos').delete().eq('id', id);

    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((e) => e.id != id).toList());
  }

  void limpiar() {
    state = const AsyncValue.data([]);
  }
}

final subestablecimientosProvider = AsyncNotifierProviderFamily<
    SubestablecimientosNotifier, List<Subestablecimiento>, String>(
  SubestablecimientosNotifier.new,
);

class SubestablecimientosNotifier
    extends FamilyAsyncNotifier<List<Subestablecimiento>, String> {
  late String idEstablecimiento;

  @override
  Future<List<Subestablecimiento>> build(String idEstablecimientoParam) async {
    idEstablecimiento = idEstablecimientoParam;
    return cargarSubestablecimientos();
  }

  Future<List<Subestablecimiento>> cargarSubestablecimientos() async {
    state = const AsyncValue.loading();
    try {
      final response = await supabase
          .from('subestablecimientos')
          .select()
          .eq('id_establecimiento', idEstablecimiento)
          .order('created_at', ascending: false);

      final data = response as List;
      final lista = data
          .map((e) => Subestablecimiento.fromMap(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(lista);
      return lista;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> agregarSubestablecimiento({
    required String nombre,
    String? descripcion,
    String? logotipo,
    String? logotipoPublicId,
    String? membrete,
    String? membretePublicId,
  }) async {
    final response = await supabase.from('subestablecimientos').insert({
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    }).select().single();

    final nuevo = Subestablecimiento.fromMap(response);
    final listaActual = state.value ?? [];
    state = AsyncValue.data([nuevo, ...listaActual]);
  }

  Future<void> editarSubestablecimiento({
    required String id,
    required String nombre,
    String? descripcion,
    String? logotipo,
    String? logotipoPublicId,
    String? membrete,
    String? membretePublicId,
  }) async {
    await supabase.from('subestablecimientos').update({
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((s) {
      if (s.id == id) {
        return Subestablecimiento(
          id: id,
          idEstablecimiento: idEstablecimiento,
          nombre: nombre,
          descripcion: descripcion,
          logotipo: logotipo,
          logotipoPublicId: logotipoPublicId,
          membrete: membrete,
          membretePublicId: membretePublicId,
        );
      }
      return s;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarSubestablecimiento(String id) async {
    final sub = state.value?.firstWhere((s) => s.id == id);
    if (sub != null) {
      if (sub.logotipoPublicId != null) {
        await CloudinaryService().eliminarImagen(sub.logotipoPublicId!);
      }
      if (sub.membretePublicId != null) {
        await CloudinaryService().eliminarImagen(sub.membretePublicId!);
      }
    }

    await supabase.from('subestablecimientos').delete().eq('id', id);

    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((s) => s.id != id).toList());
  }

  void limpiar() {
    state = const AsyncValue.data([]);
  }
  final subestablecimientosProvider = AsyncNotifierProviderFamily<
    SubestablecimientosNotifier, List<Subestablecimiento>, String>(
  SubestablecimientosNotifier.new,
);

}
final subestablecimientoPorIdProvider = FutureProvider.family<Subestablecimiento, String>((ref, idSubestablecimiento) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('subestablecimientos')
      .select()
      .eq('id', idSubestablecimiento)
      .single();

  return Subestablecimiento.fromMap(response as Map<String, dynamic>);
});

final establecimientosFiltradosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final usuario = await ref.watch(usuarioActualProvider.future);

  var query = supabase.from('establecimientos').select();

  if (usuario.rolNombre?.toLowerCase() == 'gerente' && usuario.idEstablecimiento != null) {
    // El gerente solo ve su establecimiento
    query = query.eq('id', usuario.idEstablecimiento!);
  }

  final response = await query;

  if (response == null || response is! List) {
    return [];
  }

  return (response as List)
      .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
      .toList();
});