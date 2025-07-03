//lib/models/cotizacion_habitacion.dart
class CotizacionHabitacion {
  final String nombreHabitacion;
  final int cantidad;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final int cantidadNoches;
  final double tarifa; // precio por noche
  final double subtotal;

  CotizacionHabitacion({
    required this.nombreHabitacion,
    required this.cantidad,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.cantidadNoches,
    required this.tarifa,
  }) : subtotal = cantidad * cantidadNoches * tarifa;

  Map<String, dynamic> toJson() {
    return {
      'nombreHabitacion': nombreHabitacion,
      'cantidad': cantidad,
      'fechaIngreso': fechaIngreso.toIso8601String(),
      'fechaSalida': fechaSalida.toIso8601String(),
      'cantidadNoches': cantidadNoches,
      'tarifa': tarifa,
      'subtotal': subtotal,
    };
  }

  factory CotizacionHabitacion.fromJson(Map<String, dynamic> json) {
    return CotizacionHabitacion(
      nombreHabitacion: json['nombreHabitacion'],
      cantidad: json['cantidad'],
      fechaIngreso: DateTime.parse(json['fechaIngreso']),
      fechaSalida: DateTime.parse(json['fechaSalida']),
      cantidadNoches: json['cantidadNoches'],
      tarifa: (json['tarifa'] as num).toDouble(),
    );
  }
}