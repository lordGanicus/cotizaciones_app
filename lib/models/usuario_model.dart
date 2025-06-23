class Usuario {
  final String? id; // UUID puede venir null en creación
  final String ci;
  final String nombreCompleto;
  final String? celular;
  final String? firma;
  final String idRol;
  final String? idEstablecimiento;

  Usuario({
    this.id,
    required this.ci,
    required this.nombreCompleto,
    this.celular,
    this.firma,
    required this.idRol,
    this.idEstablecimiento,
  });

  // Para convertir a Map (útil para insertar en la BD)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ci': ci,
      'nombre_completo': nombreCompleto,
      'celular': celular,
      'firma': firma,
      'id_rol': idRol,
      'id_establecimiento': idEstablecimiento,
    };
  }

  // Para crear un Usuario desde un Map (ejemplo: resultado BD)
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      ci: map['ci'],
      nombreCompleto: map['nombre_completo'],
      celular: map['celular'],
      firma: map['firma'],
      idRol: map['id_rol'],
      idEstablecimiento: map['id_establecimiento'],
    );
  }
}

