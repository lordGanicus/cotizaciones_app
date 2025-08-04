class Usuario {
  final String id;
  final String ci;
  final String nombreCompleto;
  final String celular;
  final String genero;
  final String avatar;
  final String idRol;
  final String? rolNombre;
  final String? idEstablecimiento;
  final String? establecimientoNombre;
  final String? idSubestablecimiento;
  final String email;
  final List<String> otrosEstablecimientos;

  Usuario({
    required this.id,
    required this.ci,
    required this.nombreCompleto,
    required this.celular,
    required this.genero,
    required this.avatar,
    required this.idRol,
    required this.email,
    this.rolNombre,
    this.idEstablecimiento,
    this.establecimientoNombre,
    this.idSubestablecimiento,
    this.otrosEstablecimientos = const [],
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      ci: map['ci'],
      nombreCompleto: map['nombre_completo'],
      celular: map['celular'] ?? '',
      genero: map['genero'] ?? 'otro',
      avatar: map['avatar'] ?? '',
      idRol: map['id_rol'],
      rolNombre: map['rol_nombre'],
      idEstablecimiento: map['id_establecimiento'],
      establecimientoNombre: map['establecimiento_nombre'],
      idSubestablecimiento: map['id_subestablecimiento'],
      email: map['email'] ?? '',
      otrosEstablecimientos: (map['otros_establecimientos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ci': ci,
      'nombre_completo': nombreCompleto,
      'celular': celular,
      'genero': genero,
      'avatar': avatar,
      'id_rol': idRol,
      'id_establecimiento': idEstablecimiento,
      'id_subestablecimiento': idSubestablecimiento,
      'email': email,
      'otros_establecimientos': otrosEstablecimientos,
    };
  }

  Usuario copyWith({
    String? id,
    String? ci,
    String? nombreCompleto,
    String? celular,
    String? genero,
    String? avatar,
    String? idRol,
    String? email,
    String? idEstablecimiento,
    String? idSubestablecimiento,
    List<String>? otrosEstablecimientos,
  }) {
    return Usuario(
      id: id ?? this.id,
      ci: ci ?? this.ci,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      celular: celular ?? this.celular,
      genero: genero ?? this.genero,
      avatar: avatar ?? this.avatar,
      idRol: idRol ?? this.idRol,
      email: email ?? this.email,
      idEstablecimiento: idEstablecimiento ?? this.idEstablecimiento,
      idSubestablecimiento: idSubestablecimiento ?? this.idSubestablecimiento,
      otrosEstablecimientos: otrosEstablecimientos ?? this.otrosEstablecimientos,
    );
  }
}