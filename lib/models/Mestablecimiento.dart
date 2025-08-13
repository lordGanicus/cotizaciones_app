// lib/models/Mestablecimiento.dart

class Establecimiento {
  final String id;
  final String nombre;
  final String? logotipo;        // URL o path guardado en BD
  final String? logotipoPublicId; // Para manejar Cloudinary (no en BD)
  final String? membrete;
  final String? membretePublicId; // Para manejar Cloudinary (no en BD)

  Establecimiento({
    required this.id,
    required this.nombre,
    this.logotipo,
    this.logotipoPublicId,
    this.membrete,
    this.membretePublicId,
  });

  factory Establecimiento.fromMap(Map<String, dynamic> map) {
    return Establecimiento(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      logotipo: map['logotipo'] as String?,
      logotipoPublicId: map['logotipo_public_id'] as String?,
      membrete: map['membrete'] as String?,
      membretePublicId: map['membrete_public_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'logotipo': logotipo,
      'logotipo_public_id': logotipoPublicId,
      'membrete': membrete,
      'membrete_public_id': membretePublicId,
    };
  }

}
