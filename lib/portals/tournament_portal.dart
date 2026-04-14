import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';
import '../constants.dart';

class _ScheduledGame {
  final String title;
  final String location;
  final String field;
  final String tournamentDay;
  final DateTime startTime;
  final String status;

  const _ScheduledGame({
    required this.title,
    required this.location,
    required this.field,
    required this.tournamentDay,
    required this.startTime,
    required this.status,
  });
}

class TournamentPortal extends StatefulWidget {
  const TournamentPortal({super.key});

  @override
  State<TournamentPortal> createState() => _TournamentPortalState();
}

class _TournamentPortalState extends State<TournamentPortal> {
  bool _isLocked = true; // Simulating locked state until tournament starts

  final List<_ScheduledGame> _games = [
    _ScheduledGame(
      title: 'Atiba Hutchinson 13 Greatest Assist',
      location: 'Central Gardens • Toronto',
      field: 'Field 7',
      tournamentDay: 'Tournament Day 2',
      startTime: DateTime.now().add(const Duration(hours: 6, minutes: 30)),
      status: 'Upcoming',
    ),
    _ScheduledGame(
      title: 'AH13 Deeds Derby',
      location: 'Lakeshore Grounds • Toronto',
      field: 'Field 3',
      tournamentDay: 'Tournament Day 2',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      status: 'Scheduled',
    ),
    _ScheduledGame(
      title: 'Greatest Assist: Semi-Final',
      location: 'Central Gardens • Toronto',
      field: 'Field 1',
      tournamentDay: 'Tournament Day 3',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 4, minutes: 15)),
      status: 'Scheduled',
    ),
    _ScheduledGame(
      title: 'Championship Match',
      location: 'City Central Stadium',
      field: 'Main Pitch',
      tournamentDay: 'Tournament Day 4',
      startTime: DateTime.now().add(const Duration(days: 3, hours: 1, minutes: 45)),
      status: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Tournament',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                _isLocked ? 'Locked' : 'Unlocked',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(width: 10),
              Switch(
                value: !_isLocked,
                onChanged: (val) => setState(() => _isLocked = !val),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        Expanded(child: _isLocked ? _buildLockedState() : _buildUnlockedState()),
      ],
    );
  }

  Widget _buildLockedState() {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35))),

        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.5), width: 2),
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(
                  FontAwesomeIcons.lock,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 32),
              
              Text(
                'TOURNAMENT LOCKED',
                style: AppTextStyles.headlineLarge.copyWith(
                  letterSpacing: 4,
                  color: AppColors.textTertiary,
                ),
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Season starts in 02:14:35',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                ),
              ).animate().fadeIn(delay: 500.ms).shimmer(duration: 2.seconds),

              const SizedBox(height: 48),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'The arena is being prepared. Train hard, sharpen your skills, and return when the gates open.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedState() {
    final now = DateTime.now();
    final upcoming = _games.toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TournamentHeroCard(
          title: 'AH13 Tournament Week',
          subtitle: 'Your next matches are queued — stay ready.',
          imageAsset: AppImages.stadium,
          chipText: 'LIVE SCHEDULE',
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('YOUR GAMES', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, letterSpacing: 2)),
            const Spacer(),
            Text(
              '${upcoming.length} scheduled',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(upcoming.length, (index) {
          final game = upcoming[index];
          final delay = (index * 70).ms;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ScheduledGameCard(game: game, now: now)
                .animate()
                .fadeIn(duration: 280.ms, delay: delay)
                .slideX(begin: 0.04, end: 0, delay: delay, curve: Curves.easeOutCubic),
          );
        }),
        const SizedBox(height: 6),
        Text(
          'Tip: schedules can change — this is currently placeholder data.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
        ).animate().fadeIn(delay: 280.ms),
      ],
    );
  }
}

class _TournamentHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final String chipText;

  const _TournamentHeroCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(imageAsset, fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    chipText,
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                ),
                const Spacer(),
                Text(title, style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledGameCard extends StatelessWidget {
  final _ScheduledGame game;
  final DateTime now;

  const _ScheduledGameCard({required this.game, required this.now});

  String _formatWhen(DateTime dateTime) {
    String two(int v) => v.toString().padLeft(2, '0');

    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(local.year, local.month, local.day);
    final dayDiff = thatDay.difference(today).inDays;

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '${hour12}:${two(local.minute)} $ampm';

    if (dayDiff == 0) return 'Today • $time';
    if (dayDiff == 1) return 'Tomorrow • $time';
    return '${local.month}/${local.day} • $time';
  }

  String _formatCountdown(DateTime dateTime) {
    final diff = dateTime.difference(now);
    if (diff.isNegative) return 'Started';
    final totalMinutes = diff.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours >= 24) {
      final days = hours ~/ 24;
      final remHours = hours % 24;
      return 'In ${days}d ${remHours}h';
    }
    if (hours > 0) return 'In ${hours}h ${minutes}m';
    return 'In ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Text(
                          game.status.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaPill(icon: Icons.schedule, text: _formatWhen(game.startTime)),
                      _MetaPill(icon: Icons.timelapse, text: _formatCountdown(game.startTime)),
                      _MetaPill(icon: Icons.place, text: game.location),
                      _MetaPill(icon: Icons.crop_square, text: game.field),
                      _MetaPill(icon: Icons.emoji_events, text: game.tournamentDay),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.0)),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String status;
  final String image;
  final bool isFeatured;

  const _TournamentCard({
    required this.title,
    required this.date,
    required this.location,
    required this.status,
    required this.image,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isFeatured ? 240 : 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceVariant),
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
          // Background
          Positioned.fill(
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isFeatured) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FEATURED',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.textTertiary),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  title,
                  style: isFeatured 
                      ? AppTextStyles.headlineMedium.copyWith(color: Colors.white)
                      : AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
