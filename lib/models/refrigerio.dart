class Refrigerio {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioUnitario;
  final DateTime createdAt;
  int cantidadPax; // Mutable solo para cotización

  Refrigerio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioUnitario,
    required this.createdAt,
    this.cantidadPax = 0,
  });

  double get subtotal => cantidadPax * precioUnitario;

  factory Refrigerio.fromMap(Map<String, dynamic> map) {
    return Refrigerio(
      id: map['id'],
      nombre: map['nombre_refrigerio'],
      descripcion: map['descripcion'],
      precioUnitario: map['precio_unitario'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      cantidadPax: map['cantidad_pax'] ?? 0, // opcional, si viene desde cotización
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_refrigerio': nombre,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'created_at': createdAt.toIso8601String(),
      'cantidad_pax': cantidadPax,
    };
  }

  Refrigerio copyWith({
    int? cantidadPax,
  }) {
    return Refrigerio(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precioUnitario: precioUnitario,
      createdAt: createdAt,
      cantidadPax: cantidadPax ?? this.cantidadPax,
    );
  }
}
