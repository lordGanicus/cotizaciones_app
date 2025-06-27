class Refrigerio {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioUnitario;
  final DateTime createdAt;

  Refrigerio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioUnitario,
    required this.createdAt,
  });

  factory Refrigerio.fromMap(Map<String, dynamic> map) {
    return Refrigerio(
      id: map['id'] as String,
      nombre: map['nombre_refrigerio'] as String,
      descripcion: map['descripcion'] as String,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}