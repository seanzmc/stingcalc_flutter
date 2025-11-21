import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataReadout extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final bool isLarge;

  const DataReadout({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Darker background for contrast
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.surface,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
