import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ADICIONADO: Import para o Google Sign-In

/// Serviço de autenticação (Clean Architecture)
/// Centraliza operações sobre FirebaseAuth, evitando chamadas diretas na UI.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Stream do estado de autenticação atual.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuário atual (pode ser null se não autenticado).
  User? get currentUser => _auth.currentUser;

  /// Login com e-mail e senha.
  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// NOVO: Login com Google.
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Iniciar o fluxo de login do Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // 2. Se o usuário cancelar o fluxo, retorna nulo
      if (googleUser == null) {
        return null;
      }

      // 3. Obter os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Criar uma credencial do Firebase usando os tokens do Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Fazer login no Firebase com essa credencial
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      // Repassa o erro do Firebase para a UI
      rethrow;
    } catch (e) {
      // Trata outros erros (ex: falta de internet)
      throw Exception('Ocorreu um erro no login com Google.');
    }
  }

  /// Criação de conta com e-mail e senha. Opcionalmente define displayName.
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

    if (user != null && displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }
    return user;
  }

  /// Logout do usuário atual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envia e-mail de redefinição de senha.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Atualiza o displayName do usuário atual.
  Future<void> updateUsername({required String displayName}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário autenticado para atualizar o nome.',
      );
    }
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  /// Exclui a conta do usuário atual.
  /// Se o backend exigir login recente, tente reautenticar com email+password quando fornecidos.
  Future<void> deleteAccount({String? email, String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário autenticado para excluir.',
      );
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && email != null && password != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        rethrow;
      }
    }
  }

  /// Redefine a senha a partir da senha atual (fluxo seguro exige reautenticação).
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário autenticado para alterar a senha.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}