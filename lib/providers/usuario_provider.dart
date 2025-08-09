import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

final supabase = Supabase.instance.client;

final usuarioActualProvider = FutureProvider<Usuario>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('No hay usuario logueado');
  }

 final data = await supabase
    .from('usuarios')
    .select('''
      id, ci, nombre_completo, celular, genero, avatar, 
      id_rol, roles(nombre) as rol, 
      id_establecimiento, establecimientos!usuarios_id_establecimiento_fkey(nombre) as establecimiento,
      id_subestablecimiento, email,
      otros_establecimientos
    ''')
    .eq('id', user.id)
    .maybeSingle();

  if (data == null) {
    throw Exception('Usuario no encontrado');
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(data);

  // roles(nombre) devuelve una lista con un solo objeto {nombre: 'rolNombre'}
  final rolNombre = (map['roles'] != null &&
          map['roles'] is List &&
          (map['roles'] as List).isNotEmpty)
      ? (map['roles'] as List)[0]['nombre']
      : null;

  // establecimientos(nombre) también es lista con un solo objeto {nombre: 'establecimientoNombre'}
  final establecimientoNombre = (map['establecimientos'] != null &&
          map['establecimientos'] is List &&
          (map['establecimientos'] as List).isNotEmpty)
      ? (map['establecimientos'] as List)[0]['nombre']
      : null;

  return Usuario(
    id: map['id'],
    ci: map['ci'],
    nombreCompleto: map['nombre_completo'],
    celular: map['celular'] ?? '',
    genero: map['genero'] ?? 'otro',
    avatar: map['avatar'] ?? '',
    idRol: map['id_rol'],
    rolNombre: rolNombre,
    idEstablecimiento: map['id_establecimiento'],
    establecimientoNombre: establecimientoNombre,
    idSubestablecimiento: map['id_subestablecimiento'],
    email: map['email'] ?? '',
    otrosEstablecimientos: (map['otros_establecimientos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );
});