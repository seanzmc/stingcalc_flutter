import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final Widget? labelWidget;
  final int? divisions;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

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
    this.onSubmitted,
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
          child: KeyboardListener(
            focusNode: FocusNode(
              skipTraversal: true,
            ), // Dummy node for listener? No, we want to listen to the Slider's focus.
            // Actually, KeyboardListener needs to be around the focused widget.
            // But Slider uses the passed focusNode.
            // We can't easily wrap Slider's internal focus node if we pass one.
            // If we wrap Slider in KeyboardListener, events bubble up.
            // So we can use a Focus widget wrapping the Slider, but Slider requests its own focus.
            // Let's try wrapping with CallbackShortcuts which is cleaner for "Enter".
            onKeyEvent: (event) {
              // Check for Enter key
              if (onSubmitted != null &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                  event is KeyUpEvent) {
                // Trigger on KeyUp to avoid repeats or conflicts
                onSubmitted!();
              }
            },
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              focusNode: focusNode,
            ),
          ),
        ),
      ],
    );
  }
}
