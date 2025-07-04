// lib/providers/cotizacion_salon_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cotizacion_salon.dart';

class CotizacionSalonNotifier extends StateNotifier<List<ItemSalon>> {
  CotizacionSalonNotifier() : super([]);

  void agregarSalon(
    ItemSalon salon, {
    String? idCotizacion,
    String? idEstablecimiento,
  }) {
    // Aquí puedes usar idCotizacion e idEstablecimiento si quieres (por ejemplo para backend)
    state = [...state, salon];
  }

  void actualizarSalon(int index, ItemSalon salon) {
    if (index < 0 || index >= state.length) return;
    final nuevaLista = [...state];
    nuevaLista[index] = salon;
    state = nuevaLista;
  }

  void eliminarSalon(int index) {
    if (index < 0 || index >= state.length) return;
    final nuevaLista = [...state];
    nuevaLista.removeAt(index);
    state = nuevaLista;
  }

  void limpiar() {
    state = [];
  }
}

final cotizacionSalonProvider =
    StateNotifierProvider<CotizacionSalonNotifier, List<ItemSalon>>(
        (ref) => CotizacionSalonNotifier());