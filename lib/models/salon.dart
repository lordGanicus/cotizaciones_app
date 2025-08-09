class Salon {
  final String id;
  final String idSubestablecimiento; 
  final String nombre;
  final int capacidadMesas;
  final int capacidadSillas;
  final String? descripcion;
  final DateTime createdAt;

  Salon({
    required this.id,
    required this.idSubestablecimiento,
    required this.nombre,
    required this.capacidadMesas,
    required this.capacidadSillas,
    this.descripcion,
    required this.createdAt,
  });

  factory Salon.fromMap(Map<String, dynamic> map) {
    return Salon(
      id: map['id'] as String,
      idSubestablecimiento: map['id_subestablecimiento'] as String,
      nombre: map['nombre_salon'] as String,
      capacidadMesas: map['capacidad_mesas'] as int,
      capacidadSillas: map['capacidad_sillas'] as int,
      descripcion: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
    Map<String, dynamic> toMap() => {
    // ... otros campos ...
    'id_subestablecimiento': idSubestablecimiento,
  };
  
}