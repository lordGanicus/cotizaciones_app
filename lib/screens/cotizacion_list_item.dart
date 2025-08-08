import 'package:flutter/material.dart';

class CotizacionListItem extends StatelessWidget {
  final String fecha;
  final String cliente;
  final String tipo;
  final double total;
  final VoidCallback onTap;

  const CotizacionListItem({
    Key? key,
    required this.fecha,
    required this.cliente,
    required this.tipo,
    required this.total,
    required this.onTap,
  }) : super(key: key);

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'habitación':
        return Icons.bed;
      case 'salón':
        return Icons.event;
      case 'comida':
        return Icons.restaurant;
      default:
        return Icons.receipt;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'habitación':
        return const Color(0xFF00B894);
      case 'salón':
        return const Color(0xFF2D4059);
      case 'comida':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de tipo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getColorForType(tipo).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForType(tipo),
                  color: _getColorForType(tipo),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cliente,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Bs. ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B894),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          fecha,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorForType(tipo).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              color: _getColorForType(tipo),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}