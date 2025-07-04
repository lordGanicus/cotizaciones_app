import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establecimiento.dart';

final supabase = Supabase.instance.client;

final establecimientosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final response = await supabase.from('establecimientos').select();

  // Validar que la respuesta sea lista, y convertir
  if (response == null || response is! List) {
    return [];
  }

  return (response as List)
      .map((e) => Establecimiento.fromMap(e as Map<String, dynamic>))
      .toList();
});