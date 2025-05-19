class CotizacionItem {
  final String detalle;
  final int cantidad;
  final double precioUnitario;
  final double total;

  CotizacionItem({
    required this.detalle,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'detalle': detalle,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'total': total,
    };
  }
}