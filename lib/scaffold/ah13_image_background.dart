import 'package:flutter/material.dart';

/// Image-based background wrapper used for the initial (Home) page.
///
/// Keeps content readable by adding a subtle dark overlay + bottom vignette.
class Ah13ImageBackground extends StatelessWidget {
  final String imageAsset;
  final Widget child;

  const Ah13ImageBackground({super.key, required this.imageAsset, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              // If an asset path changes, avoid a crash and still render the UI.
              return const ColoredBox(color: Colors.black);
            },
          ),
        ),
        // Global dark tint for contrast
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
        ),
        // Slight bottom vignette to anchor cards
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
