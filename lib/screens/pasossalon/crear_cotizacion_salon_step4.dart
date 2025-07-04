import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'resumen_final_cotizacion_salon.dart';

class Paso4CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;

  const Paso4CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
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

    final subtotalSalon = cotizacion.precioSalonTotal;
    final subtotalAdicionales = cotizacion.itemsAdicionales.fold<double>(
      0,
      (sum, i) => sum + i.subtotal,
    );
    final total = subtotalSalon + subtotalAdicionales;

    final minutosEvento = cotizacion.horaFin.difference(cotizacion.horaInicio).inMinutes;
    final horasValidas = minutosEvento > 0 ? (minutosEvento / 60).ceil() : 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 4: Resumen final de cotización')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              '📋 Detalles del evento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${cotizacion.nombreCliente} (CI: ${cotizacion.ciCliente})'),
            Text('Tipo de evento: ${cotizacion.tipoEvento}'),
            Text('Fecha: ${_formatearFecha(cotizacion.fechaEvento)}'),
            Text('Horario: ${_formatearHora(cotizacion.horaInicio)} - ${_formatearHora(cotizacion.horaFin)}'),
            Text('Participantes: ${cotizacion.participantes}'),
            Text('Tipo de armado: ${cotizacion.tipoArmado}'),
            Text('Salón: ${cotizacion.nombreSalon} (Capacidad: ${cotizacion.capacidad})'),
            const Divider(height: 30),

            const Text('🏢 Alquiler del salón', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text('$horasValidas hora${horasValidas > 1 ? 's' : ''}'),
              trailing: Text('${subtotalSalon.toStringAsFixed(2)} Bs'),
            ),
            const Divider(height: 30),

            const Text('🧾 Ítems adicionales', style: TextStyle(fontWeight: FontWeight.bold)),
            if (cotizacion.itemsAdicionales.isEmpty)
              const Text('Sin ítems adicionales.')
            else
              ...cotizacion.itemsAdicionales.map((i) => ListTile(
                    title: Text(i.descripcion),
                    subtitle: Text('${i.cantidad} x ${i.precioUnitario.toStringAsFixed(2)} Bs'),
                    trailing: Text('${i.subtotal.toStringAsFixed(2)} Bs'),
                  )),
            const Divider(height: 30),

            ListTile(
              title: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              trailing: Text(
                '${total.toStringAsFixed(2)} Bs',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar cotización'),
              onPressed: () async {
                final supabase = Supabase.instance.client;
                try {
                  // Insertar cotización principal
                  final cotizacionRes = await supabase
                      .from('cotizaciones')
                      .insert({
                        'id_usuario': cotizacion.idUsuario,
                        'estado': 'borrador',
                        'total': total,
                      })
                      .select()
                      .single();

                  final idNuevaCotizacion = cotizacionRes['id'] as String;

                  // Insertar alquiler salón como item
                  await supabase.from('items_cotizacion').insert({
                    'id_cotizacion': idNuevaCotizacion,
                    'servicio': 'Alquiler de salón',
                    'unidad': 'Hora',
                    'cantidad': horasValidas,
                    'precio_unitario': subtotalSalon / horasValidas,
                    'descripcion':
                        'Alquiler de salón para evento ${cotizacion.tipoEvento} (${cotizacion.participantes} personas)',
                    'tipo': 'salon',
                    'detalles': jsonEncode({
                      'fecha': cotizacion.fechaEvento.toIso8601String(),
                      'hora_inicio': cotizacion.horaInicio.toIso8601String(),
                      'hora_fin': cotizacion.horaFin.toIso8601String(),
                      'tipo_armado': cotizacion.tipoArmado,
                      'nombre_salon': cotizacion.nombreSalon,
                      'capacidad': cotizacion.capacidad,
                    }),
                  });

                  // Insertar ítems adicionales
                  for (final i in cotizacion.itemsAdicionales) {
                    await supabase.from('items_cotizacion').insert({
                      'id_cotizacion': idNuevaCotizacion,
                      'servicio': i.descripcion,
                      'unidad': 'Unidad',
                      'cantidad': i.cantidad,
                      'precio_unitario': i.precioUnitario,
                      'tipo': 'salon',
                      'descripcion': i.descripcion,
                      'detalles': jsonEncode({'tipo': 'adicional'}),
                    });
                  }

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResumenFinalCotizacionSalonPage(
                        idCotizacion: idNuevaCotizacion,
                        nombreCliente: cotizacion.nombreCliente,
                        ciCliente: cotizacion.ciCliente,
                      ),
                    ),
                  );
                } catch (e, stack) {
                  print('Error guardando cotización: $e');
                  print(stack);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar cotización: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _formatearHora(DateTime hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}
