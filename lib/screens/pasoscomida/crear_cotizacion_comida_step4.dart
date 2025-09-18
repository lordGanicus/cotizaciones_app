import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/cotizacion_comida_provider.dart';
import 'resumen_final_factura.dart';

class CrearCotizacionComidaStep4 extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const CrearCotizacionComidaStep4({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  @override
  ConsumerState<CrearCotizacionComidaStep4> createState() =>
      _CrearCotizacionComidaStep4State();
}

class _CrearCotizacionComidaStep4State
    extends ConsumerState<CrearCotizacionComidaStep4> {
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

  bool _isSaving = false;

  Future<void> _guardarCotizacion() async {
    final cotizacion = ref.read(cotizacionComidaProvider);

    if (cotizacion.itemsComida.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay platos agregados para guardar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      final idCotizacion = widget.idCotizacion;

      // Buscar o crear cliente
      final clienteExistente = await supabase
          .from('clientes')
          .select('id')
          .eq('ci', cotizacion.ciCliente)
          .maybeSingle();

      String idCliente;
      if (clienteExistente == null) {
        final insertCliente = await supabase.from('clientes').insert({
          'nombre_completo': cotizacion.nombreCliente,
          'ci': cotizacion.ciCliente,
        }).select('id').single();
        idCliente = insertCliente['id'] as String;
      } else {
        idCliente = clienteExistente['id'] as String;
      }

      // Calcular total
      final totalCalculado =
          cotizacion.itemsComida.fold<double>(0, (sum, i) => sum + i.subtotal);

      // Eliminar items existentes
      await supabase
          .from('items_cotizacion')
          .delete()
          .eq('id_cotizacion', idCotizacion)
          .eq('tipo', 'comida');

      // Preparar items con detalles incluyendo fecha y hora
      final itemsMap = cotizacion.itemsComida.map((item) {
        final detalles = {
          'descripcion': item.descripcion,
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
          'subtotal': item.subtotal,
          'fecha_evento': cotizacion.fechaEvento != null
              ? DateFormat('dd/MM/yyyy').format(cotizacion.fechaEvento!)
              : null,
          'hora_evento': cotizacion.horaEvento != null
              ? '${cotizacion.horaEvento!.hour.toString().padLeft(2, '0')}:${cotizacion.horaEvento!.minute.toString().padLeft(2, '0')}'
              : null,
        };

        return {
          'id_cotizacion': idCotizacion,
          'servicio': item.descripcion,
          'unidad': 'Unidad',
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
          'descripcion': item.descripcion,
          'detalles': detalles,
          'tipo': 'comida',
        };
      }).toList();

      await supabase.from('items_cotizacion').insert(itemsMap);

      // Actualizar total en la cotización
      await supabase
          .from('cotizaciones')
          .update({
            'total': totalCalculado,
            'id_cliente': idCliente,
          })
          .eq('id', idCotizacion);

      // 🔹 Limpiar los ítems en el provider después de guardar
      ref.read(cotizacionComidaProvider.notifier).limpiar();

      setState(() => _isSaving = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResumenFinalCotizacionComidaPage(
            idCotizacion: idCotizacion,
            nombreCliente: cotizacion.nombreCliente,
            ciCliente: cotizacion.ciCliente,
            idSubestablecimiento: widget.idSubestablecimiento,
          ),
        ),
      );
    } catch (e, st) {
      setState(() => _isSaving = false);
      debugPrint('❌ Error guardando cotización restaurante: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la cotización: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotizacion = ref.watch(cotizacionComidaProvider);

    String fechaEvento = cotizacion.fechaEvento != null
        ? DateFormat('dd/MM/yyyy').format(cotizacion.fechaEvento!)
        : '-';
    String horaEvento = cotizacion.horaEvento != null
        ? '${cotizacion.horaEvento!.hour.toString().padLeft(2, '0')}:${cotizacion.horaEvento!.minute.toString().padLeft(2, '0')}'
        : '-';

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Resumen y Confirmación'),
        backgroundColor: darkBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subestablecimiento:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
            Text(
              cotizacion.nombreSubestablecimiento.isEmpty
                  ? '-'
                  : cotizacion.nombreSubestablecimiento,
              style:
                  TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Text('Cliente:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
            Text(
              cotizacion.nombreCliente.isEmpty
                  ? '-'
                  : '${cotizacion.nombreCliente} (CI: ${cotizacion.ciCliente})',
              style: TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Text('Fecha del Evento:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
            Text(fechaEvento,
                style: TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8))),
            const SizedBox(height: 8),
            Text('Hora del Evento:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
            Text(horaEvento,
                style: TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8))),
            const SizedBox(height: 20),
            Text('Platos Agregados:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: darkBlue)),
            Expanded(
              child: ListView.separated(
                itemCount: cotizacion.itemsComida.length,
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final item = cotizacion.itemsComida[index];
                  return ListTile(
                    title: Text(item.descripcion,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: darkBlue)),
                    subtitle: Text(
                      'Cantidad: ${item.cantidad}    Precio unitario: Bs ${item.precioUnitario.toStringAsFixed(2)}\nSubtotal: Bs ${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(color: darkBlue.withOpacity(0.7)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: darkBlue.withOpacity(0.4)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryGreen)),
                Text('Bs ${cotizacion.total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryGreen)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarCotizacion,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Cotización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
