import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalChart extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final String centerText;
  final String? subCenterText;

  const TerminalChart({
    super.key,
    required this.sections,
    required this.centerText,
    this.subCenterText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubicEmphasized,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subCenterText != null) ...[
                const SizedBox(height: 4),
                Text(
                  subCenterText!,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
