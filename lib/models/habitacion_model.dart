class HabitacionSeleccionada {
  final String tipo;
  final int cantidad;

  HabitacionSeleccionada({
    required this.tipo,
    required this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'cantidad': cantidad,
    };
  }
}