import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cotizacion_habitacion.dart';

import '../models/salon.dart';
import '../models/refrigerio.dart';
class CotizacionHabitacionNotifier extends StateNotifier<List<CotizacionHabitacion>> {
  CotizacionHabitacionNotifier() : super([]);

  void agregarHabitacion(CotizacionHabitacion habitacion) {
    state = [...state, habitacion];
  }

  void eliminarHabitacion(int index) {
    final nuevaLista = [...state]..removeAt(index);
    state = nuevaLista;
  }

  void limpiar() {
    state = [];
  }

  double get total {
    return state.fold(0.0, (suma, item) => suma + item.subtotal);
  }
}

final cotizacionHabitacionProvider =
    StateNotifierProvider<CotizacionHabitacionNotifier, List<CotizacionHabitacion>>(
  (ref) => CotizacionHabitacionNotifier(),
);

final salonSeleccionadoProvider = StateProvider<Salon?>((ref) => null);

final refrigeriosSeleccionadosProvider = StateProvider<List<Refrigerio>>((ref) => []);