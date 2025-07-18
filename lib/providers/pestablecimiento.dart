import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/Mestablecimiento.dart';
import '../models/Msubestablecimiento.dart';

final supabase = Supabase.instance.client;

/// Provider para la lista de establecimientos
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
    String? logotipoUrl,
    String? membreteUrl,
  }) async {
    final response = await supabase.from('establecimientos').insert({
      'nombre': nombre,
      'logotipo': logotipoUrl,
      'membrete': membreteUrl,
    }).select().single();

    final nuevo = Establecimiento.fromMap(response);
    final listaActual = state.value ?? [];
    state = AsyncValue.data([nuevo, ...listaActual]);
  }

  Future<void> editarEstablecimiento({
    required String id,
    required String nombre,
    String? logotipoUrl,
    String? membreteUrl,
  }) async {
    await supabase.from('establecimientos').update({
      'nombre': nombre,
      'logotipo': logotipoUrl,
      'membrete': membreteUrl,
    }).eq('id', id);

    final listaActual = state.value ?? [];
    final nuevaLista = listaActual.map((e) {
      if (e.id == id) {
        return Establecimiento(
          id: id,
          nombre: nombre,
          logotipoUrl: logotipoUrl,
          membreteUrl: membreteUrl,
        );
      }
      return e;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarEstablecimiento(String id) async {
    await supabase.from('establecimientos').delete().eq('id', id);
    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((e) => e.id != id).toList());
  }

  void limpiar() {
    state = const AsyncValue.data([]);
  }
}

/// Provider para subestablecimientos, recibe el idEstablecimiento como parámetro
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
    String? membrete,
  }) async {
    final response = await supabase.from('subestablecimientos').insert({
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'membrete': membrete,
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
    String? membrete,
  }) async {
    await supabase.from('subestablecimientos').update({
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'membrete': membrete,
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
          membrete: membrete,
        );
      }
      return s;
    }).toList();

    state = AsyncValue.data(nuevaLista);
  }

  Future<void> eliminarSubestablecimiento(String id) async {
    await supabase.from('subestablecimientos').delete().eq('id', id);
    final listaActual = state.value ?? [];
    state = AsyncValue.data(listaActual.where((s) => s.id != id).toList());
  }

  void limpiar() {
    state = const AsyncValue.data([]);
  }
}