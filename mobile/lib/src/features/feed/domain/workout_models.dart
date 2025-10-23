import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutPost {
  WorkoutPost({
    required this.id,
    required this.userName,
    required this.createdAt,
    this.userAvatarUrl,
    this.workoutTitle,
    this.caption,
    this.imageUrl,
    this.exercises = const [],
    this.metrics = const {},
  });

  final String id;
  final String userName;
  final DateTime? createdAt;
  final String? userAvatarUrl;
  final String? workoutTitle;
  final String? caption;
  final String? imageUrl;
  final List<WorkoutExercise> exercises;
  final Map<String, dynamic> metrics;

  factory WorkoutPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final userName = _stringField(
          data,
          keys: ['userDisplayName', 'username', 'athleteName'],
        ) ??
        'Atleta sem nome';
    final createdAt = _parseDate(data['createdAt'] ?? data['timestamp']);
    final userAvatarUrl = _stringField(
      data,
      keys: ['userPhotoUrl', 'photoUrl', 'avatarUrl'],
    );
    final workoutTitle = _stringField(
      data,
      keys: ['workoutName', 'workoutTitle', 'title'],
    );
    final caption = _stringField(
      data,
      keys: ['description', 'caption', 'notes'],
    );
    final imageUrl = _stringField(
      data,
      keys: ['imageUrl', 'mediaUrl'],
    );

    return WorkoutPost(
      id: snapshot.id,
      userName: userName,
      createdAt: createdAt,
      userAvatarUrl: userAvatarUrl,
      workoutTitle: workoutTitle,
      caption: caption,
      imageUrl: imageUrl,
      exercises: _parseExercises(data['exercises']),
      metrics: _parseMetrics(data['metrics']),
    );
  }

  String get initials {
    final normalized = userName.trim();
    if (normalized.isEmpty) {
      return '?';
    }
    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final part = parts.first;
      if (part.length >= 2) {
        return part.substring(0, 2).toUpperCase();
      }
      return part.substring(0, 1).toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final last = parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    final combined = (first + last).trim();
    if (combined.isEmpty) {
      return '?';
    }
    return combined.toUpperCase();
  }

  String get timeAgo {
    final date = createdAt;
    if (date == null) {
      return 'agora';
    }
    final difference = DateTime.now().difference(date);
    if (difference.isNegative) return 'agora';
    if (difference.inMinutes < 1) return 'agora';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min';
    if (difference.inHours < 24) return '${difference.inHours} h';
    if (difference.inDays < 7) return '${difference.inDays} d';
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 4) return '$weeks sem';
    final months = (difference.inDays / 30).floor();
    if (months < 12) return '$months mes';
    final years = (difference.inDays / 365).floor();
    return '$years ano${years > 1 ? 's' : ''}';
  }

  static String? _stringField(
    Map<String, dynamic> data, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<WorkoutExercise> _parseExercises(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<WorkoutExercise?>((item) {
          if (item is Map<String, dynamic>) {
            return WorkoutExercise.fromMap(item);
          }
          if (item is Map) {
            return WorkoutExercise.fromMap(
              item.map((key, v) => MapEntry(key.toString(), v)),
            );
          }
          return null;
        })
        .whereType<WorkoutExercise>()
        .toList();
  }

  static Map<String, dynamic> _parseMetrics(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return const {};
  }
}

class WorkoutExercise {
  WorkoutExercise({
    required this.name,
    this.sets = const [],
    this.notes,
  });

  final String name;
  final List<WorkoutSet> sets;
  final String? notes;

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      name: (map['name'] ?? map['exerciseName'] ?? 'Exercicio').toString(),
      notes: (map['notes'] ?? map['comment'])?.toString(),
      sets: _parseSets(map['sets']),
    );
  }

  static List<WorkoutSet> _parseSets(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<WorkoutSet?>((item) {
          if (item is Map<String, dynamic>) {
            return WorkoutSet.fromMap(item);
          }
          if (item is Map) {
            return WorkoutSet.fromMap(
              item.map((key, v) => MapEntry(key.toString(), v)),
            );
          }
          return null;
        })
        .whereType<WorkoutSet>()
        .toList();
  }
}

class WorkoutSet {
  WorkoutSet({
    this.weight,
    this.reps,
    this.duration,
    this.distance,
    this.rpe,
  });

  final num? weight;
  final int? reps;
  final Duration? duration;
  final num? distance;
  final num? rpe;

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: _parseNum(map['weight'] ?? map['kg'] ?? map['peso']),
      reps: _parseInt(map['reps'] ?? map['repeticoes']),
      duration: _parseDuration(map['duration'] ?? map['tempo']),
      distance: _parseNum(map['distance'] ?? map['distancia']),
      rpe: _parseNum(map['rpe']),
    );
  }

  static num? _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Duration? _parseDuration(dynamic value) {
    if (value is Duration) return value;
    if (value is int) return Duration(seconds: value);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return Duration(seconds: parsed);
      }
      final segments = value.split(':');
      if (segments.length == 3) {
        final hours = int.tryParse(segments[0]) ?? 0;
        final minutes = int.tryParse(segments[1]) ?? 0;
        final seconds = int.tryParse(segments[2]) ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }
    return null;
  }
}
