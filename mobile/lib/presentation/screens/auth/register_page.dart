// lib/presentation/screens/auth/register_page.dart - DESIGN STITCH

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart'; // Fonte Epilogue
import '../../../application/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- PARTE 1: A LÓGICA (100% INTACTA) ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  // Cores do Design Stitch
  final Color _primaryColor = const Color(0xFF13EC6D); // Verde Neon
  final Color _backgroundColor = const Color(0xFF102218); // Verde Escuro Fundo
  final Color _inputFillColor = const Color(0xFF152E1F); // Fundo dos inputs
  final Color _textColor = Colors.white;
  final Color _subTextColor = const Color(0xFF94A3B8); // Slate-400

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await _authService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );
      Navigator.of(context).pop();

    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao registrar';
      switch (e.code) {
        case 'email-already-in-use': message = 'Este e-mail já está em uso.'; break;
        case 'invalid-email': message = 'O formato do e-mail é inválido.'; break;
        case 'weak-password': message = 'A senha é muito fraca.'; break;
        default: message = e.message ?? 'Ocorreu um erro desconhecido.';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Google realizado com sucesso!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- PARTE 2: O NOVO DESIGN (STITCH) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Text(
                    "Junte-se à Comunidade",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.epilogue(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Comece sua jornada fitness conosco.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.epilogue(
                      fontSize: 16.sp,
                      color: _subTextColor,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Foto de Perfil (Visual apenas por enquanto, pois o cadastro logicamente não envia foto ainda)
                  Stack(
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: _inputFillColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade700, width: 2, style: BorderStyle.solid), // Dashed é difícil nativamente, solid fica bom
                        ),
                        child: Icon(Icons.person, size: 60.sp, color: Colors.grey.shade500),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        left: 0,
                        top: 0,
                        child: Center(
                          child: Icon(Icons.add_a_photo, color: Colors.white.withOpacity(0.8), size: 30.sp),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 30.h),

                  // Campos do Formulário
                  _buildLabel("Nome Completo"),
                  _buildStitchInput(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _emailFocus,
                    hintText: "Digite seu nome",
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe seu nome' : null,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("E-mail"),
                  _buildStitchInput(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    hintText: "seuemail@exemplo.com",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe o e-mail';
                      if (!value.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Criar Senha"),
                  _buildStitchInput(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocus: _confirmFocus,
                    hintText: "Mínimo 6 caracteres",
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (value) => (value != null && value.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  SizedBox(height: 16.h),

                  _buildLabel("Confirmar Senha"), // Adaptado do design original para manter lógica
                  _buildStitchInput(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hintText: "Repita a senha",
                    isPassword: true,
                    obscureText: _obscureConfirm,
                    onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) => (value != _passwordController.text) ? 'As senhas não coincidem' : null,
                    onFieldSubmitted: (_) => _register(),
                  ),
                  SizedBox(height: 24.h),

                  // Botão Cadastrar
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _backgroundColor, // Texto escuro
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: _backgroundColor, strokeWidth: 2))
                          : Text(
                        "Cadastrar",
                        style: GoogleFonts.epilogue(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Termos
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      "Ao se cadastrar, você concorda com nossos Termos de Serviço e Política de Privacidade.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _subTextColor, fontSize: 12.sp),
                    ),
                  ),

                  // Divisor
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text("OU", style: TextStyle(color: _subTextColor, fontSize: 12.sp)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Botão Google
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Image.asset('assets/images/google_logo.png', height: 20.h),
                      label: Text("Entrar com Google", style: GoogleFonts.epilogue(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Link Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Já possui uma conta? ", style: TextStyle(color: _subTextColor)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(), // Volta para o login
                        child: Text(
                          "Entrar",
                          style: GoogleFonts.epilogue(color: _primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildLabel(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.epilogue(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStitchInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: _primaryColor,
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (val) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else if (onFieldSubmitted != null) {
          onFieldSubmitted(val);
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: _inputFillColor,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade500,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
      ),
      validator: validator,
    );
  }
}