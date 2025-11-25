import 'package:flutter/material.dart';

class TerminalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final Widget? labelWidget;
  final int? divisions;
  final FocusNode? focusNode;

  const TerminalSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
    this.labelWidget,
    this.divisions,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) ...[
          labelWidget!,
          const SizedBox(height: 4),
        ] else if (label != null) ...[
          Text(label!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surface,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 0, // No shadow
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            focusNode: focusNode,
          ),
        ),
      ],
    );
  }
}
