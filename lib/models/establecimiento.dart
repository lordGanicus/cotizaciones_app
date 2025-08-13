class Establecimiento {
  final String id;
  final String nombre;
  final String? logotipo; // <-- nuevo campo opcional

  Establecimiento({
    required this.id,
    required this.nombre,
    this.logotipo,
  });

  factory Establecimiento.fromMap(Map<String, dynamic> map) {
    return Establecimiento(
      id: map['id'],
      nombre: map['nombre'],
      logotipo: map['logotipo'] as String?, // <-- leer de la BD si existe
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'logotipo': logotipo,
    };
  }
}