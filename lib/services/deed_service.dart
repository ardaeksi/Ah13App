import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ascent/models/deed.dart';

/// Local-first deeds + immediate points sync.
///
/// - Deed definitions live in code as JSON-like maps (scale-friendly).
/// - Progress is stored per-user in SharedPreferences.
/// - `totalPoints` is treated as cross-device state:
///   - Pulled from Firestore on bootstrap/login.
///   - Pushed to Firestore after every completed deed.
class DeedService {
  DeedService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _cooldownDefaultDays = 14;
  static const _leaderboardDeferAfterSync = Duration(hours: 1);

  // SharedPreferences keys (namespaced per uid).
  static String _kCatalogVersion(String uid) => 'deeds.catalog_version.$uid';
  static String _kProgressJson(String uid) => 'deeds.progress_json.$uid';
  static String _kTotalPoints(String uid) => 'deeds.total_points.$uid';

  // Cross-service coordination (kept as a raw key to avoid circular imports).
  static const _kLeaderboardDeferredUntil = 'leaderboard.deferred_until.v1';

  final StreamController<List<Deed>> _deedsController = StreamController<List<Deed>>.broadcast();
  String? _activeUid;
  bool _isBootstrapped = false;

  // Best-effort guard to avoid overlapping point writes.
  Future<void>? _pointsSyncInFlight;

  /// Scale-friendly deed catalog (JSON objects).
  ///
  /// You can safely add fields here later without migrations.
  static const List<Map<String, dynamic>> deedCatalogJson = [
    {
      'id': 'clean_mess_not_yours',
      'label': 'Be like Japan’s soccer team and clean a mess that is not yours',
      'description': 'Pick up trash or tidy a shared area that you didn’t make messy.',
      'points': 30,
      'highlight': 'Small actions set the standard.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'gratitude_journal_30_days',
      'label': 'Write a gratitude journal for 30 days about everyone and/or everything you are thankful for',
      'description': 'Write one gratitude entry each day for 30 days.',
      'points': 100,
      'highlight': 'Gratitude builds resilience.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'mindset',
      'version': 1,
    },
    {
      'id': 'savoring_task_today',
      'label': 'Savoring task: For today – practice being in the moment. Just focus and appreciate what you are doing',
      'description': 'Be mindful today—focus on the moment and appreciate what you’re doing.',
      'points': 10,
      'highlight': 'Presence is power.',
      'icon_key': 'target',
      'cooldown_days': 14,
      'category': 'mindset',
      'version': 1,
    },
    {
      'id': 'offline_day_book_10_words',
      'label': 'Offline day! Replace your screen with a book and describe what you read in 10 words',
      'description': 'Spend the day offline, read a book, then summarize it in 10 words.',
      'points': 30,
      'highlight': 'Trade scrolling for growth.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'growth',
      'version': 1,
    },
    {
      'id': 'team_circle_positive_attribute',
      'label': 'Sit in a circle as a team and write one positive attribute about each person',
      'description': 'As a team, write one positive attribute about each teammate.',
      'points': 50,
      'highlight': 'Build your people up.',
      'icon_key': 'team',
      'cooldown_days': 14,
      'category': 'team',
      'version': 1,
    },
    {
      'id': 'team_volunteer_values',
      'label': 'As a team, volunteer for a cause that fits your values',
      'description': 'Volunteer together for a cause you care about.',
      'points': 30,
      'highlight': 'Service strengthens teams.',
      'icon_key': 'team',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'free_space_photo_or_video_x5',
      'label': 'Free space! You decide – take a picture or video (x5)',
      'description': 'Choose your own good deed and document it with 5 photos/videos.',
      'points': 10,
      'highlight': 'Make it yours.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'general',
      'version': 1,
    },
    {
      'id': 'play_with_new_friend',
      'label': 'Go play with someone you have not played with all year or make a new friend',
      'description': 'Invite someone new to play or make a new friend.',
      'points': 20,
      'highlight': 'Connection counts.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'social',
      'version': 1,
    },
    {
      'id': 'call_family_childhood',
      'label': 'Call a family member and ask about their childhood',
      'description': 'Call a family member and learn one childhood story.',
      'points': 20,
      'highlight': 'Stories bring us closer.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'family',
      'version': 1,
    },
    {
      'id': 'lemonade_or_bake_sale_donate',
      'label': 'Set up a lemonade stand or a bake sale and donate the profits',
      'description': 'Raise money with a small stand/sale and donate the profits.',
      'points': 80,
      'highlight': 'Turn effort into impact.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'plant_and_watch_grow',
      'label': 'Plant something and watch it grow!',
      'description': 'Plant a seed/plant and care for it.',
      'points': 30,
      'highlight': 'Nurture something new.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'nature',
      'version': 1,
    },
    {
      'id': 'give_toy_or_books_to_kids',
      'label': 'Give away a toy/toys or book/books to underprivileged kids',
      'description': 'Donate gently used toys/books to kids in need.',
      'points': 20,
      'highlight': 'Give what you can.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'feed_birds_or_ducks',
      'label': 'Feed the birds or ducks at your local park (if permitted)',
      'description': 'If permitted, feed birds/ducks responsibly at a local park.',
      'points': 10,
      'highlight': 'Care for living things.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'nature',
      'version': 1,
    },
    {
      'id': 'clean_trail_park_school_photos',
      'label': 'Go outside and clean up a trail, park or school! Take before and after pictures',
      'description': 'Clean up an outdoor area and take before/after photos.',
      'points': 30,
      'highlight': 'Leave it better than you found it.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'chalk_encouraging_messages',
      'label': 'Write encouraging messages with chalk on the sidewalk',
      'description': 'Write a few positive messages where others can see them.',
      'points': 30,
      'highlight': 'Spread some light.',
      'icon_key': 'target',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'breakfast_in_bed',
      'label': 'Make your parents breakfast in bed!',
      'description': 'Prepare a simple breakfast and surprise your parent/guardian.',
      'points': 20,
      'highlight': 'Love looks like effort.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'family',
      'version': 1,
    },
    {
      'id': 'help_less_privileged_donate',
      'label': 'Help someone who does not have the same privileges as you (i.e., donate to a food bank and/or clothing drive)',
      'description': 'Donate to a food bank/clothing drive or help in another meaningful way.',
      'points': 30,
      'highlight': 'Use what you have to help.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'kindness_jar_30_days',
      'label': 'Create a kindness jar in class or at home by writing down random kind acts for 30 days.',
      'description': 'Write down one kind act each day for 30 days and collect them in a jar.',
      'points': 100,
      'highlight': 'Kindness compounds.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'workout_5_days_straight',
      'label': 'Do 20 pushups, 20 sit ups and 20 jumping jacks 5 days straight!',
      'description': 'Complete the set each day for 5 straight days.',
      'points': 80,
      'highlight': 'Discipline is a superpower.',
      'icon_key': 'run',
      'cooldown_days': 14,
      'category': 'health',
      'version': 1,
    },
    {
      'id': 'set_table_5_days_family_talk',
      'label': 'Set the table for dinner for 5 days straight and ask your family about their day',
      'description': 'Set the table for 5 days and ask each person about their day.',
      'points': 70,
      'highlight': 'Show up at home too.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'family',
      'version': 1,
    },
    {
      'id': 'visit_elderly_home_help',
      'label': 'Ask your parents to visit an elderly home and help for a few hours',
      'description': 'Visit an elderly home with a parent/guardian and volunteer for a few hours.',
      'points': 100,
      'highlight': 'Respect is a deed.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },

    // Additional good deeds
    {
      'id': 'help_homework',
      'label': 'Help someone (i.e. a sibling, classmate, or friend) with their homework',
      'description': 'Help someone understand a topic or finish an assignment.',
      'points': 30,
      'highlight': 'Teach what you know.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'build_birdhouse_or_birdfeeder',
      'label': 'Build a birdhouse or birdfeeder',
      'description': 'Build and place a birdhouse/birdfeeder safely.',
      'points': 20,
      'highlight': 'Create something that helps.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'nature',
      'version': 1,
    },
    {
      'id': 'volunteer_school_library',
      'label': 'Volunteer at your school’s library',
      'description': 'Help the library staff: organize, shelve books, or assist students.',
      'points': 20,
      'highlight': 'Serve where you are.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'community',
      'version': 1,
    },
    {
      'id': 'team_hangout_day',
      'label': 'Hang out as a team for a day (i.e., play board games, watch movies, converse)',
      'description': 'Spend quality time together and get to know each other.',
      'points': 50,
      'highlight': 'Chemistry is built.',
      'icon_key': 'team',
      'cooldown_days': 14,
      'category': 'team',
      'version': 1,
    },
    {
      'id': 'do_chore_unasked',
      'label': 'Do a chore without being asked to',
      'description': 'Pick a helpful chore and do it without being asked.',
      'points': 20,
      'highlight': 'Initiative matters.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'family',
      'version': 1,
    },
    {
      'id': 'donate_animal_shelter',
      'label': 'Donate to an animal shelter',
      'description': 'Donate supplies, food, or money to a local shelter.',
      'points': 40,
      'highlight': 'Kindness includes animals.',
      'icon_key': 'shield',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'help_make_meal_and_dishes',
      'label': 'Help make a meal. Don’t forget the dishes!',
      'description': 'Help cook a meal and do the dishes afterwards.',
      'points': 40,
      'highlight': 'Finish the job.',
      'icon_key': 'task',
      'cooldown_days': 14,
      'category': 'family',
      'version': 1,
    },
    {
      'id': 'handmade_item_gift',
      'label': 'Create a handmade item (i.e., a letter, card, bracelet, trinket) and gift it to someone',
      'description': 'Make something by hand and gift it to someone you appreciate.',
      'points': 20,
      'highlight': 'Thought beats price.',
      'icon_key': 'user_check',
      'cooldown_days': 14,
      'category': 'kindness',
      'version': 1,
    },
    {
      'id': 'secret_helper_week',
      'label': 'Play Secret Helper with your team',
      'description': 'Draw names secretly. Help/be kind to your person for a week. At the end, guess who helped you. Points: +20 for correct guesses, -10 for incorrect guesses.',
      'points': 100,
      'highlight': 'Anonymous kindness hits different.',
      'icon_key': 'team',
      'cooldown_days': 14,
      'category': 'team',
      'version': 1,
    },
  ];

  Stream<List<Deed>> watchDeedsForUser(String uid) {
    _ensureBootstrapped(uid);
    return _deedsController.stream;
  }

  Future<int> getTotalPoints(String uid) async {
    await _ensureBootstrapped(uid);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTotalPoints(uid)) ?? 0;
  }

  Future<void> markCompleted({required String uid, required String deedId}) async {
    await _ensureBootstrapped(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = _readProgress(prefs, uid);
      final now = DateTime.now().toUtc();
      final def = _catalog.firstWhere((d) => d.id == deedId, orElse: () => throw StateError('Unknown deedId=$deedId'));

      final p = progress[deedId] ?? _DeedProgress.empty;
      final nextAllowedAt = p.completedAt?.add(Duration(days: p.cooldownDays ?? def.cooldownDays ?? _cooldownDefaultDays));
      if (nextAllowedAt != null && now.isBefore(nextAllowedAt)) {
        debugPrint('Deed $deedId not available until $nextAllowedAt');
        return;
      }

      progress[deedId] = _DeedProgress(
        completedAt: now,
        cooldownDays: def.cooldownDays,
        definitionVersion: def.version,
      );
      _writeProgress(prefs, uid, progress);

      final current = prefs.getInt(_kTotalPoints(uid)) ?? 0;
      final updated = current + def.points;
      await prefs.setInt(_kTotalPoints(uid), updated);

      await _emit(uid);
      await syncPointsToFirebase(uid);
    } catch (e) {
      debugPrint('markCompleted failed: $e');
      rethrow;
    }
  }

  /// Pulls `totalPoints` from Firebase (source of truth) into local cache.
  ///
  /// Call this on login (or when opening deeds) so the app reflects the server value.
  Future<void> pullTotalPointsFromFirebase(String uid) async {
    await _ensureBootstrapped(uid);
    await _pullTotalPointsFromFirebase(uid);
  }

  /// Writes `totalPoints` to `users/{uid}` immediately.
  ///
  /// This is called after each deed completion so points don't diverge across devices.
  Future<void> syncPointsToFirebase(String uid) async {
    await _ensureBootstrapped(uid);
    await _syncPointsToFirebase(uid);
  }

  // -----------------
  // Internal helpers
  // -----------------

  late final List<DeedDefinition> _catalog = deedCatalogJson.map(DeedDefinition.fromJson).toList(growable: false);

  Future<void> _ensureBootstrapped(String uid) async {
    if (_isBootstrapped && _activeUid == uid) return;
    _activeUid = uid;
    _isBootstrapped = true;

    // Ensure prefs are reachable and data is sanitized.
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = _readProgress(prefs, uid);
      _writeProgress(prefs, uid, progress); // sanitize
    } catch (e) {
      debugPrint('DeedService bootstrap failed: $e');
    }

    await _emit(uid);
    // Fire-and-forget, so opening the page never blocks UI.
    unawaited(_pullTotalPointsFromFirebase(uid));
  }

  Future<void> _pullTotalPointsFromFirebase(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 12));
      final data = snap.data();
      final serverPointsRaw = data?['totalPoints'] ?? data?['total_points'] ?? 0;
      final serverPoints = serverPointsRaw is num ? serverPointsRaw.toInt() : int.tryParse(serverPointsRaw.toString()) ?? 0;

      final prefs = await SharedPreferences.getInstance();

      // Cross-device behavior:
      // - If there is no local value (new install), adopt server.
      // - If local differs (offline progress), keep the higher value and re-sync.
      final local = prefs.getInt(_kTotalPoints(uid));
      if (local == null) {
        await prefs.setInt(_kTotalPoints(uid), serverPoints);
      } else if (serverPoints > local) {
        await prefs.setInt(_kTotalPoints(uid), serverPoints);
      } else if (local > serverPoints) {
        // Best-effort: we have locally accumulated points that the server doesn't yet have.
        unawaited(_syncPointsToFirebase(uid));
      }

      await _emit(uid);
    } catch (e) {
      debugPrint('_pullTotalPointsFromFirebase failed: $e');
    }
  }

  Future<void> _syncPointsToFirebase(String uid) async {
    // Avoid overlapping writes if multiple deed completions happen quickly.
    if (_pointsSyncInFlight != null) return _pointsSyncInFlight!;

    final completer = Completer<void>();
    _pointsSyncInFlight = completer.future;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();
      final localPoints = prefs.getInt(_kTotalPoints(uid)) ?? 0;

      await _firestore.collection('users').doc(uid).set({
        'totalPoints': localPoints,
        'lastPointsSyncAt': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 12));

      // After we push points, defer leaderboard refresh slightly so devices that
      // just synced don't immediately fetch the leaderboard snapshot.
      // This is a best-effort local behavior (no background work when app is closed).
      await prefs.setString(_kLeaderboardDeferredUntil, now.add(_leaderboardDeferAfterSync).toIso8601String());
    } catch (e) {
      debugPrint('_syncPointsToFirebase failed: $e');
    } finally {
      completer.complete();
      _pointsSyncInFlight = null;
    }
  }

  Future<void> _emit(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = _readProgress(prefs, uid);
      final now = DateTime.now().toUtc();

      final deeds = _catalog.map((def) {
        final p = progress[def.id];
        final completedAt = p?.completedAt;
        final cooldownDays = p?.cooldownDays ?? def.cooldownDays;
        final nextAvailableAt = completedAt == null ? null : completedAt.add(Duration(days: cooldownDays));
        final available = completedAt == null || (nextAvailableAt != null && !now.isBefore(nextAvailableAt));

        return Deed(
          id: def.id,
          title: def.label,
          description: def.description,
          points: def.points,
          highlight: def.highlight,
          iconKey: def.iconKey,
          status: available ? DeedStatus.assigned : DeedStatus.completed,
          assignedAt: null,
          completedAt: available ? null : completedAt,
          nextAvailableAt: available ? null : nextAvailableAt,
          cooldownDays: def.cooldownDays,
          createdAt: null,
          updatedAt: null,
        );
      }).toList(growable: false);

      _deedsController.add(deeds);
    } catch (e) {
      debugPrint('_emit failed: $e');
      _deedsController.add(const <Deed>[]);
    }
  }

  static Map<String, _DeedProgress> _readProgress(SharedPreferences prefs, String uid) {
    final raw = prefs.getString(_kProgressJson(uid));
    if (raw == null || raw.trim().isEmpty) return <String, _DeedProgress>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, _DeedProgress>{};

      final map = <String, _DeedProgress>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final p = _DeedProgress.fromJson(value);
          if (p != null) map[key] = p;
        } else if (value is Map) {
          final p = _DeedProgress.fromJson(value.map((k, v) => MapEntry(k.toString(), v)));
          if (p != null) map[key] = p;
        }
      }
      return map;
    } catch (e) {
      debugPrint('_readProgress failed, resetting: $e');
      return <String, _DeedProgress>{};
    }
  }

  static Future<void> _writeProgress(SharedPreferences prefs, String uid, Map<String, _DeedProgress> progress) async {
    final jsonMap = <String, dynamic>{};
    for (final e in progress.entries) {
      jsonMap[e.key] = e.value.toJson();
    }
    await prefs.setString(_kProgressJson(uid), jsonEncode(jsonMap));
  }
}

@immutable
class _DeedProgress {
  final DateTime? completedAt;
  final int? cooldownDays;
  final int? definitionVersion;

  const _DeedProgress({required this.completedAt, required this.cooldownDays, required this.definitionVersion});

  static const empty = _DeedProgress(completedAt: null, cooldownDays: null, definitionVersion: null);

  static _DeedProgress? fromJson(Map<String, dynamic> json) {
    try {
      final completedRaw = json['completed_at'] ?? json['completedAt'];
      final completedAt = completedRaw is String ? DateTime.tryParse(completedRaw)?.toUtc() : null;
      final cooldownRaw = json['cooldown_days'] ?? json['cooldownDays'];
      final cooldownDays = cooldownRaw is num ? cooldownRaw.toInt() : int.tryParse(cooldownRaw?.toString() ?? '');
      final versionRaw = json['definition_version'] ?? json['definitionVersion'];
      final definitionVersion = versionRaw is num ? versionRaw.toInt() : int.tryParse(versionRaw?.toString() ?? '');

      if (completedAt == null) return null;
      return _DeedProgress(completedAt: completedAt, cooldownDays: cooldownDays, definitionVersion: definitionVersion);
    } catch (e) {
      debugPrint('_DeedProgress.fromJson failed: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'completed_at': completedAt?.toIso8601String(),
        'cooldown_days': cooldownDays,
        'definition_version': definitionVersion,
      };
}
