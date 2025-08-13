import 'package:flutter/material.dart';
import '../constants/app_colors.dart';


class HotelCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  const HotelCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.hotelColors[name] ?? Colors.blueGrey;
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.hotel,
                    size: 50,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}