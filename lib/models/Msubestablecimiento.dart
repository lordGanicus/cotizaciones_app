class Subestablecimiento {
  final String id;
  final String idEstablecimiento;
  final String nombre;
  final String? descripcion;
  final String? logotipo;    // agregar
  final String? membrete;    // agregar

  Subestablecimiento({
    required this.id,
    required this.idEstablecimiento,
    required this.nombre,
    this.descripcion,
    this.logotipo,
    this.membrete,
  });

  factory Subestablecimiento.fromMap(Map<String, dynamic> map) {
    return Subestablecimiento(
      id: map['id'] as String,
      idEstablecimiento: map['id_establecimiento'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      logotipo: map['logotipo'] as String?,   // agregar
      membrete: map['membrete'] as String?,   // agregar
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'membrete': membrete,
    };
  }
}