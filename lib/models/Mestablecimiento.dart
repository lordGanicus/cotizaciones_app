// lib/models/Mestablecimiento.dart

class Establecimiento {
  final String id;
  final String nombre;
  final String? logotipo;          // URL o path guardado en BD
  final String? logotipoPublicId;  // Para manejar Cloudinary (no en BD)
  final String? membrete;
  final String? membretePublicId;  // Para manejar Cloudinary (no en BD)
  final String checkin;            // Hora de ingreso
  final String checkout;           // Hora de salida

  Establecimiento({
    required this.id,
    required this.nombre,
    this.logotipo,
    this.logotipoPublicId,
    this.membrete,
    this.membretePublicId,
    this.checkin = "14:00",   // valor por defecto si no viene de BD
    this.checkout = "12:00",  // valor por defecto si no viene de BD
  });

  factory Establecimiento.fromMap(Map<String, dynamic> map) {
    return Establecimiento(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      logotipo: map['logotipo'] as String?,
      logotipoPublicId: map['logotipo_public_id'] as String?,
      membrete: map['membrete'] as String?,
      membretePublicId: map['membrete_public_id'] as String?,
      checkin: (map['checkin'] ?? "14:00").toString(),
      checkout: (map['checkout'] ?? "12:00").toString(),
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
      'checkin': checkin,
      'checkout': checkout,
    };
  }
}