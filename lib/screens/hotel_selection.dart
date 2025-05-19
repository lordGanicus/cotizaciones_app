import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/hotel_card.dart';
import 'bienvenida.dart';

class HotelSelectionPage extends StatelessWidget {
  const HotelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SELECCIONE SU HOTEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 40),
              HotelCard(
                name: 'Rey Palac',
                imagePath: 'assets/ReyPalac.png',
                onTap: () => _navigateToWelcome(context, 'Rey Palac'),
              ),
              const SizedBox(height: 20),
              HotelCard(
                name: 'Madero',
                imagePath: 'assets/Madero.png',
                onTap: () => _navigateToWelcome(context, 'Madero'),
              ),
              const SizedBox(height: 20),
              HotelCard(
                name: 'Altus',
                imagePath: 'assets/AltusLogo.png',
                onTap: () => _navigateToWelcome(context, 'Altus'),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Salir',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWelcome(BuildContext context, String hotelName) {
    final color = AppColors.hotelColors[hotelName] ?? Colors.blueGrey;
    final imagePath = 'assets/${hotelName.replaceAll(' ', '')}.png';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BienvenidaPage(
          hotelName: hotelName,
          primaryColor: color,
          logoPath: imagePath,
        ),
      ),
    );
  }
}