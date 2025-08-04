import 'itemComida.dart';

class ItemComidaCotizacion {
  final String idCotizacion;
  final String idUsuario;
  final String idEstablecimiento;
  final String idSubestablecimiento;
  final String nombreSubestablecimiento;
  final String nombreCliente;
  final String ciCliente;
  final DateTime fechaEvento;
  final DateTime horaEvento;
  final List<ItemComida> itemsComida;
  final double total;

  ItemComidaCotizacion({
    required this.idCotizacion,
    required this.idUsuario,
    required this.idEstablecimiento,
    required this.idSubestablecimiento,
    required this.nombreSubestablecimiento,
    required this.nombreCliente,
    required this.ciCliente,
    required this.fechaEvento,
    required this.horaEvento,
    required this.itemsComida,
    required this.total,
  });

  ItemComidaCotizacion copyWith({
    String? idCotizacion,
    String? idUsuario,
    String? idEstablecimiento,
    String? idSubestablecimiento,
    String? nombreSubestablecimiento,
    String? nombreCliente,
    String? ciCliente,
    DateTime? fechaEvento,
    DateTime? horaEvento,
    List<ItemComida>? itemsComida,
    double? total,
  }) {
    return ItemComidaCotizacion(
      idCotizacion: idCotizacion ?? this.idCotizacion,
      idUsuario: idUsuario ?? this.idUsuario,
      idEstablecimiento: idEstablecimiento ?? this.idEstablecimiento,
      idSubestablecimiento: idSubestablecimiento ?? this.idSubestablecimiento,
      nombreSubestablecimiento: nombreSubestablecimiento ?? this.nombreSubestablecimiento,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      ciCliente: ciCliente ?? this.ciCliente,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      horaEvento: horaEvento ?? this.horaEvento,
      itemsComida: itemsComida ?? this.itemsComida,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() => {
        'id_cotizacion': idCotizacion,
        'id_usuario': idUsuario,
        'id_establecimiento': idEstablecimiento,
        'id_subestablecimiento': idSubestablecimiento,
        'nombre_subestablecimiento': nombreSubestablecimiento,
        'nombre_cliente': nombreCliente,
        'ci_cliente': ciCliente,
        'fecha_evento': fechaEvento.toIso8601String(),
        'hora_evento': horaEvento.toIso8601String(),
        'items_comida': itemsComida.map((e) => e.toMap()).toList(),
        'total': total,
        'tipo': 'comida', // para distinguir en BD
      };

  factory ItemComidaCotizacion.fromMap(Map<String, dynamic> map) {
    return ItemComidaCotizacion(
      idCotizacion: map['id_cotizacion'] ?? '',
      idUsuario: map['id_usuario'] ?? '',
      idEstablecimiento: map['id_establecimiento'] ?? '',
      idSubestablecimiento: map['id_subestablecimiento'] ?? '',
      nombreSubestablecimiento: map['nombre_subestablecimiento'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      ciCliente: map['ci_cliente'] ?? '',
      fechaEvento: DateTime.parse(map['fecha_evento']),
      horaEvento: DateTime.parse(map['hora_evento']),
      total: (map['total'] as num).toDouble(),
      itemsComida: List<ItemComida>.from(
        (map['items_comida'] as List).map((e) => ItemComida.fromMap(e)),
      ),
    );
  }
}