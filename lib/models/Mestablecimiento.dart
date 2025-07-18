// lib/models/Mestablecimiento.dart

class Establecimiento {
  final String id;
  final String nombre;
  final String? logotipoUrl;
  final String? logotipoPublicId;
  final String? membreteUrl;
  final String? membretePublicId;

  Establecimiento({
    required this.id,
    required this.nombre,
    this.logotipoUrl,
    this.logotipoPublicId,
    this.membreteUrl,
    this.membretePublicId,
  });

  factory Establecimiento.fromMap(Map<String, dynamic> map) {
    return Establecimiento(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      logotipoUrl: map['logotipo_url'] as String?,
      logotipoPublicId: map['logotipo_public_id'] as String?,
      membreteUrl: map['membrete_url'] as String?,
      membretePublicId: map['membrete_public_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'logotipo_url': logotipoUrl,
      'logotipo_public_id': logotipoPublicId,
      'membrete_url': membreteUrl,
      'membrete_public_id': membretePublicId,
    };
  }
}