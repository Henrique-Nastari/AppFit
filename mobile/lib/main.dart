// main.dart - VERSÃO FINAL CORRIGIDA

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'firebase_options.dart';

// Imports atualizados para a nova estrutura
import 'presentation/screens/auth/login_page.dart';
import 'presentation/screens/auth/register_page.dart';
import 'application/auth/auth_service.dart';
import 'presentation/screens/feed/feed_page.dart'; // <-- IMPORT ADICIONADO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppFit());
}

class AppFit extends StatelessWidget {
  const AppFit({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), 
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'AppFit',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthGate(), // AuthGate controla a tela inicial
          routes: {
             // Rota '/home' agora também aponta para FeedPage
            '/home': (context) => const FeedPage(), 
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
          },
        );
      },
    );
  }
}

// AuthGate CORRIGIDO para mostrar FeedPage
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // CORREÇÃO APLICADA AQUI: Retorna FeedPage se logado
        if (snapshot.hasData) {
          return const FeedPage(); 
        }
        // Retorna LoginPage se não logado (continua igual)
        return const LoginPage();
      },
    );
  }
}

// A DEFINIÇÃO ANTIGA DA HomePage FOI COMPLETAMENTE REMOVIDA DESTE ARQUIVO.