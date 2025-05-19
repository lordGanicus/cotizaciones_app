import 'package:flutter/material.dart';
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

  double get descuento => subtotal >= 800 ? 50 : 0;

  double get total => subtotal - descuento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen - $hotelName'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: Image.asset(
                          logoPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.hotel,
                            size: 40,
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
                        'Fecha: ${DateTime.now().toLocal().toString().split(" ")[0]}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Hora: ${TimeOfDay.now().format(context)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'DETALLE DE COTIZACIÓN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: cotizaciones.length,
                  itemBuilder: (context, index) {
                    final item = cotizaciones[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.detalle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} Bs',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ResumenLine(
                        label: 'Subtotal:',
                        value: subtotal,
                      ),
                      ResumenLine(
                        label: 'Descuento:',
                        value: -descuento,
                      ),
                      const Divider(),
                      ResumenLine(
                        label: 'TOTAL A PAGAR:',
                        value: total,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cotización enviada con éxito'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Confirmar y Enviar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver a editar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}