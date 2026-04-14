import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

class LeaderboardPortal extends StatefulWidget {
  const LeaderboardPortal({super.key});

  @override
  State<LeaderboardPortal> createState() => _LeaderboardPortalState();
}

class _LeaderboardPortalState extends State<LeaderboardPortal> {
  final _service = LeaderboardService();

  Future<List<LeaderboardEntry>>? _future;
  Duration? _remaining;
  DateTime? _lastFetch;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _future = _service.getLeaderboard(limit: LeaderboardService.defaultLimit);
    _ticker = Ticker(_onTick)..start();
    _loadCountdown();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (_lastFetch == null) return;
    final now = DateTime.now().toUtc();
    final next = _lastFetch!.add(LeaderboardService.refreshInterval);
    final remaining = next.difference(now);
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  Future<void> _loadCountdown() async {
    final last = await _service.getLastFetchAt();
    if (!mounted) return;
    // If this is the very first app run (no cached fetch yet), still show a
    // sensible countdown instead of “Loading…” forever.
    setState(() => _lastFetch = last ?? DateTime.now().toUtc());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthProvider, String?>((a) => a.currentUser?.uid);

    return Column(
      children: [
        _LeaderboardHeader(remaining: _remaining),
        const Divider(color: AppColors.surfaceVariant),
        Expanded(
          child: FutureBuilder<List<LeaderboardEntry>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) {
                final msg = snap.error?.toString() ?? '';
                final isPermission = msg.contains('permission-denied') || msg.contains('Missing or insufficient permissions');
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      isPermission
                          ? 'Leaderboard is blocked by Firestore rules.\nAllow reads for leaderboards/global_top7 (and optionally users).'
                          : 'Could not load leaderboard.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final entries = snap.data ?? const <LeaderboardEntry>[];
              if (entries.isEmpty) {
                return Center(child: Text('No players yet.', style: AppTextStyles.bodyMedium));
              }

              final me = uid == null ? null : entries.where((e) => e.uid == uid).cast<LeaderboardEntry?>().firstOrNull;
              final myRank = me == null ? null : (entries.indexWhere((e) => e.uid == uid) + 1);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final rank = index + 1;
                        final isTop3 = rank <= 3;
                        final isMe = uid != null && e.uid == uid;
                        final rankColor = _rankColor(rank);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary.withValues(alpha: 0.14)
                                : (isTop3 ? rankColor.withValues(alpha: 0.10) : AppColors.surface),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMe
                                  ? AppColors.primary.withValues(alpha: 0.55)
                                  : (isTop3 ? rankColor.withValues(alpha: 0.45) : AppColors.surfaceVariant),
                            ),
                          ),
                          child: ListTile(
                            leading: SizedBox(
                              width: 44,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '#$rank',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: isTop3 ? rankColor : AppColors.textTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              isMe ? '${e.displayName} (You)' : e.displayName,
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${e.totalPoints}',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms).slideX();
                      },
                    ),
                  ),
                  if (uid != null)
                    _StickyMeBar(
                      displayName: me?.displayName ?? 'You',
                      points: me?.totalPoints ?? 0,
                      rank: myRank,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.blueGrey;
    if (rank == 3) return Colors.brown;
    return AppColors.textSecondary;
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.remaining});

  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final remainingText = remaining == null ? 'Loading refresh timer…' : _formatRemaining(remaining!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Leaderboard', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            remaining == null ? remainingText : 'Next refresh in $remainingText',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('RANK', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary))),
              Expanded(flex: 3, child: Text('PLAYER', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary))),
              Text('XP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRemaining(Duration d) {
    final totalHours = d.inHours;
    final days = totalHours ~/ 24;
    final hours = totalHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _StickyMeBar extends StatelessWidget {
  const _StickyMeBar({required this.displayName, required this.points, required this.rank});

  final String displayName;
  final int points;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final rankText = rank == null ? '' : ' • #$rank';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 44, child: Align(alignment: Alignment.center, child: Icon(Icons.person_rounded, color: AppColors.textTertiary))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$displayName$rankText', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                Text('Keep climbing!', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text('$points', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 600.ms);
  }
}

/// Minimal ticker to update the refresh countdown without external packages.
class Ticker {
  Ticker(this.onTick);

  final void Function(Duration elapsed) onTick;

  Stopwatch? _watch;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _watch = Stopwatch()..start();
    _loop();
  }

  Future<void> _loop() async {
    while (_running) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!_running) break;
      onTick(_watch?.elapsed ?? Duration.zero);
    }
  }

  void dispose() {
    _running = false;
    _watch?.stop();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
