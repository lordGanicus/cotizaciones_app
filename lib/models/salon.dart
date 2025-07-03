import 'servicio_incluido.dart';
import 'refrigerio.dart';

class Salon {
  final String id;
  final String nombre;
  final int capacidadMesas;
  final int capacidadSillas;
  final String? descripcion;
  final DateTime createdAt;

  final List<ServicioIncluido> servicios; 
  final List<Refrigerio> refrigerios;     

  Salon({
    required this.id,
    required this.nombre,
    required this.capacidadMesas,
    required this.capacidadSillas,
    this.descripcion,
    required this.createdAt,
    required this.servicios,     
    required this.refrigerios,   
  });

  factory Salon.fromMap(
    Map<String, dynamic> map,
    List<ServicioIncluido> servicios,
    List<Refrigerio> refrigerios,
  ) {
    return Salon(
      id: map['id'],
      nombre: map['nombre_salon'],
      capacidadMesas: map['capacidad_mesas'],
      capacidadSillas: map['capacidad_sillas'],
      descripcion: map['descripcion'],
      createdAt: DateTime.parse(map['created_at']),
      servicios: servicios,        
      refrigerios: refrigerios,    
    );
  }
}