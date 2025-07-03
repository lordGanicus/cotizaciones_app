class ServicioIncluido {
  final String id;
  final String nombre;
  final double precio;

  ServicioIncluido({required this.id, required this.nombre, required this.precio});
}

class Refrigerio {
  final String id;
  final String nombre;
  final double precioPorPax;
  int cantidadPax; // Editable

  Refrigerio({
    required this.id,
    required this.nombre,
    required this.precioPorPax,
    this.cantidadPax = 0,
  });

  double get subtotal => cantidadPax * precioPorPax;
}

class ItemSalon {
  final String idSalon;
  final String nombreSalon;
  final int capacidad;
  final String descripcion;
  int cantidadHoras;
  DateTime fechaEvento;
  DateTime horaInicio;
  DateTime horaFin;
  int participantes;
  String tipoArmado;

  List<ServicioIncluido> serviciosSeleccionados;
  List<Refrigerio> refrigeriosSeleccionados;

  ItemSalon({
    required this.idSalon,
    required this.nombreSalon,
    required this.capacidad,
    required this.descripcion,
    this.cantidadHoras = 1,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    this.participantes = 0,
    this.tipoArmado = '',
    this.serviciosSeleccionados = const [],
    this.refrigeriosSeleccionados = const [],
  });

  double get precioSalonPorHora {
    // Aquí puedes cambiar si quieres cargar precio de BD o fijo
    return 150.0; // Ejemplo precio fijo por hora
  }

  double get subtotalSalon => precioSalonPorHora * cantidadHoras;

  double get subtotalServicios =>
      serviciosSeleccionados.fold(0, (sum, s) => sum + s.precio);

  double get subtotalRefrigerios =>
      refrigeriosSeleccionados.fold(0, (sum, r) => sum + r.subtotal);

  double get total =>
      subtotalSalon + subtotalServicios + subtotalRefrigerios;
}