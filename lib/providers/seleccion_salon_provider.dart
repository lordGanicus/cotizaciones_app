import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salon.dart';

// Provider simple para guardar el salón seleccionado (puede ser null)
final salonSeleccionadoProvider = StateProvider<Salon?>((ref) => null);
