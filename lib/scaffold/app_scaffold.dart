import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ascent/constants.dart';
import 'package:ascent/scaffold/ah13_image_background.dart';
import '../theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final isLeaderboard = path.startsWith('/leaderboard');
    final isTournament = path.startsWith('/tournament');
    final isDeeds = path.startsWith('/deeds');

    return Scaffold(
      extendBody: true,
      body: Ah13ImageBackground(
        imageAsset: AppImages.contact,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Ah13PortalHeader(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 68,
        width: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
            ],
            border: Border.all(color: isDeeds ? Colors.white.withValues(alpha: 0.6) : Colors.transparent, width: 2),
          ),
          child: FloatingActionButton(
            onPressed: () => context.go('/deeds'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: Icon(
              FontAwesomeIcons.tasks,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomItem(
                  icon: FontAwesomeIcons.trophy,
                  label: 'Leaderboard',
                  selected: isLeaderboard,
                  onTap: () => context.go('/leaderboard'),
                ),
                const SizedBox(width: 48), // space for FAB notch
                _BottomItem(
                  icon: FontAwesomeIcons.futbol,
                  label: 'Tournament',
                  selected: isTournament,
                  onTap: () => context.go('/tournament'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Ah13PortalHeader extends StatelessWidget {
  const Ah13PortalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppImages.ah13AppLogo,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 44, height: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AH13 Deeds App',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.05);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: clampedTextScaler,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, height: 1.0),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 2,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }
}
