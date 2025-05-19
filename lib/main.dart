import 'package:cotizaciones_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'screens/hotel_selection.dart';

void main() {
  runApp(const CotizacionApp());
}

class CotizacionApp extends StatelessWidget {
  const CotizacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Cotizaciones Hoteleras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.hotelColors['Rey Palac']!,
          secondary: AppColors.hotelColors['Madero']!,
          surface: AppColors.cardBackground,
          background: AppColors.primaryBackground,
          onBackground: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.primaryBackground,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.cardBackground,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 1,
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.hotelColors['Rey Palac']!,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const HotelSelectionPage(),
    );
  }
}