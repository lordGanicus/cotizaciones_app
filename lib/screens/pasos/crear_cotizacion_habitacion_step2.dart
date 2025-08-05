import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_habitacion.dart';
import '../../providers/cotizacion_habitacion_provider.dart';
import 'seleccionar_habitacion_modal.dart';
import 'crear_cotizacion_habitacion_step3.dart';

class CrearCotizacionHabitacionStep2 extends ConsumerWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const CrearCotizacionHabitacionStep2({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  // Colores del diseño
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D4059);
  static const Color textSecondary = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitaciones = ref.watch(cotizacionHabitacionProvider);
    final totalCotizacion = habitaciones.fold<double>(
      0.0,
      (sum, hab) => sum + (hab.tarifa * hab.cantidadNoches * hab.cantidad),
    );

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Agregar Habitaciones',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Información del cliente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cliente',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreCliente,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CI/NIT',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ciCliente.isEmpty ? 'No especificado' : ciCliente,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lista de habitaciones
            Expanded(
              child: habitaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel,
                            size: 48,
                            color: darkBlue.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay habitaciones agregadas',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón para agregar',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: habitaciones.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final hab = habitaciones[index];
                        final subtotal =
                            hab.tarifa * hab.cantidadNoches * hab.cantidad;

                        return Container(
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                            title: Text(
                              hab.nombreHabitacion,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${hab.cantidad} × ${hab.cantidadNoches} noches',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Text(
                              'Bs ${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                                fontSize: 16,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      'Fecha de ingreso',
                                      _formatDate(hab.fechaIngreso),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Fecha de salida',
                                      _formatDate(hab.fechaSalida),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Tarifa por noche',
                                      'Bs ${hab.tarifa.toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Total y botones
            Column(
              children: [
                if (habitaciones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total provisional:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Bs ${totalCotizacion.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: darkBlue.withOpacity(0.5),
                            width: 1.5,
                          ),
                          foregroundColor: darkBlue,
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text('VOLVER'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const SeleccionarHabitacionModal(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: primaryGreen.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('AGREGAR'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (habitaciones.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PasoResumenHabitacionesPage(
                              idCotizacion: idCotizacion,
                              nombreCliente: nombreCliente,
                              ciCliente: ciCliente,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: darkBlue.withOpacity(0.3),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('CONTINUAR'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}