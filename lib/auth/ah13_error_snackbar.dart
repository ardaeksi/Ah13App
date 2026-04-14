import 'package:flutter/material.dart';

import 'package:ascent/theme.dart';

/// Shows a higher (floating) error message with AH13 styling.
///
/// - Sits higher than the default bottom SnackBar
/// - Black background
/// - Thin red line at the top
class Ah13ErrorSnackBar {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    // Large bottom margin lifts the floating SnackBar upward.
    final margin = EdgeInsets.fromLTRB(16, topPad + 12, 16, size.height * 0.68);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        elevation: 0,
        margin: margin,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 2, decoration: const BoxDecoration(color: AppColors.primary)),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
