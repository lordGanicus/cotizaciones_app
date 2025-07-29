import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

final supabase = Supabase.instance.client;

final usuariosProvider = StateNotifierProvider<UsuariosNotifier, List<Usuario>>((ref) {
  return UsuariosNotifier();
});

class UsuariosNotifier extends StateNotifier<List<Usuario>> {
  UsuariosNotifier() : super([]) {
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final response = await supabase.from('usuarios').select('''
      *,
      roles(nombre) AS rol_nombre,
      establecimientos(nombre) AS establecimiento_nombre,
      id_subestablecimiento
    ''');

    final lista = <Usuario>[];
    for (final item in response) {
      // Obtener otros establecimientos del usuario
      final otrosEstabRes = await supabase
          .from('usuarios_establecimientos')
          .select('id_establecimiento')
          .eq('id_usuario', item['id']);

      final otrosEstabs =
          otrosEstabRes.map((e) => e['id_establecimiento'].toString()).toList();

      lista.add(Usuario.fromMap({
        ...item,
        'otros_establecimientos': otrosEstabs,
        'id_subestablecimiento': item['id_subestablecimiento'], // aseguramos este campo
      }));
    }

    state = lista;
  }

  Future<void> agregarUsuario(Usuario usuario) async {
    final avatar = _asignarAvatarSegunGenero(usuario.genero);

    final res = await supabase.from('usuarios').insert({
      'ci': usuario.ci,
      'nombre_completo': usuario.nombreCompleto,
      'celular': usuario.celular,
      'genero': usuario.genero,
      'avatar': avatar,
      'id_rol': usuario.idRol,
      'id_establecimiento': usuario.idEstablecimiento,
      'id_subestablecimiento': usuario.idSubestablecimiento,
    }).select().single();

    final idUsuarioNuevo = res['id'] as String;

    // Agregar otros establecimientos
    for (final idEst in usuario.otrosEstablecimientos) {
      await supabase.from('usuarios_establecimientos').insert({
        'id_usuario': idUsuarioNuevo,
        'id_establecimiento': idEst,
      });
    }

    await cargarUsuarios();
  }

  Future<void> actualizarUsuario(Usuario usuario) async {
    final avatar = _asignarAvatarSegunGenero(usuario.genero);

    await supabase.from('usuarios').update({
      'ci': usuario.ci,
      'nombre_completo': usuario.nombreCompleto,
      'celular': usuario.celular,
      'genero': usuario.genero,
      'avatar': avatar,
      'id_rol': usuario.idRol,
      'id_establecimiento': usuario.idEstablecimiento,
      'id_subestablecimiento': usuario.idSubestablecimiento,
    }).eq('id', usuario.id);

    // Actualizar lista de otros establecimientos
    await supabase.from('usuarios_establecimientos').delete().eq('id_usuario', usuario.id);

    for (final idEst in usuario.otrosEstablecimientos) {
      await supabase.from('usuarios_establecimientos').insert({
        'id_usuario': usuario.id,
        'id_establecimiento': idEst,
      });
    }

    await cargarUsuarios();
  }

  Future<void> eliminarUsuario(String idUsuario) async {
    await supabase.from('usuarios').delete().eq('id', idUsuario);
    await cargarUsuarios();
  }

  String _asignarAvatarSegunGenero(String genero) {
    switch (genero.toLowerCase()) {
      case 'masculino':
        return 'https://res.cloudinary.com/dvmov11mg/image/upload/v1753724887/1717ab72-821c-4a21-9d5a-5170ec80d6fa.png';
      case 'femenino':
        return 'https://res.cloudinary.com/dvmov11mg/image/upload/v1753724849/502d2d51-a110-4230-b37b-20cbce7caa95.png';
      default:
        return 'https://api.dicebear.com/7.x/fun-emoji/svg?seed=person&backgroundColor=b6e3f4,ffd5dc,c0aede';
    }
  }
}
