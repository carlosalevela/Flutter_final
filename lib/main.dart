import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection_container.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/history/history_bloc.dart'; // 👈 AGREGAR ESTE IMPORT
import 'presentation/bloc/skin_analysis_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main_page.dart'; // 👈 CAMBIAR A MAIN_PAGE

// 👇 NUEVOS IMPORTS (únicos cambios de importación)
import 'presentation/pages/info_page.dart';
import 'presentation/pages/history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias
  await InjectionContainer.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider.value(
          value: InjectionContainer.authBloc,
        ),
        // Skin Analysis BLoC
        BlocProvider.value(
          value: InjectionContainer.skinAnalysisBloc,
        ),
        // History BLoC 👈 AGREGAR ESTE
        BlocProvider.value(
          value: InjectionContainer.historyBloc,
        ),
      ],
      child: MaterialApp(
        title: 'SkinCheck AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Wrapper para verificar el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificar estado de autenticación al iniciar
    context.read<AuthBloc>().add(CheckAuthStatusEvent());

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Mostrar loading mientras verifica
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.teal,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'SkinCheck AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        // Si está autenticado, ir a InfoPage (home) con callbacks
        else if (state is Authenticated) {
          return InfoPage(
            onAnalyze: () {
              // Navega a tu flujo de análisis (usa MainPage si ahí está la cámara/analizador)
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MainPage()),
              );
            },
            onHistory: () {
              // Navega al historial
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          );
        }
        // Si no está autenticado, ir a LoginPage
        else {
          return const LoginPage();
        }
      },
    );
  }
}
