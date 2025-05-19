import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ResumenLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const ResumenLine({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false, required bool showDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} Bs',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: value < 0 ? AppColors.errorColor : null,
            ),
          ),
        ],
      ),
    );
  }
}