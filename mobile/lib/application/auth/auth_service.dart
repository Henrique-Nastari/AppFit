// lib/application/auth/auth_service.dart - VERSÃO FINAL V6+ CORRETA

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Instancia o GoogleSignIn (sintaxe V6+)
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Usa a instância .signIn() (sintaxe V6+)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Usuário cancelou
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        // accessToken e idToken estão corretos (sintaxe V6+)
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocument(
          user: user,
          displayName: user.displayName,
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (_) { // Remove o aviso de "e" não usado
      throw Exception('Ocorreu um erro no login com Google.');
    }
  }

  Future<User?> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;

    if (user != null) {
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      await _createUserDocument(
        user: user,
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : user.displayName,
      );
    }
    return user;
  }

  Future<void> _createUserDocument({required User user, String? displayName}) async {
    final userRef = _users.doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      final finalDisplayName = displayName ??
          user.displayName ??
          user.email?.split('@').first ??
          'Novo Usuário';

      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': finalDisplayName,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'bio': null,
        'followersCount': 0,
        'followingCount': 0,
      });
    }
  }

  Future<void> signOut() async {
    // Usa a instância .signOut() (sintaxe V6+)
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- Métodos restantes ---
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // (Restante dos métodos ...deleteAccount, etc... )
  Future<void> updateUsername({required String displayName}) async { /* ... */ }
  Future<void> deleteAccount({String? email, String? password}) async { /* ... */ }
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async { /* ... */ }
}