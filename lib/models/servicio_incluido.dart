class ServicioIncluido {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime createdAt;

  ServicioIncluido({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.createdAt,
  });

  factory ServicioIncluido.fromMap(Map<String, dynamic> map) {
    return ServicioIncluido(
      id: map['id'],
      nombre: map['nombre_servicio'],
      descripcion: map['descripcion'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_servicio': nombre,
      'descripcion': descripcion,
    };
  }
}