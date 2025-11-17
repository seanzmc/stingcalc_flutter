import 'package:flutter/material.dart';

class ClearButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const ClearButton({
    super.key,
    required this.onPressed,
    this.label = 'Clear',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}