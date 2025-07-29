class Rol {
  final String id;
  final String nombre;

  Rol({
    required this.id,
    required this.nombre,
  });

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      id: map['id'],
      nombre: map['nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}