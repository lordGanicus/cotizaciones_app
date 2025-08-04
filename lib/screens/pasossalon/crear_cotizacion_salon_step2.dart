import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'crear_cotizacion_salon_step3.dart';

class Paso2CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const Paso2CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  // Colores definidos
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color cardBackground = Colors.white;
  final Color textColor = const Color(0xFF2D4059);
  final Color secondaryTextColor = const Color(0xFF555555);

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkBlue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaSalones = ref.watch(cotizacionSalonProvider);

    if (listaSalones.isEmpty) {
      return Scaffold(
        backgroundColor: lightBackground,
        body: Center(
          child: Text(
            'Cotización no iniciada',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    final cotizacion = listaSalones[0];

    String formatoFecha(DateTime fecha) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }

    String formatoHora(DateTime hora) {
      final h = hora.hour.toString().padLeft(2, '0');
      final m = hora.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Resumen de la Cotización'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Datos del cliente'),
            _buildInfoRow('Nombre:', cotizacion.nombreCliente),
            _buildInfoRow('CI/NIT:', cotizacion.ciCliente),

            const SizedBox(height: 16),
            _buildSectionTitle('Detalles del evento'),
            _buildInfoRow('Tipo de evento:', cotizacion.tipoEvento),
            _buildInfoRow('Fecha:', formatoFecha(cotizacion.fechaEvento)),
            _buildInfoRow('Hora inicio:', formatoHora(cotizacion.horaInicio)),
            _buildInfoRow('Hora fin:', formatoHora(cotizacion.horaFin)),
            _buildInfoRow('Participantes:', cotizacion.participantes.toString()),
            _buildInfoRow('Tipo de armado:', cotizacion.tipoArmado),

            const SizedBox(height: 16),
            _buildSectionTitle('Salón seleccionado'),
            _buildInfoRow('Nombre:', cotizacion.nombreSalon),
            _buildInfoRow('Capacidad:', cotizacion.capacidad.toString()),
            if (cotizacion.descripcion.isNotEmpty)
              _buildInfoRow('Descripción:', cotizacion.descripcion),

            const SizedBox(height: 16),
            _buildSectionTitle('Precio'),
            _buildInfoRow('Precio total (Bs):', cotizacion.precioSalonTotal.toStringAsFixed(2)),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Paso3CotizacionSalonPage(
                        idCotizacion: idCotizacion,
                        idEstablecimiento: idEstablecimiento,
                        idUsuario: idUsuario,
                        idSubestablecimiento: idSubestablecimiento,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continuar', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}