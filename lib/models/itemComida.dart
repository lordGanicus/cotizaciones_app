class ItemComida {
  final String descripcion; // nombre del plato o producto
  final int cantidad;
  final double precioUnitario;

  ItemComida({
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

  factory ItemComida.fromMap(Map<String, dynamic> map) => ItemComida(
        descripcion: map['descripcion'],
        cantidad: map['cantidad'],
        precioUnitario: (map['precio_unitario'] as num).toDouble(),
      );
}