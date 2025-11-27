// lib/presentation/screens/auth/login_page.dart - CORRIGIDO (Sem tela preta)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _obscureText = true;
  final AuthService _authService = AuthService();

  // Cores do Design Stitch
  final Color _primaryColor = const Color(0xFF13EC6D);
  final Color _backgroundColor = const Color(0xFF102218);
  final Color _inputFillColor = const Color(0xFF0D1610).withValues(alpha: 0.5);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // --- CORREÇÃO DA TELA PRETA ---
      // Só fecha a tela se ela foi empilhada (veio do cadastro, etc).
      // Se for a tela raiz (do AuthGate), não faz nada, o AuthGate troca pro Feed sozinho.
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      // ------------------------------

    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      switch (e.code) {
        case 'invalid-email': message = 'E-mail inválido.'; break;
        case 'user-not-found':
        case 'invalid-credential': message = 'Credenciais inválidas.'; break;
        case 'wrong-password': message = 'Senha incorreta.'; break;
        case 'user-disabled': message = 'Usuário desabilitado.'; break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;

      // --- CORREÇÃO DA TELA PRETA ---
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      // ------------------------------

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no Google: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Imagem de Fundo
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: _backgroundColor),
            ),
          ),
          // Overlay Escuro
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: _primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Bem-vindo de volta',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.epilogue(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continue sua jornada',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.epilogue(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildLabel("E-mail"),
                    _buildInput(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hintText: "Digite seu e-mail",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Senha"),
                    _buildInput(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hintText: "Digite sua senha",
                      isPassword: true,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () { /* TODO: Recuperar senha */ },
                        child: Text(
                          "Esqueceu sua senha?",
                          style: GoogleFonts.epilogue(
                            color: _primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _backgroundColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? CircularProgressIndicator(color: _backgroundColor)
                            : Text(
                          "Entrar",
                          style: GoogleFonts.epilogue(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[700])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("ou", style: TextStyle(color: Colors.grey[400])),
                        ),
                        Expanded(child: Divider(color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            label: "Google",
                            iconPath: 'images/google_logo.png',
                            onTap: _loading ? null : _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSocialButton(
                            label: "Facebook",
                            iconData: Icons.facebook,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Facebook em breve!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Não tem uma conta? ",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            "Cadastre-se",
                            style: GoogleFonts.epilogue(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.epilogue(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    IconData? icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscureText : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    String? iconPath,
    IconData? iconData,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              Image.asset(iconPath, height: 24)
            else if (iconData != null)
              Icon(iconData, color: Colors.blue, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.epilogue(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}