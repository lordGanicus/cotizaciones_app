import 'servicio_incluido.dart';

class Salon {
  final String id;
  final String idEstablecimiento; 
  final String nombre;
  final int capacidadMesas;
  final int capacidadSillas;
  final String? descripcion;
  final DateTime createdAt;

  final List<ServicioIncluido> servicios;

  Salon({
    required this.id,
    required this.idEstablecimiento, 
    required this.nombre,
    required this.capacidadMesas,
    required this.capacidadSillas,
    this.descripcion,
    required this.createdAt,
    required this.servicios,
  });

  factory Salon.fromMap(
    Map<String, dynamic> map,
    List<ServicioIncluido> servicios,
  ) {
    return Salon(
      id: map['id'],
      idEstablecimiento: map['id_establecimiento'], 
      nombre: map['nombre_salon'],
      capacidadMesas: map['capacidad_mesas'],
      capacidadSillas: map['capacidad_sillas'],
      descripcion: map['descripcion'],
      createdAt: DateTime.parse(map['created_at']),
      servicios: servicios,
    );
  }
}