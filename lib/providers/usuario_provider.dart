// usuario_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/establecimiento.dart';

final supabase = Supabase.instance.client;

final usuarioActualProvider = FutureProvider<Usuario>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('No hay usuario logueado');

  print('--- INICIO: Usuario actual ---');
  print('Usuario auth id: ${user.id}');

  // 1️⃣ Traer datos de usuario y rol
  final data = await supabase
      .from('usuarios')
      .select(
          'id, ci, nombre_completo, celular, genero, avatar, id_rol, roles(nombre), id_establecimiento, id_subestablecimiento')
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) throw Exception('Usuario no encontrado');

  final map = Map<String, dynamic>.from(data);

  // Procesar rol
  String? rolNombre;
  if (map['roles'] != null) {
    if (map['roles'] is List && (map['roles'] as List).isNotEmpty) {
      rolNombre = (map['roles'][0]['nombre'] ?? '').toString();
    } else if (map['roles'] is Map) {
      rolNombre = map['roles']['nombre']?.toString();
    }
  }
  print('Rol procesado: $rolNombre');

  // 2️⃣ Traer establecimiento principal (ID + nombre)
  String? idEstablecimiento;
  String? nombreEstablecimiento;

  if (map['id_establecimiento'] != null) {
    final estData = await supabase
        .from('establecimientos')
        .select('id, nombre')
        .eq('id', map['id_establecimiento'].toString())
        .maybeSingle();

    if (estData != null) {
      idEstablecimiento = estData['id']?.toString();
      nombreEstablecimiento = estData['nombre']?.toString();
      print('Principal: $nombreEstablecimiento');
    }
  }

  // 3️⃣ Traer otros establecimientos (muchos a muchos)
  final secundariosRaw = await supabase
      .from('usuarios_establecimientos')
      .select('id_establecimiento')
      .eq('id_usuario', map['id']);

  final otrosEstablecimientos = (secundariosRaw as List<dynamic>? ?? [])
      .map((e) => e['id_establecimiento'].toString())
      .toList();

  print('Otros permitidos: $otrosEstablecimientos');

  // 4️⃣ Devolver Usuario con principal + secundarios (solo IDs)
  return Usuario(
    id: map['id'],
    ci: map['ci'],
    nombreCompleto: map['nombre_completo'],
    celular: map['celular'] ?? '',
    genero: map['genero'] ?? 'otro',
    avatar: map['avatar'] ?? '',
    idRol: map['id_rol'],
    rolNombre: rolNombre,
    idEstablecimiento: idEstablecimiento,
    establecimientoNombre: nombreEstablecimiento, // <- ahora sí viene el nombre
    idSubestablecimiento: map['id_subestablecimiento'],
    email: '',
    otrosEstablecimientos: otrosEstablecimientos, // solo IDs
  );
});
