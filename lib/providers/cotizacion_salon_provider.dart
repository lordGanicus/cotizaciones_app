import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cotizacion_salon.dart';

class CotizacionSalonNotifier extends StateNotifier<ItemSalon?> {
  CotizacionSalonNotifier() : super(null);

  void iniciarCotizacion(ItemSalon itemSalon) {
    state = itemSalon;
  }

  void actualizarHoras(int horas) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: horas,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarFechaEvento(DateTime fecha) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: fecha,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarHoraInicio(DateTime hora) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: hora,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarHoraFin(DateTime hora) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: hora,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarParticipantes(int cant) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: cant,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarTipoArmado(String armado) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: armado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarServicios(List<ServicioIncluido> servicios) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: servicios,
      refrigeriosSeleccionados: state!.refrigeriosSeleccionados,
    );
  }

  void actualizarRefrigerios(List<Refrigerio> refrigerios) {
    if (state == null) return;
    state = ItemSalon(
      idSalon: state!.idSalon,
      nombreSalon: state!.nombreSalon,
      capacidad: state!.capacidad,
      descripcion: state!.descripcion,
      cantidadHoras: state!.cantidadHoras,
      fechaEvento: state!.fechaEvento,
      horaInicio: state!.horaInicio,
      horaFin: state!.horaFin,
      participantes: state!.participantes,
      tipoArmado: state!.tipoArmado,
      serviciosSeleccionados: state!.serviciosSeleccionados,
      refrigeriosSeleccionados: refrigerios,
    );
  }
}

final cotizacionSalonProvider =
    StateNotifierProvider<CotizacionSalonNotifier, ItemSalon?>((ref) {
  return CotizacionSalonNotifier();
});