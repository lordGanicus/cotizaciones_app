import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salon.dart';
import '../models/servicio_incluido.dart';
import '../models/refrigerio.dart';

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
          .select('''
            *,
            salon_servicios_incluidos (
              servicio_id,
              servicios_incluidos (
                id,
                nombre_servicio,
                descripcion,
                created_at
              )
            ),
            salon_refrigerios (
              refrigerio_id,
              refrigerios (
                id,
                nombre_refrigerio,
                descripcion,
                precio_unitario,
                created_at
              )
            )
          ''')
          .order('created_at', ascending: false);

      final lista = (response as List).map<Salon>((row) {
        final servicios = (row['salon_servicios_incluidos'] as List)
            .map((rel) => rel['servicios_incluidos'])
            .where((s) => s != null)
            .map((s) => ServicioIncluido.fromMap(s))
            .toList();

        final refrigerios = (row['salon_refrigerios'] as List)
            .map((rel) => rel['refrigerios'])
            .where((r) => r != null)
            .map((r) => Refrigerio.fromMap(r))
            .toList();

        return Salon.fromMap(row, servicios, refrigerios);
      }).toList();

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
    List<String> serviciosIds,
    List<String> refrigeriosIds,
  ) async {
    try {
      final response = await supabase.from('salones').insert({
        'nombre_salon': nombre,
        'capacidad_mesas': capacidadMesas,
        'capacidad_sillas': capacidadSillas,
        'descripcion': descripcion,
      }).select().single();

      final salonId = response['id'] as String;

      for (final sid in serviciosIds) {
        await supabase.from('salon_servicios_incluidos').insert({
          'salon_id': salonId,
          'servicio_id': sid,
        });
      }

      for (final rid in refrigeriosIds) {
        await supabase.from('salon_refrigerios').insert({
          'salon_id': salonId,
          'refrigerio_id': rid,
        });
      }

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
    List<String> serviciosIds,
    List<String> refrigeriosIds,
  ) async {
    try {
      await supabase.from('salones').update({
        'nombre_salon': nombre,
        'capacidad_mesas': capacidadMesas,
        'capacidad_sillas': capacidadSillas,
        'descripcion': descripcion,
      }).eq('id', id);

      await supabase.from('salon_servicios_incluidos').delete().eq('salon_id', id);
      for (final sid in serviciosIds) {
        await supabase.from('salon_servicios_incluidos').insert({
          'salon_id': id,
          'servicio_id': sid,
        });
      }

      await supabase.from('salon_refrigerios').delete().eq('salon_id', id);
      for (final rid in refrigeriosIds) {
        await supabase.from('salon_refrigerios').insert({
          'salon_id': id,
          'refrigerio_id': rid,
        });
      }

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