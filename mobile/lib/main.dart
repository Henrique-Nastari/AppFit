// main.dart - CORRIGIDO (com AuthGate restaurado)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'presentation/screens/auth/login_page.dart';
import 'presentation/screens/auth/register_page.dart';
import 'presentation/screens/feed/feed_page.dart';
import 'presentation/screens/feed/create_post_page.dart';
import 'presentation/screens/profile/profile_page.dart';
import 'presentation/screens/workouts/workouts_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR', null);
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

          // Temas (claro e escuro)
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
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
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
            // CORREÇÃO: Removendo 'const' se alguma página não for const
            // Mas, idealmente, todas deveriam ser const.
            // O erro "isn't a const constructor" sumirá ao corrigir o AuthGate.
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

// CORREÇÃO: Implementação completa do AuthGate restaurada
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
        if (snapshot.hasData) {
          return const FeedPage();
        }
        return const LoginPage();
      },
    );
  }
}