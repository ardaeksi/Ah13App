import 'package:flutter/material.dart';

import 'package:ascent/constants.dart';
import 'package:ascent/scaffold/ah13_image_background.dart';

/// App-wide background wrapper.
///
/// Updated to use the branded Atiba background image asset.
class PitchBackground extends StatelessWidget {
  final Widget child;
  const PitchBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Ah13ImageBackground(imageAsset: AppImages.atibaBackgroundNew, child: child);
  }
}
