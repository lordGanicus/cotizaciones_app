import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itemComida.dart';
import '../models/ItemComidaCotizacion.dart';

class CotizacionComidaNotifier extends StateNotifier<ItemComidaCotizacion> {
  CotizacionComidaNotifier()
      : super(
          ItemComidaCotizacion(
            idCotizacion: '',
            idUsuario: '',
            idEstablecimiento: '',
            idSubestablecimiento: '',
            nombreSubestablecimiento: '',
            nombreCliente: '',
            ciCliente: '',
            fechaEvento: DateTime.now(),
            horaEvento: DateTime.now(),
            itemsComida: [],
            total: 0,
          ),
        );

  // Método para setear todos los IDs a la vez
  void setIds({
    required String idCotizacion,
    required String idEstablecimiento,
    required String idUsuario,
    String? idSubestablecimiento,
  }) {
    state = state.copyWith(
      idCotizacion: idCotizacion,
      idEstablecimiento: idEstablecimiento,
      idUsuario: idUsuario,
      idSubestablecimiento: idSubestablecimiento ?? '',
    );
  }

  void setCliente({
    required String nombre,
    required String ci,
  }) {
    state = state.copyWith(
      nombreCliente: nombre,
      ciCliente: ci,
    );
  }

  void setSubestablecimiento({
    required String id,
    required String nombre,
  }) {
    state = state.copyWith(
      idSubestablecimiento: id,
      nombreSubestablecimiento: nombre,
    );
  }

  void setUsuario(String idUsuario) {
    state = state.copyWith(idUsuario: idUsuario);
  }

  void setFechaYHoraEvento(DateTime fecha, DateTime hora) {
    state = state.copyWith(
      fechaEvento: fecha,
      horaEvento: hora,
    );
  }

  void agregarItem(ItemComida item) {
    final nuevaLista = [...state.itemsComida, item];
    final nuevoTotal = nuevaLista.fold<double>(0, (sum, i) => sum + i.subtotal);
    state = state.copyWith(
      itemsComida: nuevaLista,
      total: nuevoTotal,
    );
  }

  void eliminarItemPorDescripcion(String descripcion) {
    final nuevaLista =
        state.itemsComida.where((i) => i.descripcion != descripcion).toList();
    final nuevoTotal =
        nuevaLista.fold<double>(0, (sum, i) => sum + i.subtotal);
    state = state.copyWith(
      itemsComida: nuevaLista,
      total: nuevoTotal,
    );
  }

  void limpiar() {
    state = ItemComidaCotizacion(
      idCotizacion: '',
      idUsuario: '',
      idEstablecimiento: '',
      idSubestablecimiento: '',
      nombreSubestablecimiento: '',
      nombreCliente: '',
      ciCliente: '',
      fechaEvento: DateTime.now(),
      horaEvento: DateTime.now(),
      itemsComida: [],
      total: 0,
    );
  }
}

final cotizacionComidaProvider =
    StateNotifierProvider<CotizacionComidaNotifier, ItemComidaCotizacion>(
  (ref) => CotizacionComidaNotifier(),
);
