// lib/screens/pasossalon/crear_cotizacion_salon_step2.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'crear_cotizacion_salon_step3.dart';

class Paso2CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;

  const Paso2CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaSalones = ref.watch(cotizacionSalonProvider);

    if (listaSalones.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Cotización no iniciada')),
      );
    }

    final cotizacion = listaSalones[0];
    final notifier = ref.read(cotizacionSalonProvider.notifier);

    // Servicios disponibles ejemplo estático
    final serviciosDisponibles = [
      {'id': 'serv1', 'nombre': 'Proyector', 'precio': 150.0},
      {'id': 'serv2', 'nombre': 'Audio', 'precio': 200.0},
      {'id': 'serv3', 'nombre': 'Catering', 'precio': 500.0},
    ];

    final serviciosSeleccionados = List<String>.from(cotizacion.serviciosSeleccionados);

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 2: Seleccionar servicios')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ...serviciosDisponibles.map((servicio) {
              final idServicio = servicio['id'] as String;
              final nombre = servicio['nombre'] as String;

              final seleccionado = serviciosSeleccionados.contains(idServicio);

              return CheckboxListTile(
                title: Text(nombre),
                value: seleccionado,
                onChanged: (bool? value) {
                  final nuevosServicios = List<String>.from(serviciosSeleccionados);
                  if (value == true && !nuevosServicios.contains(idServicio)) {
                    nuevosServicios.add(idServicio);
                  } else if (value == false) {
                    nuevosServicios.remove(idServicio);
                  }
                  final salonActualizado = cotizacion.copyWith(
                    serviciosSeleccionados: nuevosServicios,
                  );
                  notifier.actualizarSalon(0, salonActualizado);
                },
              );
            }).toList(),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Paso3CotizacionSalonPage(
                      idCotizacion: idCotizacion,
                      idEstablecimiento: idEstablecimiento,
                      idUsuario: idUsuario,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.navigate_next),
              label: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}