/*import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/cotizacion_model.dart';
import '../widgets/resumen_line.dart';

class ResumenPage extends StatelessWidget {
  final List<CotizacionItem> cotizaciones;
  final String hotelName;
  final Color primaryColor;
  final String logoPath;

  const ResumenPage({
    super.key,
    required this.cotizaciones,
    required this.hotelName,
    required this.primaryColor,
    required this.logoPath,
  });

  double get subtotal =>
      cotizaciones.fold(0, (sum, item) => sum + item.total);

  double get descuento {
    // Descuento del 5% si el subtotal es mayor a 1000 Bs
    return subtotal > 1000 ? subtotal * 0.05 : 0;
  }

  double get total => subtotal - descuento;

  @override
  Widget build(BuildContext context) {
    // Agrupar cotizaciones por cliente
    final Map<String, List<CotizacionItem>> cotizacionesPorCliente = {};
    for (var item in cotizaciones) {
      if (!cotizacionesPorCliente.containsKey(item.nombreCliente)) {
        cotizacionesPorCliente[item.nombreCliente] = [];
      }
      cotizacionesPorCliente[item.nombreCliente]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen - $hotelName'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Encabezado con información del hotel
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: Image.asset(
                          logoPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.hotel,
                            size: 50,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hotelName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hora: ${TimeOfDay.now().format(context)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'COT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título de sección
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: const Text(
                  'DETALLE DE COTIZACIÓN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Lista de cotizaciones agrupadas por cliente
              Expanded(
                child: ListView(
                  children: [
                    ...cotizacionesPorCliente.entries.map((entry) {
                      final subtotalCliente = entry.value.fold(
                          0.0, (sum, item) => sum + item.total);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con nombre del cliente
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 8.0,
                              bottom: 8.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Items del cliente
                          ...entry.value.map((item) => Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.detalle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} Bs',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${item.total.toStringAsFixed(2)} Bs',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),

                          // Subtotal por cliente
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${subtotalCliente.toStringAsFixed(2)} Bs',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Resumen de pagos
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ResumenLine(
                        label: 'Subtotal:',
                        value: subtotal,
                        showDiscount: false,
                      ),
                      ResumenLine(
                        label: 'Descuento (5%):',
                        value: -descuento,
                        showDiscount: subtotal > 1000,
                      ),
                      const Divider(height: 20),
                      ResumenLine(
                        label: 'TOTAL A PAGAR:',
                        value: total,
                        isTotal: true,
                        showDiscount: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  // Botón de imprimir
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.print, color: primaryColor),
                      label: Text(
                        'Imprimir',
                        style: TextStyle(color: primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Lógica para imprimir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preparando documento para imprimir...'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Botón principal
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Cotización confirmada con éxito'),
                            backgroundColor: AppColors.successColor,
                          ),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/