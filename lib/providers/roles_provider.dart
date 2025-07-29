import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rol.dart';

final supabase = Supabase.instance.client;

final rolesProvider = FutureProvider<List<Rol>>((ref) async {
  final response = await supabase.from('roles').select();

  final lista = <Rol>[];
  for (final item in response) {
    lista.add(Rol.fromMap(item));
  }

  return lista;
});