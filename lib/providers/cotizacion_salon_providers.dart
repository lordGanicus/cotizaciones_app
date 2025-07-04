import 'package:flutter_riverpod/flutter_riverpod.dart';
//import '../models/salon.dart';
import '../models/refrigerio.dart';

/// Provider para el salón seleccionado
//final salonSeleccionadoProvider = StateProvider<Salon?>((ref) => null);

/// Provider para refrigerios seleccionados
final refrigeriosSeleccionadosProvider = StateProvider<List<Refrigerio>>((ref) => []);
