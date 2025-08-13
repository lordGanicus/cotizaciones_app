// establecimientos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establecimiento.dart';
import '../models/usuario.dart';
import 'usuario_provider.dart';

final supabase = Supabase.instance.client;

// Todos los establecimientos
final establecimientosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final response = await supabase.from('establecimientos').select();
  if (response == null || response is! List) return [];

  final establecimientos = (response as List)
      .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
      .toList();

  print('Total de establecimientos en la BD: ${establecimientos.length}');
  for (var e in establecimientos) {
    print('Establecimiento: ${e.id} - ${e.nombre}');
  }

  return establecimientos;
});




/******************************************** */
// Filtrados según rol y usuario
final establecimientosFiltradosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final usuario = await ref.watch(usuarioActualProvider.future);

  print('--- INICIO: Filtrado de establecimientos ---');
  print('Usuario: ${usuario.nombreCompleto}');
  print('Rol: ${usuario.rolNombre}');
  print('ID principal: ${usuario.idEstablecimiento}');
  print('Otros permitidos: ${usuario.otrosEstablecimientos}');

  final response = await supabase.from('establecimientos').select();
  if (response == null || response is! List) return [];

  final establecimientos = (response as List)
      .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
      .toList();

  print('Establecimientos en la BD: ${establecimientos.map((e) => e.id).toList()}');

  final idsPermitidos = <String>{};
  final rol = usuario.rolNombre?.toLowerCase();

  if (rol == 'administrador') {
    // Administrador ve todos los establecimientos
    idsPermitidos.addAll(establecimientos.map((e) => e.id));
    print('Es administrador, IDs permitidos: $idsPermitidos');
  } else {
    // Usuario/gerente: principal + secundarios
    if (usuario.idEstablecimiento != null && usuario.idEstablecimiento!.isNotEmpty) {
      idsPermitidos.add(usuario.idEstablecimiento!);
      print('Agregado principal: ${usuario.idEstablecimiento}');
    }

    if (usuario.otrosEstablecimientos.isNotEmpty) {
      idsPermitidos.addAll(usuario.otrosEstablecimientos);
      print('Agregados secundarios: ${usuario.otrosEstablecimientos}');
    }
  }

  final filtrados = establecimientos.where((e) => idsPermitidos.contains(e.id)).toList();
  print('Filtrados encontrados: ${filtrados.map((e) => e.id).toList()}');
  print('--- FIN: Filtrado de establecimientos ---');

  return filtrados;
});

