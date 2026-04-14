import 'package:flutter/material.dart';
import 'package:ascent/constants.dart';
import 'package:ascent/scaffold/ah13_image_background.dart';
import 'package:ascent/theme.dart';

/// AH13-style background for auth screens.
///
/// Uses the Atiba image with a strong dark overlay and a thin red accent line.
class Ah13LoginBackground extends StatelessWidget {
  final Widget child;
  const Ah13LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Ah13ImageBackground(
            imageAsset: AppImages.atibaBackgroundNew,
            child: const SizedBox.shrink(),
          ),
        ),
        // Stronger overlay for auth readability
        Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35))),
        // Thin red accent line near the top
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.paddingOf(context).top + 4,
          child: Container(height: 2, color: AppColors.primary.withValues(alpha: 0.95)),
        ),
        child,
      ],
    );
  }
}
