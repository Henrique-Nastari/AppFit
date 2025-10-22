// auth/register_page.dart - VERSÃO COMPLETA E CORRIGIDA (Bug do OutlinedButton)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../application/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- PARTE 1: O "CÉREBRO" (Sua lógica original + Google) ---
  final _formKey = GlobalKey<FormState>(); // Essencial para validação
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  
  // FocusNodes para uma melhor UX (pular para o próximo campo)
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  // Flag para UI do loading
  bool _signInWithGoogleInvoked = false;

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

  /// Método para cadastro com E-mail e Senha
  Future<void> _register() async {
    // Valida o formulário antes de continuar
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    FocusScope.of(context).unfocus(); // Esconder teclado
    setState(() { 
      _loading = true; 
      _signInWithGoogleInvoked = false; // Garante que o loading certo apareça
    });

    try {
      await _authService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      // O AuthGate cuidará do redirecionamento para a Home.
      
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao registrar';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este e-mail já está em uso.';
          break;
        case 'invalid-email':
          message = 'O formato do e-mail é inválido.';
          break;
        case 'weak-password':
          message = 'A senha é muito fraca.';
          break;
        default:
          message = e.message ?? 'Ocorreu um erro desconhecido.';
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

  /// Método para cadastro/login com Google
  Future<void> _signInWithGoogle() async {
    setState(() { 
      _loading = true; 
      _signInWithGoogleInvoked = true; // Garante que o loading certo apareça
    });
    try {
      await _authService.signInWithGoogle();
      // O AuthGate cuidará do redirecionamento.
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

  // --- PARTE 2: O "ROSTO" (Novo Design adaptado para Cadastro) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Form( // Usamos um Form para a validação
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 50.h),
                  Center(
                    child: Image.asset('images/logo.png'),
                  ),
                  SizedBox(height: 50.h),
                  Text(
                    'Crie sua conta no AppFit',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  
                  // Campo Nome
                  _buildTextFormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocusNode: _emailFocus,
                    hintText: 'Nome Completo',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe seu nome';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),
                  
                  // Campo Email
                  _buildTextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocusNode: _passwordFocus,
                    hintText: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe seu e-mail';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                         return 'Por favor, insira um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),

                  // Campo Senha
                  _buildTextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocusNode: _confirmFocus,
                    hintText: 'Senha',
                    icon: Icons.lock,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onObscureToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),

                  // Campo Confirmar Senha
                  _buildTextFormField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hintText: 'Confirmar Senha',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscureConfirm,
                    onObscureToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 25.h),

                  _buildRegisterButton(),
                  SizedBox(height: 20.h),
                  _buildSocialLogins(),
                  SizedBox(height: 15.h),
                  _buildLoginLink(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper para o botão de Criar Conta
  Widget _buildRegisterButton() {
    return InkWell(
      onTap: _loading ? null : _register, // Chama a validação e o cadastro
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: _loading && !_signInWithGoogleInvoked // Mostra loading só do botão de email
            ? const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                'Criar Conta',
                style: TextStyle(
                  fontSize: 23.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
  
  /// Helper para o botão de Login com Google
  Widget _buildSocialLogins() {
    // *** CORREÇÃO APLICADA AQUI ***
    // Trocado de OutlinedButton.icon para OutlinedButton
    // e construído o child manualmente.
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        // Define uma altura mínima para o botão não pular
        minimumSize: Size(double.infinity, 48.h) 
      ),
      onPressed: _loading ? null : _signInWithGoogle,
      child: _loading && _signInWithGoogleInvoked // Mostra loading só do botão do google
          ? const SizedBox(
              height: 24, // Tamanho consistente
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            )
          : Row( // Constrói o conteúdo manualmente
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/google_logo.png', height: 24.h),
                SizedBox(width: 10.w),
                Text(
                  'Cadastrar com Google',
                  style: TextStyle(
                    color: Colors.black, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp, // Tamanho de fonte consistente
                  ),
                ),
              ],
            ),
    );
  }

  /// Helper para o link "Já tem conta?"
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Já tem uma conta?  ",
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
        GestureDetector(
          onTap: _loading
              ? null
              : () => Navigator.pushReplacementNamed(context, '/login'), // Manda para o login
          child: Text(
            "Login ",
            style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Helper para criar os TextFormFields padronizados
  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onObscureToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: nextFocusNode != null 
          ? TextInputAction.next 
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          // Só tenta registrar se não estiver carregando
          if(!_loading) _register(); 
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onObscureToggle,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            width: 2.w,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            width: 2.w,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      validator: validator,
    );
  }
}