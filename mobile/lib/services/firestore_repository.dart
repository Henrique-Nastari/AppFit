import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/post.dart';

class FirestoreRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Workouts
  CollectionReference<Map<String, dynamic>> get _workouts => _db.collection('workouts');

  Future<String> createWorkout(Workout workout) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    final doc = await _workouts.add(workout.toMap()..['ownerId'] = uid);
    return doc.id;
  }

  Stream<List<Workout>> listWorkouts({String? ownerId, int limit = 20}) {
    Query<Map<String, dynamic>> q = _workouts.orderBy('createdAt', descending: true).limit(limit);
    if (ownerId != null) {
      q = q.where('ownerId', isEqualTo: ownerId);
    }
    return q.snapshots().map((s) => s.docs.map(Workout.fromDoc).toList());
  }

  Future<Workout?> getWorkout(String id) async {
    final doc = await _workouts.doc(id).get();
    if (!doc.exists) return null;
    return Workout.fromDoc(doc);
  }

  Future<void> updateWorkout(String id, Workout workout) async {
    await _workouts.doc(id).update(workout.toMap());
  }

  Future<void> deleteWorkout(String id) async {
    await _workouts.doc(id).delete();
  }

  // Posts
  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  Future<String> createPost(Post post) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final doc = await _posts.add(post.toMap()
      ..['ownerId'] = user.uid
      ..['ownerEmail'] = user.email ?? '');
    return doc.id;
  }

  Stream<List<Post>> feed({int limit = 50}) {
    return _posts
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Post.fromDoc).toList());
  }

  Future<void> likePost(String id) async {
    await _posts.doc(id).update({'likeCount': FieldValue.increment(1)});
  }

  Future<void> attachWorkoutToPost(String postId, String workoutId) async {
    await _posts.doc(postId).update({'workoutId': workoutId});
  }
}