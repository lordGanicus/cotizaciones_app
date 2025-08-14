import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'resumen_final_cotizacion_salon.dart';
import 'crear_cotizacion_salon_step1.dart';

class Paso4CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  Paso4CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color cardBackground = Colors.white;
  final Color textColor = const Color(0xFF2D4059);
  final Color secondaryTextColor = const Color(0xFF555555);
  final Color highlightColor = Color(0xFF00B894).withAlpha((255 * 0.1).toInt());

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20, color: primaryGreen),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String price, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isTotal ? highlightColor : cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: textColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _formatearHora(DateTime hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
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
    final subtotalSalon = cotizacion.precioSalonTotal;
    final subtotalAdicionales = cotizacion.itemsAdicionales.fold<double>(
      0,
      (sum, i) => sum + i.subtotal,
    );
    final total = subtotalSalon + subtotalAdicionales;

    final minutosEvento =
        cotizacion.horaFin.difference(cotizacion.horaInicio).inMinutes;
    final horasValidas = minutosEvento > 0 ? (minutosEvento / 60).ceil() : 1;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Resumen Final'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles del evento
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: darkBlue.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Detalles del evento', icon: Icons.event),
                    const SizedBox(height: 8),
                    _buildDetailItem('Cliente:', cotizacion.nombreCliente),
                    _buildDetailItem('CI/NIT:', cotizacion.ciCliente),
                    _buildDetailItem('Tipo de evento:', cotizacion.tipoEvento),
                    _buildDetailItem('Fecha:',
                        _formatearFecha(cotizacion.fechaEvento)),
                    _buildDetailItem(
                        'Horario',
                        '${_formatearHora(cotizacion.horaInicio)} - ${_formatearHora(cotizacion.horaFin)}'),
                    _buildDetailItem(
                        'Participantes:', cotizacion.participantes.toString()),
                    _buildDetailItem('Tipo de armado:', cotizacion.tipoArmado),
                    _buildDetailItem('Salón:',
                        '${cotizacion.nombreSalon} (Capacidad: ${cotizacion.capacidad})'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Alquiler salón
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: darkBlue.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                        'Alquiler del salón', icon: Icons.meeting_room),
                    const SizedBox(height: 8),
                    _buildPriceItem(
                      '$horasValidas hora${horasValidas > 1 ? 's' : ''}',
                      '${subtotalSalon.toStringAsFixed(2)} Bs',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Items adicionales
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: darkBlue.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Ítems adicionales', icon: Icons.list),
                    const SizedBox(height: 8),
                    if (cotizacion.itemsAdicionales.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No hay ítems adicionales',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      )
                    else
                      Column(
                        children: cotizacion.itemsAdicionales.map((i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        i.descripcion,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${i.subtotal.toStringAsFixed(2)} Bs',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${i.cantidad} x ${i.precioUnitario.toStringAsFixed(2)} Bs',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Total
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: darkBlue.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceItem(
                      'Total a pagar',
                      '${total.toStringAsFixed(2)} Bs',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final supabase = Supabase.instance.client;

                  try {
                    // 🔹 PRINT ARRIBA: antes de cualquier operación
                    print('DEBUG: Cotización recibida: $cotizacion');
                    print('DEBUG: Participantes: ${cotizacion.participantes}');
                    print('DEBUG: Total calculado: $total Bs');

                    String? idCliente;

                    // Buscar cliente por CI
                    if (cotizacion.ciCliente.isNotEmpty) {
                      final clientesPorCI = await supabase
                          .from('clientes')
                          .select('id')
                          .eq('ci', cotizacion.ciCliente)
                          .limit(1);

                      if (clientesPorCI.isNotEmpty) {
                        idCliente = clientesPorCI[0]['id'] as String;
                      }
                    }

                    // Si no se encontró por CI, buscar por nombre
                    if (idCliente == null) {
                      final clientesPorNombre = await supabase
                          .from('clientes')
                          .select('id')
                          .eq('nombre_completo', cotizacion.nombreCliente)
                          .limit(1);

                      if (clientesPorNombre.isNotEmpty) {
                        idCliente = clientesPorNombre[0]['id'] as String;
                      }
                    }

                    // Crear nuevo cliente si no existe
                    if (idCliente == null) {
                      final insertRes = await supabase.from('clientes').insert({
                        'nombre_completo': cotizacion.nombreCliente,
                        if (cotizacion.ciCliente.isNotEmpty) 'ci': cotizacion.ciCliente,
                      }).select('id').single();

                      idCliente = insertRes['id'] as String;
                    }

                    // Insertar cotización
                    final cotizacionRes = await supabase.from('cotizaciones').insert({
                      'id_usuario': idUsuario,
                      'estado': 'borrador',
                      'total': total,
                      'id_cliente': idCliente,
                    }).select().single();

                    final idNuevaCotizacion = cotizacionRes['id'] as String;

                    // Insertar item principal (alquiler del salón)
                    final detallesSalon = {
                      'fecha': cotizacion.fechaEvento.toIso8601String(),
                      'hora_inicio': cotizacion.horaInicio.toIso8601String(),
                      'hora_fin': cotizacion.horaFin.toIso8601String(),
                      'tipo_armado': cotizacion.tipoArmado,
                      'nombre_salon': cotizacion.nombreSalon,
                      'capacidad': cotizacion.capacidad,
                      'participantes': cotizacion.participantes, 
                    };
                    print('DEBUG: Insertando item principal con detalles: $detallesSalon');

                    await supabase.from('items_cotizacion').insert({
                      'id_cotizacion': idNuevaCotizacion,
                      'unidad': 'Hora',
                      'cantidad': horasValidas,
                      'precio_unitario': subtotalSalon / horasValidas,
                      'descripcion': 'Alquiler de salón para evento ${cotizacion.tipoEvento} (${cotizacion.participantes} personas)',
                      'tipo': 'salon',
                      'detalles': jsonEncode(detallesSalon),
                    });

                    // Insertar ítems adicionales
                    for (final i in cotizacion.itemsAdicionales) {
                      final detallesAdicional = {'tipo': 'adicional'};
                      print('DEBUG: Insertando item adicional: ${i.descripcion}, detalles: $detallesAdicional');
                      await supabase.from('items_cotizacion').insert({
                        'id_cotizacion': idNuevaCotizacion,
                        'unidad': 'Unidad',
                        'cantidad': i.cantidad,
                        'precio_unitario': i.precioUnitario,
                        'descripcion': i.descripcion,
                        'tipo': 'salon',
                        'detalles': jsonEncode(detallesAdicional),
                      });
                    }

                    // 🔹 PRINT ABAJO: confirmación
                    print('DEBUG: Cotización guardada correctamente con id: $idNuevaCotizacion');
                    print('DEBUG: Total guardado: $total Bs');

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResumenFinalCotizacionSalonPage(
                          idCotizacion: idNuevaCotizacion,
                          nombreCliente: cotizacion.nombreCliente,
                          ciCliente: cotizacion.ciCliente,
                          idSubestablecimiento: idSubestablecimiento,
                        ),
                      ),
                    );
                  } catch (e, stack) {
                    print('Error guardando cotización: $e');
                    print(stack);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar cotización: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Guardar Cotización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
