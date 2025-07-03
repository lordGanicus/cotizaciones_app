import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_comida.dart';

class ItemComidaNotifier extends StateNotifier<List<ItemComida>> {
  ItemComidaNotifier() : super([]);

  void agregarItem(ItemComida item) {
    state = [...state, item];
  }

  void eliminarItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  double calcularTotal() {
    return state.fold(0, (total, item) => total + item.subtotal);
  }

  void limpiarItems() {
    state = [];
  }
}

final itemComidaProvider = StateNotifierProvider<ItemComidaNotifier, List<ItemComida>>(
  (ref) => ItemComidaNotifier(),
);