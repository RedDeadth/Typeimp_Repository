import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'amplifyconfiguration.dart'; // Asegúrate de que este archivo exista y esté configurado
import 'View/AuthScreen.dart'; // Asegúrate de que la ruta sea correcta
import 'View/HomeScreen.dart';   // Asegúrate de que la ruta sea correcta

// Mantenemos esta función, pero la llamaremos SÓLO UNA VEZ al inicio.
Future<void> _configureAmplify() async {
  // Solo configura si aún no está configurado
  if (!Amplify.isConfigured) {
    try {
      AmplifyAuthCognito auth = AmplifyAuthCognito();
      AmplifyAPI api = AmplifyAPI();
      await Amplify.addPlugins([auth, api]);

      // Configura Amplify usando el archivo generado
      await Amplify.configure(amplifyconfig);
      safePrint('Amplify configurado.');
    } on AmplifyException catch (e) {
      safePrint('Error al configurar Amplify: $e');
    }
  } else {
    safePrint('Amplify ya está configurado.');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAmplify(); // Llama a la configuración de Amplify aquí al inicio.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Ahora solo necesitamos un flag para saber si la verificación de auth terminó
  bool _isLoadingAuthStatus = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus(); // Solo verifica el estado de autenticación
  }

  Future<void> _checkAuthStatus() async {
    // Asegurarse de que Amplify esté configurado antes de intentar operaciones de autenticación.
    // Como _configureAmplify se llama en main(), aquí simplemente esperamos un momento
    // o asumimos que ya está listo.
    // Si la aplicación es compleja, podrías usar un Listener de Amplify.isConfigured
    // o un FutureBuilder en el widget tree.
    // Para este caso, como se llama en main() ANTES de runApp, debería estar listo.
    
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      safePrint('Auth session result: ${result.isSignedIn}');
      if (mounted) {
        setState(() {
          _isSignedIn = result.isSignedIn;
          _isLoadingAuthStatus = false;
        });
      }
    } on AuthException catch (e) {
      safePrint('Error fetching auth session: ${e.message}');
      if (mounted) {
        setState(() {
          _isSignedIn = false; // Asumir no autenticado si hay error
          _isLoadingAuthStatus = false;
        });
      }
    } catch (e) {
      // Captura cualquier otra excepción, por ejemplo, si Amplify no está completamente listo
      safePrint('Unexpected error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _isLoadingAuthStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuthStatus) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF3B30)), // Rojo de carga
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notas Brillantes',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF3B30),
          primary: const Color(0xFF1A1A1A),
          secondary: const Color(0xFFFF3B30),
          background: const Color(0xFF1A1A1A),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.black87,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
      ),
      home: _isSignedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}