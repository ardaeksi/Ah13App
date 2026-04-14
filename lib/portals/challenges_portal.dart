import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../auth/auth_provider.dart';
import '../models/deed.dart';
import '../services/deed_service.dart';
import '../theme.dart';

class AtibaDeedsPortal extends StatefulWidget {
  const AtibaDeedsPortal({super.key});

  @override
  State<AtibaDeedsPortal> createState() => _AtibaDeedsPortalState();
}

class _DeedsPortalExplanation extends StatelessWidget {
  const _DeedsPortalExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        'Complete Your Deeds, Compete in leaderboard and follow your tournament schedule!\n'
        'Share your deeds on instagram with #ah13deeds to be featured in our tournament page and get a shoutout from Atiba!',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
          height: 1.45,
        ),
      ),
    ).animate().fadeIn(duration: 450.ms, delay: 250.ms);
  }
}

class _AtibaDeedsPortalState extends State<AtibaDeedsPortal> {
  final DeedService _deedService = DeedService();

  Future<void>? _bootstrapFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid != null) {
      _bootstrapFuture ??= _deedService.pullTotalPointsFromFirebase(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthProvider, String?>((a) => a.currentUser?.uid);
    if (uid == null) {
      return Center(
        child: Text('Please sign in to view your deeds.', style: AppTextStyles.bodyMedium),
      );
    }

    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, _) => StreamBuilder<List<Deed>>(
        stream: _deedService.watchDeedsForUser(uid),
        builder: (context, snap) {
        final deeds = snap.data ?? const <Deed>[];
        final totalPointsFuture = _deedService.getTotalPoints(uid);

        return Column(
          children: [
            // Points Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.background],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL POINTS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: totalPointsFuture,
                    builder: (context, snap) {
                      final points = snap.data ?? 0;
                      return Text(
                        '$points',
                        style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary),
                      ).animate().scale(curve: Curves.elasticOut);
                    },
                  ),
                  const SizedBox(height: 14),
                  const _DeedsPortalExplanation(),
                ],
              ),
            ),

            // List
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Could not load deeds. Please try again.', style: AppTextStyles.bodyMedium),
                    );
                  }
                  if (deeds.isEmpty) {
                    return Center(
                      child: Text('No deeds assigned yet.', style: AppTextStyles.bodyMedium),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: deeds.length,
                    itemBuilder: (context, index) {
                      final deed = deeds[index];
                      final isCompleted = deed.isCompleted && !deed.isAvailable;
                      final icon = DeedIcons.fromKey(deed.iconKey);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted ? AppColors.white.withValues(alpha: 0.25) : AppColors.surfaceVariant,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.white.withValues(alpha: 0.08) : AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: isCompleted ? AppColors.white : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              deed.title,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  deed.description,
                                  style: AppTextStyles.bodySmall,
                                ),
                                if (isCompleted && deed.nextAvailableAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Available again: ${_formatCountdown(deed.nextAvailableAt!)}',
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${deed.points} XP',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isCompleted
                                ? const Icon(Icons.verified_rounded, color: AppColors.white)
                                : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                            onTap: () => context.push('${AppRoutes.deeds}/${deed.id}', extra: deed),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.06, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  static String _formatCountdown(DateTime nextAvailableAt) {
    final now = DateTime.now().toUtc();
    final diff = nextAvailableAt.difference(now);
    if (diff.isNegative) return 'now';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    if (days <= 0) return '${hours}h';
    return '${days}d ${hours}h';
  }
}
