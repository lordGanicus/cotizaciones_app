import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'crear_cotizacion_salon_step4.dart';

class Paso3CotizacionSalonPage extends ConsumerWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento; // <-- agregado

  const Paso3CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento, // <-- agregado
  }) : super(key: key);

  // Colores definidos
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color cardBackground = Colors.white;
  final Color textColor = const Color(0xFF2D4059);
  final Color secondaryTextColor = const Color(0xFF555555);
  final Color errorColor = Colors.redAccent;

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: darkBlue.withOpacity(0.8)),
      floatingLabelStyle: TextStyle(color: primaryGreen),
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildAdicionalItem(ItemAdicional item, int index, BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: darkBlue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.descripcion,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} Bs',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${item.subtotal.toStringAsFixed(2)} Bs',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: errorColor),
              onPressed: () {
                final listaSalones = ref.read(cotizacionSalonProvider);
                if (listaSalones.isNotEmpty) {
                  final cotizacion = listaSalones[0];
                  final nuevosAdicionales = List<ItemAdicional>.from(cotizacion.itemsAdicionales)
                    ..removeAt(index);
                  ref.read(cotizacionSalonProvider.notifier).actualizarSalon(
                    0,
                    cotizacion.copyWith(itemsAdicionales: nuevosAdicionales),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAdicional(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: lightBackground,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar ítem adicional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: descController,
                    decoration: _inputDecoration('Descripción'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final trimmed = v.trim();
                      if (trimmed.isEmpty) return 'Requerido';
                      // Validar que inicie con mayúscula A-Z
                      if (!RegExp(r'^[A-ZÁÉÍÓÚÜÑ]').hasMatch(trimmed)) {
                        return 'La descripción debe iniciar con mayúscula';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cantidadController,
                    decoration: _inputDecoration('Cantidad'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Cantidad inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: precioController,
                    decoration: _inputDecoration('Precio unitario (Bs)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Precio inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: secondaryTextColor,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final desc = descController.text.trim();
                            final cantidad = int.parse(cantidadController.text.trim());
                            final precio = double.parse(precioController.text.trim());

                            final notifier = ref.read(cotizacionSalonProvider.notifier);
                            final listaSalones = ref.read(cotizacionSalonProvider);

                            if (listaSalones.isNotEmpty) {
                              final cotizacion = listaSalones[0];
                              final nuevosAdicionales = List<ItemAdicional>.from(cotizacion.itemsAdicionales)
                                ..add(ItemAdicional(
                                  descripcion: desc,
                                  cantidad: cantidad,
                                  precioUnitario: precio,
                                ));
                              notifier.actualizarSalon(
                                0,
                                cotizacion.copyWith(itemsAdicionales: nuevosAdicionales),
                              );
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final adicionales = cotizacion.itemsAdicionales;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Ítems Adicionales'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Ítems adicionales'),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoAdicional(context, ref),
                  icon: Icon(Icons.add, size: 20, color: Colors.white),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (adicionales.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: darkBlue.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay ítems adicionales agregados',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    ...adicionales.asMap().entries.map((entry) {
                      return _buildAdicionalItem(entry.value, entry.key, context, ref);
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Paso4CotizacionSalonPage(
                        idCotizacion: idCotizacion,
                        idEstablecimiento: idEstablecimiento,
                        idUsuario: idUsuario,
                        idSubestablecimiento: idSubestablecimiento, // <-- pasamos aquí también
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
