// lib/presentation/screens/auth/login_page.dart - CORRIGIDO (com Navegação)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../application/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _loading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Método para login com E-mail e Senha
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso!')),
      );

      // --- CORREÇÃO DE NAVEGAÇÃO ---
      // Fecha a página de login para revelar o AuthGate (que mostrará o Feed)
      Navigator.of(context).pop();
      // --- FIM DA CORREÇÃO ---

    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      switch (e.code) {
        case 'invalid-email':
          message = 'O formato do e-mail é inválido.';
          break;
        case 'user-not-found':
        case 'invalid-credential': // Nova versão do Firebase usa este código
          message = 'Usuário não encontrado ou senha incorreta.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta. Por favor, tente novamente.';
          break;
        case 'user-disabled':
          message = 'Este usuário foi desabilitado.';
          break;
        default:
          message = 'Verifique seu e-mail e senha.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Método para login com Google
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Google realizado com sucesso!')),
      );

      // --- CORREÇÃO DE NAVEGAÇÃO ---
      // Fecha a página de login para revelar o AuthGate (que mostrará o Feed)
      Navigator.of(context).pop();
      // --- FIM DA CORREÇÃO ---

    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Erro no login com Google.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ocorreu um erro: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  // --- PARTE 2: O "ROSTO" (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco para tema claro
      body: SafeArea(
        child: SingleChildScrollView( // Permite rolagem quando o teclado aparece
          child: Column(
            children: [
              SizedBox(width: 96.w, height: 100.h),
              Center(
                child: Image.asset('images/logo.png'),
              ),
              SizedBox(height: 120.h),
              Textfild(_emailController, _emailFocus, 'Email', Icons.email),
              SizedBox(height: 15.h),
              Textfild(_passwordController, _passwordFocus, 'Password', Icons.lock),
              SizedBox(height: 15.h),
              forget(),
              SizedBox(height: 15.h),
              login(),
              SizedBox(height: 20.h),
              _buildSocialLogins(),
              SizedBox(height: 15.h),
              Have(),
              SizedBox(height: 20.h), // Espaço extra no final
            ],
          ),
        ),
      ),
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centralizado
        children: [
          Text(
            "Não tem uma conta?  ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: _loading
                ? null
                : () => Navigator.pushNamed(context, '/register'), // Navega para a rota de registro
            child: Text(
              "Sign up ",
              style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget login() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: _loading ? null : _signIn,
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _loading
              ? const SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : Text(
            'Login',
            style: TextStyle(
              fontSize: 23.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogins() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: OutlinedButton.icon(
        icon: Image.asset('images/google_logo.png', height: 24.h),
        label: const Text(
          'Login com Google',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            minimumSize: Size(double.infinity, 44.h) // Ocupa largura total
        ),
        onPressed: _loading ? null : _signInWithGoogle,
      ),
    );
  }

  Widget forget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              // todo: Lógica para 'Esqueci a senha'
            },
            child: Text(
              'Esqueceu a senha?',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding Textfild(TextEditingController controll, FocusNode focusNode,
      String typename, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: TextField(
        style: TextStyle(fontSize: 18.sp, color: Colors.black),
        controller: controll,
        focusNode: focusNode,
        obscureText: typename == 'Password',
        decoration: InputDecoration(
          hintText: typename,
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
          ),
          contentPadding:
          EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              width: 2.w,
              color: Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              width: 2.w,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}