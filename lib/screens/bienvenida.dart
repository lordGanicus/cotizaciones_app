import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'cotizacion.dart';

class BienvenidaPage extends StatelessWidget {
  final String hotelName;
  final Color primaryColor;
  final String logoPath;

  const BienvenidaPage({
    super.key,
    required this.hotelName,
    required this.primaryColor,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor.withOpacity(0.05),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.hotel,
                    size: 80,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hotelName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Bienvenido al sistema de cotizaciones\nPresione siguiente para empezar una nueva cotización',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CotizacionPage(
                        hotelName: hotelName,
                        primaryColor: primaryColor,
                        logoPath: logoPath,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'SIGUIENTE',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Volver',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}