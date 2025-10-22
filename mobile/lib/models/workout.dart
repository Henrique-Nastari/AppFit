import 'package:cloud_firestore/cloud_firestore.dart';

class SetEntry {
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final int? restSeconds;

  const SetEntry({this.reps, this.weightKg, this.durationSeconds, this.restSeconds});

  Map<String, dynamic> toMap() => {
        if (reps != null) 'reps': reps,
        if (weightKg != null) 'weightKg': weightKg,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (restSeconds != null) 'restSeconds': restSeconds,
      };

  factory SetEntry.fromMap(Map<String, dynamic> map) => SetEntry(
        reps: (map['reps'] as num?)?.toInt(),
        weightKg: (map['weightKg'] as num?)?.toDouble(),
        durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
        restSeconds: (map['restSeconds'] as num?)?.toInt(),
      );
}

class Exercise {
  final String name;
  final String? notes;
  final List<SetEntry> sets;

  const Exercise({required this.name, this.notes, this.sets = const []});

  Map<String, dynamic> toMap() => {
        'name': name,
        if (notes != null) 'notes': notes,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        name: map['name'] as String? ?? '',
        notes: map['notes'] as String?,
        sets: (map['sets'] as List<dynamic>? ?? [])
            .map((e) => SetEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class Workout {
  final String? id;
  final String ownerId;
  final String title;
  final String? notes;
  final List<Exercise> exercises;
  final List<String> tags;
  final String visibility; // 'public' | 'private'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? durationMinutes;

  const Workout({
    this.id,
    required this.ownerId,
    required this.title,
    this.notes,
    this.exercises = const [],
    this.tags = const [],
    this.visibility = 'public',
    this.createdAt,
    this.updatedAt,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        if (notes != null) 'notes': notes,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'tags': tags,
        'visibility': visibility,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Workout.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    Timestamp? createdTs = data['createdAt'] as Timestamp?;
    Timestamp? updatedTs = data['updatedAt'] as Timestamp?;
    return Workout(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      notes: data['notes'] as String?,
      exercises: (data['exercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tags: (data['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      visibility: data['visibility'] as String? ?? 'public',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      createdAt: createdTs?.toDate(),
      updatedAt: updatedTs?.toDate(),
    );
  }

  Map<String, dynamic> summary() {
    final exerciseCount = exercises.length;
    final totalSets = exercises.fold<int>(0, (acc, e) => acc + e.sets.length);
    return {
      'title': title,
      'exerciseCount': exerciseCount,
      'totalSets': totalSets,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'tags': tags,
    };
  }
}