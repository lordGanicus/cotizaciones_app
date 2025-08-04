import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/itemComida.dart';
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

      // Eliminar items anteriores
      await supabase
          .from('items_cotizacion')
          .delete()
          .eq('id_cotizacion', idCotizacion)
          .eq('tipo', 'comida');

      // Insertar nuevos items (sin 'total')
      final itemsMap = cotizacion.itemsComida.map((item) {
        return {
          'id_cotizacion': idCotizacion,
          'servicio': item.descripcion,
          'unidad': 'Unidad',
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
          'descripcion': item.descripcion,
          'detalles': {},
          'tipo': 'comida',
        };
      }).toList();

      await supabase.from('items_cotizacion').insert(itemsMap);

      // Actualizar total en cotizaciones
      final totalCalculado =
          cotizacion.itemsComida.fold<double>(0, (sum, i) => sum + i.subtotal);

      await supabase
          .from('cotizaciones')
          .update({'total': totalCalculado})
          .eq('id', idCotizacion);

      setState(() => _isSaving = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResumenFinalCotizacionComidaPage(
            idCotizacion: idCotizacion,
          ),
        ),
      );
    } catch (e, st) {
      setState(() => _isSaving = false);
      debugPrint('❌ Error guardando cotización comida: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la cotización: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotizacion = ref.watch(cotizacionComidaProvider);

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
            Text(
              'Subestablecimiento:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue),
            ),
            Text(
              cotizacion.nombreSubestablecimiento.isEmpty
                  ? '-'
                  : cotizacion.nombreSubestablecimiento,
              style: TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Text(
              'Cliente:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue),
            ),
            Text(
              cotizacion.nombreCliente.isEmpty
                  ? '-'
                  : '${cotizacion.nombreCliente} (CI: ${cotizacion.ciCliente})',
              style: TextStyle(fontSize: 16, color: darkBlue.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            Text(
              'Platos Agregados:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: darkBlue),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: cotizacion.itemsComida.length,
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final item = cotizacion.itemsComida[index];
                  return ListTile(
                    title: Text(
                      item.descripcion,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, color: darkBlue),
                    ),
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
                Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  'Bs ${cotizacion.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: primaryGreen,
                  ),
                ),
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
