class ItemComida {
  final String id;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  ItemComida({
    required this.id,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}