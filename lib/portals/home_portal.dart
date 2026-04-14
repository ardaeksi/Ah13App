import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';
import '../constants.dart';
import '../auth/auth_provider.dart';
import '../scaffold/ah13_image_background.dart';

class HomePortal extends StatelessWidget {
  const HomePortal({super.key});

  @override
  Widget build(BuildContext context) {
    return Ah13ImageBackground(
      // Swap this to your uploaded background image asset path.
      // If you tell me the filename you uploaded in Assets panel, I’ll wire it here.
      imageAsset: AppImages.appBackground,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: const _HomeHeaderBranding(),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textTertiary),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PortalCard(
                  title: 'ATIBA DEEDS',
                  subtitle: 'Build your legacy',
                  image: AppImages.playerKick,
                  icon: FontAwesomeIcons.tasks,
                  color: AppColors.primary,
                  onTap: () => context.go('/deeds'),
                  delay: 100,
                ),
                const SizedBox(height: 16),
                _PortalCard(
                  title: 'LEADERBOARD',
                  subtitle: 'You are ranked #42',
                  image: AppImages.trophy,
                  icon: FontAwesomeIcons.trophy,
                  color: AppColors.white,
                  onTap: () => context.go('/leaderboard'),
                  delay: 200,
                ),
                const SizedBox(height: 16),
                _PortalCard(
                  title: 'TOURNAMENTS',
                  subtitle: 'Next event in 2 days',
                  image: AppImages.stadium,
                  icon: FontAwesomeIcons.futbol,
                  color: Colors.white,
                  onTap: () => context.go('/tournament'),
                  delay: 300,
                ),
                const SizedBox(height: 80), // Bottom padding for nav bar
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _HomeHeaderBranding extends StatelessWidget {
  const _HomeHeaderBranding();

  @override
  Widget build(BuildContext context) {
    // Put your logo asset paths here (upload them via Assets panel first).
    // Example: ['assets/images/ah13_logo.png', 'assets/images/foundation_logo.png']
    const logoAssets = <String>[AppImages.ahLogo];

    return FlexibleSpaceBar(
      centerTitle: true,
      titlePadding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 12),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoAssets.isNotEmpty) ...[
            _TopLogosRow(logoAssets: logoAssets),
            const SizedBox(height: 10),
          ],
          const _Ah13BrandLockup(),
        ],
      ),
    );
  }
}

class _TopLogosRow extends StatelessWidget {
  final List<String> logoAssets;
  const _TopLogosRow({required this.logoAssets});

  @override
  Widget build(BuildContext context) {
    final items = logoAssets.take(3).toList(growable: false);

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Image.asset(
              items[i],
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

/// AH13 brand title with metallic "AH" and red "13", plus subtitle.
class _Ah13BrandLockup extends StatelessWidget {
  const _Ah13BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Metallic gradient for "AH"
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8E8E8), // light silver
                  Color(0xFFB0B0B0), // mid silver
                  Color(0xFF7A7A7A), // deep silver
                ],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              blendMode: BlendMode.srcIn,
              child: Text(
                'AH',
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: Colors.white, // masked by shader
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Solid red for "13"
            Text(
              '13',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'GREATEST DEEDS',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 3.2,
          ),
        ),
      ],
    );
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ).animate().scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
            ),
            
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0);
  }
}
