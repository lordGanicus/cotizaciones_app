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

  Map<String, dynamic> toMap() => {
        'descripcion': descripcion,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };

  factory ItemAdicional.fromMap(Map<String, dynamic> map) => ItemAdicional(
        descripcion: map['descripcion'],
        cantidad: map['cantidad'],
        precioUnitario: (map['precio_unitario'] as num).toDouble(),
      );
}

class ItemSalon {
  final String idUsuario;
  final String idSalon;
  final String nombreSalon;
  final int capacidad; // capacidad = cantidad máxima personas en el salón
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
  final List<Map<String, dynamic>> serviciosSeleccionados; // Listado de servicios con id, nombre, precio, etc.
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
    List<Map<String, dynamic>>? serviciosSeleccionados,
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

  Map<String, dynamic> toMap() => {
        'id_usuario': idUsuario,
        'id_salon': idSalon,
        'nombre_salon': nombreSalon,
        'capacidad': capacidad,
        'descripcion': descripcion,
        'nombre_cliente': nombreCliente,
        'ci_cliente': ciCliente,
        'tipo_evento': tipoEvento,
        'fecha_evento': fechaEvento.toIso8601String(),
        'hora_inicio': horaInicio.toIso8601String(),
        'hora_fin': horaFin.toIso8601String(),
        'participantes': participantes,
        'tipo_armado': tipoArmado,
        'precio_salon_total': precioSalonTotal,
        'servicios_seleccionados': serviciosSeleccionados,
        'items_adicionales': itemsAdicionales.map((e) => e.toMap()).toList(),
      };

  factory ItemSalon.fromMap(Map<String, dynamic> map) => ItemSalon(
        idUsuario: map['id_usuario'],
        idSalon: map['id_salon'],
        nombreSalon: map['nombre_salon'],
        capacidad: map['capacidad'],
        descripcion: map['descripcion'],
        nombreCliente: map['nombre_cliente'],
        ciCliente: map['ci_cliente'],
        tipoEvento: map['tipo_evento'],
        fechaEvento: DateTime.parse(map['fecha_evento']),
        horaInicio: DateTime.parse(map['hora_inicio']),
        horaFin: DateTime.parse(map['hora_fin']),
        participantes: map['participantes'],
        tipoArmado: map['tipo_armado'],
        precioSalonTotal: (map['precio_salon_total'] as num).toDouble(),
        serviciosSeleccionados: List<Map<String, dynamic>>.from(map['servicios_seleccionados']),
        itemsAdicionales: List<ItemAdicional>.from(
          (map['items_adicionales'] as List).map((x) => ItemAdicional.fromMap(x)),
        ),
      );
}
