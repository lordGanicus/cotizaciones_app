import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establecimiento.dart';

final supabase = Supabase.instance.client;

final establecimientosProvider = FutureProvider<List<Establecimiento>>((ref) async {
  final response = await supabase.from('establecimientos').select();

  final data = response as List;
  return data.map((e) => Establecimiento.fromMap(e)).toList();
});