// lib/models/Msubestablecimiento.dart
class Subestablecimiento {
  final String id;
  final String idEstablecimiento;
  final String nombre;
  final String? descripcion;
  final String? logotipo;
  final String? logotipoPublicId;
  final String? membrete;
  final String? membretePublicId;

  Subestablecimiento({
    required this.id,
    required this.idEstablecimiento,
    required this.nombre,
    this.descripcion,
    this.logotipo,
    this.logotipoPublicId,
    this.membrete,
    this.membretePublicId,
  });

  factory Subestablecimiento.fromMap(Map<String, dynamic> map) {
    return Subestablecimiento(
      id: map['id'] as String,
      idEstablecimiento: map['id_establecimiento'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      logotipo: map['logotipo'] as String?,
      logotipoPublicId: map['logotipo_public_id'] as String?,
      membrete: map['membrete'] as String?,
      membretePublicId: map['membrete_public_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_establecimiento': idEstablecimiento,
      'nombre': nombre,
      'descripcion': descripcion,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    };
  }
}