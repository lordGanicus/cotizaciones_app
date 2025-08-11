import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itemComida.dart';
import '../../providers/cotizacion_comida_provider.dart';
import 'crear_cotizacion_comida_step2.dart';
import 'crear_cotizacion_comida_step4.dart';

class CrearCotizacionComidaStep3 extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const CrearCotizacionComidaStep3({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

  Future<bool> _confirmarEliminar(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Seguro que quieres eliminar este ítem?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cotizacionComidaProvider).itemsComida;

    void _eliminarItem(String descripcion) async {
      final confirmado = await _confirmarEliminar(context);
      if (!confirmado) return;

      ref
          .read(cotizacionComidaProvider.notifier)
          .eliminarItemPorDescripcion(descripcion);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ítem eliminado'),
          backgroundColor: primaryGreen,
          duration: Duration(milliseconds: 800),
        ),
      );
    }

    void _agregarMas() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionComidaStep2(
            idCotizacion: idCotizacion,
            idEstablecimiento: idEstablecimiento,
            idUsuario: idUsuario,
            idSubestablecimiento: idSubestablecimiento,
          ),
        ),
      );
    }

    void _irAlResumen() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionComidaStep4(
            idCotizacion: idCotizacion,
            idEstablecimiento: idEstablecimiento,
            idUsuario: idUsuario,
            idSubestablecimiento: idSubestablecimiento,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Lista de Platos Agregados'),
        backgroundColor: darkBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No hay platos agregados aún.',
                    style: TextStyle(
                      color: darkBlue.withOpacity(0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          item.descripcion,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          'Cantidad: ${item.cantidad}   |   Precio unitario: Bs ${item.precioUnitario.toStringAsFixed(2)}\nSubtotal: Bs ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _eliminarItem(item.descripcion),
                          tooltip: 'Eliminar ítem',
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _agregarMas,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Agregar más platos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: darkBlue.withOpacity(0.7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: items.isEmpty ? null : _irAlResumen,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ir al resumen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}
