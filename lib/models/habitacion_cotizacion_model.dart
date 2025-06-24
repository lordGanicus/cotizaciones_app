class HabitacionCotizada {
  final String tipo; // Suite simple, Suite doble, etc.
  final int cantidad;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final int noches;
  final double precioRegular;
  final double precioEspecial;

  HabitacionCotizada({
    required this.tipo,
    required this.cantidad,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.noches,
    required this.precioRegular,
    required this.precioEspecial,
  });

  double get total => cantidad * noches * precioEspecial;

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'cantidad': cantidad,
      'fecha_ingreso': fechaIngreso.toIso8601String(),
      'fecha_salida': fechaSalida.toIso8601String(),
      'noches': noches,
      'precio_regular': precioRegular,
      'precio_especial': precioEspecial,
      'total': total,
    };
  }
}