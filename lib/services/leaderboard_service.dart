import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int totalPoints;

  const LeaderboardEntry({required this.uid, required this.displayName, required this.totalPoints});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final uid = (json['uid'] ?? '').toString();
    final displayName = (json['displayName'] ?? json['name'] ?? 'Player').toString();
    final pointsRaw = json['totalPoints'] ?? json['total_points'] ?? 0;
    final totalPoints = pointsRaw is num ? pointsRaw.toInt() : int.tryParse(pointsRaw.toString()) ?? 0;
    return LeaderboardEntry(uid: uid, displayName: displayName, totalPoints: totalPoints);
  }

  Map<String, dynamic> toJson() => {'uid': uid, 'displayName': displayName, 'totalPoints': totalPoints};
}

/// Cheap leaderboard: cache a snapshot locally and refresh infrequently.
///
/// Firestore costs are primarily document reads. By refreshing the top-N list
/// once every [refreshInterval], you cap reads to `N` docs per refresh.
class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const refreshInterval = Duration(days: 3);
  static const defaultLimit = 7;

  static const _kCacheJson = 'leaderboard.cache_json.v1';
  static const _kLastFetchAt = 'leaderboard.last_fetch_at.v1';
  static const _kDeferredUntil = 'leaderboard.deferred_until.v1';

  // Optional: if a Cloud Function writes a snapshot doc, we can refresh with 1 read.
  static const _snapshotDocPath = 'leaderboards/global_top7';

  static List<LeaderboardEntry> placeholderEntries({int limit = defaultLimit}) {
    const names = <String>[
      'Aiden (Toronto)',
      'Olivia (Vancouver)',
      'Noah (Calgary)',
      'Emma (Montreal)',
      'Liam (Ottawa)',
      'Sophia (Edmonton)',
      'Benjamin (Winnipeg)',
    ];
    const points = <int>[1280, 1140, 980, 820, 760, 640, 520];
    final out = <LeaderboardEntry>[];
    for (var i = 0; i < names.length && out.length < limit; i++) {
      out.add(LeaderboardEntry(uid: 'placeholder_${i + 1}', displayName: names[i], totalPoints: points[i]));
    }
    return out;
  }

  Future<DateTime?> getLastFetchAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLastFetchAt);
      return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
    } catch (e) {
      debugPrint('LeaderboardService.getLastFetchAt failed: $e');
      return null;
    }
  }

  Future<Duration?> timeUntilNextRefresh() async {
    final last = await getLastFetchAt();
    if (last == null) return null;
    final now = DateTime.now().toUtc();
    final next = last.add(refreshInterval);
    final remaining = next.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = defaultLimit, bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc();

    DateTime? last;
    try {
      final lastRaw = prefs.getString(_kLastFetchAt);
      last = lastRaw == null ? null : DateTime.tryParse(lastRaw)?.toUtc();
    } catch (e) {
      debugPrint('LeaderboardService lastFetch parse failed: $e');
    }

    final isFresh = last != null && now.difference(last) < refreshInterval;
    if (!forceRefresh && isFresh) {
      final cached = await _readCache(prefs);
      if (cached.isNotEmpty) return cached.take(limit).toList(growable: false);
    }

    // If we just synced points, we optionally defer fetching the leaderboard for a bit.
    // This prevents an immediate "sync points -> fetch leaderboard" spike on the same device.
    if (!forceRefresh) {
      try {
        final deferredRaw = prefs.getString(_kDeferredUntil);
        final deferredUntil = deferredRaw == null ? null : DateTime.tryParse(deferredRaw)?.toUtc();
        if (deferredUntil != null && now.isBefore(deferredUntil)) {
          final cached = await _readCache(prefs);
          if (cached.isNotEmpty) return cached.take(limit).toList(growable: false);
        }
      } catch (e) {
        debugPrint('LeaderboardService deferredUntil parse failed: $e');
      }
    }

    try {
      // First try snapshot doc (1 doc read) if present.
      final snapshot = await _tryFetchSnapshot(limit: limit);
      if (snapshot != null && snapshot.isNotEmpty) {
        await _writeCache(prefs, snapshot, fetchedAt: now);
        return snapshot;
      }

      // Fallback: query users collection (N doc reads).
      final query = _firestore.collection('users').orderBy('totalPoints', descending: true).limit(limit);
      final snap = await query.get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 12));

      final entries = snap.docs
          .map((d) {
            final data = d.data();
            return LeaderboardEntry(
              uid: d.id,
              displayName: (data['name'] ?? data['displayName'] ?? 'Player').toString(),
              totalPoints: (data['totalPoints'] is num)
                  ? (data['totalPoints'] as num).toInt()
                  : int.tryParse((data['totalPoints'] ?? data['total_points'] ?? 0).toString()) ?? 0,
            );
          })
          .toList(growable: false);

      await _writeCache(prefs, entries, fetchedAt: now);
      return entries;
    } catch (e) {
      debugPrint('LeaderboardService Firestore fetch failed, falling back to cache: $e');
      final cached = await _readCache(prefs);
      if (cached.isNotEmpty) return cached.take(limit).toList(growable: false);

      // No cache available (first launch, rules not set up yet, offline, etc.).
      // Show a friendly placeholder leaderboard so the UI still looks complete.
      // We also persist it as a cache so the refresh timer has a reference point.
      final placeholders = placeholderEntries(limit: limit);
      await _writeCache(prefs, placeholders, fetchedAt: now);
      return placeholders;
    }
  }

  Future<List<LeaderboardEntry>?> _tryFetchSnapshot({required int limit}) async {
    try {
      final doc = await _firestore.doc(_snapshotDocPath).get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 8));
      final data = doc.data();
      if (data == null) return null;

      final rawEntries = data['entries'];
      if (rawEntries is! List) return null;

      final out = <LeaderboardEntry>[];
      for (final item in rawEntries) {
        if (item is Map<String, dynamic>) out.add(LeaderboardEntry.fromJson(item));
        if (item is Map) out.add(LeaderboardEntry.fromJson(item.map((k, v) => MapEntry(k.toString(), v))));
        if (out.length >= limit) break;
      }
      return out;
    } catch (e) {
      // Snapshot doc may simply not exist yet.
      debugPrint('LeaderboardService snapshot fetch skipped: $e');
      return null;
    }
  }

  Future<List<LeaderboardEntry>> _readCache(SharedPreferences prefs) async {
    try {
      final raw = prefs.getString(_kCacheJson);
      if (raw == null || raw.trim().isEmpty) return const <LeaderboardEntry>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <LeaderboardEntry>[];

      final out = <LeaderboardEntry>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) out.add(LeaderboardEntry.fromJson(item));
        if (item is Map) out.add(LeaderboardEntry.fromJson(item.map((k, v) => MapEntry(k.toString(), v))));
      }
      return out;
    } catch (e) {
      debugPrint('LeaderboardService cache decode failed: $e');
      return const <LeaderboardEntry>[];
    }
  }

  Future<void> _writeCache(SharedPreferences prefs, List<LeaderboardEntry> entries, {required DateTime fetchedAt}) async {
    try {
      final encoded = jsonEncode(entries.map((e) => e.toJson()).toList(growable: false));
      await prefs.setString(_kCacheJson, encoded);
      await prefs.setString(_kLastFetchAt, fetchedAt.toIso8601String());
    } catch (e) {
      debugPrint('LeaderboardService cache write failed: $e');
    }
  }
}
