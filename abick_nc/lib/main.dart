import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'storage/secure_storage.dart';

void main() {
  runApp(const AbickNcApp());
}

class AbickNcApp extends StatelessWidget {
  const AbickNcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABICK NC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      locale: const Locale('es', 'CL'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('en', 'US'),
      ],
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper que verifica si hay una sesión activa
/// para decidir si mostrar el Login o el Home.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SecureStorage.hasSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final hasSession = snapshot.data ?? false;
          return hasSession ? const HomeScreen() : const LoginScreen();
        }

        // Mientras verifica, mostrar pantalla de carga
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
