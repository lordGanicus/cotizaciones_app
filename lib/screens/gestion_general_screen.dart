import 'package:flutter/material.dart';
import 'servicios/servicios_screen.dart';
import 'refrigerios/refrigerios_screen.dart';
import 'salon/salones_screen.dart';
import 'habitaciones/habitaciones_screen.dart';

class GestionGeneralScreen extends StatelessWidget {
  const GestionGeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {
        'icon': Icons.miscellaneous_services,
        'label': 'Servicios Incluidos',
        'screen': const ServiciosScreen(),
      },
      {
        'icon': Icons.fastfood,
        'label': 'Refrigerios',
        'screen': const RefrigeriosScreen(),
      },
      {
        'icon': Icons.meeting_room,
        'label': 'Salones',
        'screen': const SalonesScreen(),
      },
      {
        'icon': Icons.bed,
        'label': 'Habitaciones',
        'screen': const HabitacionesScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión General'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona un módulo para gestionar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...buttons.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  icon: Icon(item['icon'] as IconData),
                  label: Text(item['label'] as String),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => item['screen'] as Widget,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}