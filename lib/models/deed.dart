import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeedStatus {
  pending,
  assigned,
  completed;

  static DeedStatus fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'pending':
        return DeedStatus.pending;
      case 'completed':
        return DeedStatus.completed;
      case 'assigned':
      case 'active':
      case 'in_progress':
      case 'inprogress':
        return DeedStatus.assigned;
      default:
        return DeedStatus.assigned;
    }
  }

  String get firestoreValue {
    switch (this) {
      case DeedStatus.pending:
        return 'pending';
      case DeedStatus.assigned:
        return 'assigned';
      case DeedStatus.completed:
        return 'completed';
    }
  }
}

@immutable
class Deed {
  final String id;
  final String title;
  final String description;
  final int points;
  final String highlight;
  final String iconKey;
  final DeedStatus status;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  /// Local-only: when the deed can be completed again.
  final DateTime? nextAvailableAt;

  /// Local-only: how many days must pass before it can be completed again.
  /// Defaults to 14 per your requirements.
  final int cooldownDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Deed({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.highlight,
    required this.iconKey,
    required this.status,
    required this.assignedAt,
    required this.completedAt,
    required this.nextAvailableAt,
    this.cooldownDays = 14,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == DeedStatus.completed;

  bool get isAvailable {
    if (status != DeedStatus.completed) return true;
    final next = nextAvailableAt;
    if (next == null) return false;
    return DateTime.now().toUtc().isAfter(next) || DateTime.now().toUtc().isAtSameMomentAs(next);
  }

  Deed copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? highlight,
    String? iconKey,
    DeedStatus? status,
    DateTime? assignedAt,
    DateTime? completedAt,
    DateTime? nextAvailableAt,
    int? cooldownDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deed(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      highlight: highlight ?? this.highlight,
      iconKey: iconKey ?? this.iconKey,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      nextAvailableAt: nextAvailableAt ?? this.nextAvailableAt,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    // Firestore Timestamp has a toDate() method, but we avoid a direct type import.
    try {
      final dynamic any = v;
      final dynamic date = any.toDate?.call();
      if (date is DateTime) return date.toUtc();
    } catch (_) {}
    if (v is String) {
      return DateTime.tryParse(v)?.toUtc();
    }
    return null;
  }

  /// Be permissive about keys so we can adapt to your existing Firestore schema.
  factory Deed.fromFirestore(String id, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['name'] ?? '').toString().trim();
    final desc = (data['desc'] ?? data['description'] ?? data['details'] ?? '').toString().trim();
    final highlight = (data['highlight'] ?? data['subtitle'] ?? '').toString().trim();
    final pointsRaw = data['points'] ?? data['xp'] ?? 0;
    final points = pointsRaw is num ? pointsRaw.toInt() : int.tryParse(pointsRaw.toString()) ?? 0;

    final status = DeedStatus.fromString(data['status']?.toString());
    final iconKey = (data['icon_key'] ?? data['icon'] ?? 'task').toString().trim();

    return Deed(
      id: id,
      title: title.isEmpty ? 'Deed' : title,
      description: desc.isEmpty ? 'Complete this deed.' : desc,
      points: points,
      highlight: highlight.isEmpty ? 'Level up.' : highlight,
      iconKey: iconKey.isEmpty ? 'task' : iconKey,
      status: status,
      assignedAt: _parseDate(data['assigned_at'] ?? data['assignedAt']),
      completedAt: _parseDate(data['completed_at'] ?? data['completedAt']),
      nextAvailableAt: null,
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      updatedAt: _parseDate(data['updated_at'] ?? data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'desc': description,
      'highlight': highlight,
      'points': points,
      'icon_key': iconKey,
      'status': status.firestoreValue,
      'assigned_at': assignedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// JSON-serializable definition used for local (client-side) deed catalogs.
///
/// This is your “scale-friendly JSON object” format.
@immutable
class DeedDefinition {
  final String id;
  final String label;
  final String description;
  final int points;
  final String highlight;
  final String iconKey;

  /// How long until the deed can be completed again.
  final int cooldownDays;

  /// Optional: group/sort/filter later without schema changes.
  final String category;

  /// Optional: allows you to roll out catalog changes while keeping old progress.
  final int version;

  const DeedDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.points,
    required this.highlight,
    required this.iconKey,
    this.cooldownDays = 14,
    this.category = 'general',
    this.version = 1,
  });

  factory DeedDefinition.fromJson(Map<String, dynamic> json) {
    final pointsRaw = json['points'] ?? 0;
    final cooldownRaw = json['cooldown_days'] ?? json['cooldownDays'] ?? 14;
    final versionRaw = json['version'] ?? 1;
    return DeedDefinition(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      points: pointsRaw is num ? pointsRaw.toInt() : int.tryParse(pointsRaw.toString()) ?? 0,
      highlight: (json['highlight'] ?? '').toString(),
      iconKey: (json['icon_key'] ?? json['iconKey'] ?? 'task').toString(),
      cooldownDays: cooldownRaw is num ? cooldownRaw.toInt() : int.tryParse(cooldownRaw.toString()) ?? 14,
      category: (json['category'] ?? 'general').toString(),
      version: versionRaw is num ? versionRaw.toInt() : int.tryParse(versionRaw.toString()) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'points': points,
        'highlight': highlight,
        'icon_key': iconKey,
        'cooldown_days': cooldownDays,
        'category': category,
        'version': version,
      };
}

class DeedIcons {
  static IconData fromKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'user_check':
      case 'profile':
      case 'account':
        return Icons.verified_user_outlined;
      case 'bullseye':
      case 'target':
        return Icons.gps_fixed_rounded;
      case 'handshake':
      case 'team':
        return Icons.groups_2_outlined;
      case 'shield':
      case 'defense':
        return Icons.shield_outlined;
      case 'run':
      case 'running':
        return Icons.directions_run_rounded;
      case 'task':
      default:
        return Icons.task_alt_rounded;
    }
  }
}
