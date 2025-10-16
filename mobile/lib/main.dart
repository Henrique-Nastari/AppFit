import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppFit());
}

class AppFit extends StatelessWidget {
  const AppFit({super.key});

  @override
  Widget build(BuildContext context) {
    // ADICIONADO: Wrapper para inicializar o ScreenUtil
    // Isso permite que você use .w, .h e .sp para tamanhos responsivos
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Tamanho base do design que você usou
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Seu MaterialApp original, agora dentro do builder do ScreenUtil
        return MaterialApp(
          title: 'AppFit',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          // Seu AuthGate continua sendo a porta de entrada, o que é perfeito.
          home: const AuthGate(),
          routes: {
            '/home': (context) => HomePage(),
            '/login': (context) =>  LoginPage(),
            '/register': (context) =>  RegisterPage(),
          },
        );
      },
    );
  }
}

// O AuthGate continua perfeito, não precisa de nenhuma mudança.
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
          return HomePage();
        }
        return LoginPage();
      },
    );
  }
}

// HomePage com as correções que já fizemos.
class HomePage extends StatelessWidget {
  HomePage({super.key});

  // CORRIGIDO: AuthService instanciado fora do método build.
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 AppFit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () {
              // CORRIGIDO: Apenas chama o signOut, o AuthGate cuida do resto.
              _authService.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Firebase inicializado com sucesso! Você está autenticado.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}