class Habitacion {
  final String id;
  final String idEstablecimiento;
  final String nombre;
  final int capacidad;
  final String? descripcion;
  final DateTime createdAt;

  Habitacion({
    required this.id,
    required this.idEstablecimiento,
    required this.nombre,
    required this.capacidad,
    this.descripcion,
    required this.createdAt,
  });

  factory Habitacion.fromMap(Map<String, dynamic> map) {
    return Habitacion(
      id: map['id'] as String,
      idEstablecimiento: map['id_establecimiento'] as String,
      nombre: map['nombre'] as String,
      capacidad: map['capacidad'] as int,
      descripcion: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'capacidad': capacidad,
      'descripcion': descripcion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
