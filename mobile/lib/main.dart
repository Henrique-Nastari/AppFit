// lib/main.dart - VERSÃO FINAL

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// Imports de Telas e Serviços
import 'presentation/screens/auth/login_page.dart';
import 'presentation/screens/auth/register_page.dart';
import 'presentation/screens/feed/feed_page.dart';
import 'presentation/screens/feed/create_post_page.dart';
import 'presentation/screens/profile/profile_page.dart';
import 'presentation/screens/workouts/workouts_page.dart';
import 'application/notifications/notification_service.dart'; // Import do Serviço

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Inicializa o serviço de notificações (Permissões, Canais Android)
  await NotificationService().initialize();

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

          // --- TEMA CLARO ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              surfaceTintColor: Colors.transparent,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.light,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardThemeData(
              elevation: 0.5,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
            useMaterial3: true,
          ),

          // --- TEMA ESCURO (Visual Stitch) ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black, // Ou Color(0xFF102218) se quiser forçar o verde em tudo
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.dark,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              elevation: 0.5,
              color: Colors.grey[900],
              surfaceTintColor: Colors.transparent,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,

          home: const AuthGate(),
          routes: {
            '/home': (context) => const FeedPage(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/create-post': (context) => const CreatePostPage(),
            '/workouts': (context) => const WorkoutsPage(),
            '/profile': (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Estado de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuário Logado
        if (snapshot.hasData) {
          // CORREÇÃO CRÍTICA: Usamos o UID como key para forçar a reconstrução
          // completa da árvore de widgets quando a conta muda.
          return FeedPage(key: ValueKey(snapshot.data!.uid));
        }

        // Usuário Deslogado
        return const LoginPage();
      },
    );
  }
}