import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- PARTE 1: O "CÉREBRO" (Sua lógica original, 100% preservada) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _loading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Seu método _signIn robusto, com a correção de navegação já aplicada
  Future<void> _signIn() async {
    // Esconder o teclado para uma melhor experiência do usuário
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Opcional: a snackbar pode ser removida se a transição de tela for rápida
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Login realizado com sucesso!')),
      // );
      // A navegação foi REMOVIDA daqui, pois o AuthGate cuida disso.
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      switch (e.code) {
        case 'invalid-email':
          message = 'O formato do e-mail é inválido.';
          break;
        case 'user-not-found':
          message = 'Nenhum usuário encontrado para este e-mail.';
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

  // --- PARTE 2: O "ROSTO" (Seu novo design, agora conectado ao cérebro) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(width: 96.w, height: 100.h),
            Center(
              // Lembrete: Adicione 'images/logo.png' nos assets do seu pubspec.yaml
              child: Image.asset('images/logo.png'),
            ),
            SizedBox(height: 120.h),
            // CONEXÃO: Widgets de UI agora usam os controllers e focus nodes do "cérebro"
            Textfild(_emailController, _emailFocus, 'Email', Icons.email),
            SizedBox(height: 15.h),
            Textfild(_passwordController, _passwordFocus, 'Password', Icons.lock),
            SizedBox(height: 15.h),
            forget(),
            SizedBox(height: 15.h),
            login(),
            SizedBox(height: 15.h),
            Have()
          ],
        ),
      ),
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Não tem uma conta?  ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            // CONEXÃO: Usando o sistema de rotas que você já tem e desabilitando durante o loading
            onTap: _loading
                ? null
                : () => Navigator.pushNamed(context, '/register'),
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
        // CONEXÃO: Chamando o método _signIn e desabilitando o toque durante o loading
        onTap: _loading ? null : _signIn,
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.r),
          ),
          // CONEXÃO: Mostrando o indicador de progresso quando _loading for true
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

  Widget forget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              // Lógica para 'Esqueci a senha' pode ser adicionada aqui no futuro
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
        obscureText: typename == 'Password', // Esconde a senha
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