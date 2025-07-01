class Establecimiento {
  final String id;
  final String nombre;

  Establecimiento({
    required this.id,
    required this.nombre,
  });

  factory Establecimiento.fromMap(Map<String, dynamic> map) {
    return Establecimiento(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
}