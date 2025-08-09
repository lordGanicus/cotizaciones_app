import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establecimiento.dart';
import '../models/usuario.dart'; // Modelo Usuario
import 'usuario_provider.dart'; // Provider que entrega usuarioActualProvider

final supabase = Supabase.instance.client;

// Provider general sin filtro (todos los establecimientos)
final establecimientosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final response = await supabase.from('establecimientos').select();

  if (response == null || response is! List) {
    return [];
  }

  return (response as List)
      .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
      .toList();
});

// Provider filtrado según rol y usuario logueado
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