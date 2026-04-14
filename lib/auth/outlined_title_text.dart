import 'package:flutter/material.dart';

/// Renders text with a slim outline for better contrast on busy backgrounds.
class OutlinedTitleText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;

  const OutlinedTitleText({
    super.key,
    required this.text,
    required this.textStyle,
    this.outlineColor = Colors.black,
    this.outlineWidth = 2,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final fillStyle = textStyle.copyWith(foreground: null);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..color = outlineColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text,
            textAlign: textAlign,
            style: textStyle.copyWith(foreground: strokePaint)),
        Text(text, textAlign: textAlign, style: fillStyle),
      ],
    );
  }
}
