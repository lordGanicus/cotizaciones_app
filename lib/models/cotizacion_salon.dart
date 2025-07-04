// lib/models/cotizacion_salon.dart

class ItemAdicional {
  final String descripcion;
  final int cantidad;
  final double precioUnitario;

  ItemAdicional({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class ItemSalon {
  final String idUsuario;
  final String idSalon;
  final String nombreSalon;
  final int capacidad;
  final String descripcion;
  final String nombreCliente;
  final String ciCliente;
  final String tipoEvento;
  final DateTime fechaEvento;
  final DateTime horaInicio;
  final DateTime horaFin;
  final int participantes;
  final String tipoArmado;
  final double precioSalonTotal;
  final List<dynamic> serviciosSeleccionados;
  final List<ItemAdicional> itemsAdicionales;

  ItemSalon({
    required this.idUsuario,
    required this.idSalon,
    required this.nombreSalon,
    required this.capacidad,
    required this.descripcion,
    required this.nombreCliente,
    required this.ciCliente,
    required this.tipoEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.participantes,
    required this.tipoArmado,
    required this.precioSalonTotal,
    required this.serviciosSeleccionados,
    required this.itemsAdicionales,
  });

  ItemSalon copyWith({
    String? idUsuario,
    String? idSalon,
    String? nombreSalon,
    int? capacidad,
    String? descripcion,
    String? nombreCliente,
    String? ciCliente,
    String? tipoEvento,
    DateTime? fechaEvento,
    DateTime? horaInicio,
    DateTime? horaFin,
    int? participantes,
    String? tipoArmado,
    double? precioSalonTotal,
    List<dynamic>? serviciosSeleccionados,
    List<ItemAdicional>? itemsAdicionales,
  }) {
    return ItemSalon(
      idUsuario: idUsuario ?? this.idUsuario,
      idSalon: idSalon ?? this.idSalon,
      nombreSalon: nombreSalon ?? this.nombreSalon,
      capacidad: capacidad ?? this.capacidad,
      descripcion: descripcion ?? this.descripcion,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      ciCliente: ciCliente ?? this.ciCliente,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      participantes: participantes ?? this.participantes,
      tipoArmado: tipoArmado ?? this.tipoArmado,
      precioSalonTotal: precioSalonTotal ?? this.precioSalonTotal,
      serviciosSeleccionados: serviciosSeleccionados ?? this.serviciosSeleccionados,
      itemsAdicionales: itemsAdicionales ?? this.itemsAdicionales,
    );
  }
}