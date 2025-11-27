// lib/application/notifications/notification_service.dart - COM POPUP LOCAL

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import novo

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Plugin de Notificações Locais
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // --- INICIALIZAÇÃO (CHAMAR NO MAIN) ---
  Future<void> initialize() async {
    // Configuração para Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Usa o ícone do app

    // Configuração para iOS (Simples)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Pede permissão no Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- MOSTRAR POPUP (HEADS-UP) ---
  Future<void> showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id_appfit',
      'Notificações AppFit',
      importance: Importance.max, // Importante para fazer o popup aparecer
      priority: Priority.high,    // Importante para fazer o popup aparecer
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond, // ID único baseado no tempo
      title,
      body,
      details,
    );
  }

  // --- MÉTODOS DO FIRESTORE (MANTIDOS) ---

  Future<void> sendNotification({
    required String targetUserId,
    required String type,
    required String message,
    String? postId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == targetUserId) return;

    try {
      final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final senderData = senderDoc.data() ?? {};
      final String senderName = senderData['displayName'] ?? 'Alguém';
      final String? senderPhotoUrl = senderData['photoUrl'];

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': type,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'message': message,
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print("Erro ao enviar notificação: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unreadDocs = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}