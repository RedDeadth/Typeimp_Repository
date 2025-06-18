import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart'; 
import 'View/AuthScreen.dart';
import 'package:amplify_api/amplify_api.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAmplify(); // Llama a la función de configuración
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    // 1. Crear e importar los plugins necesarios
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();
    await Amplify.addPlugin(auth);
    await Amplify.addPlugin(api);
    

    await Amplify.configure(amplifyconfig); // <-- 'amplifyconfig' es la variable en ese archivo
    safePrint('Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify was already configured.'); // Esto es para evitar errores en hot reload
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(), // Crearemos esta pantalla de autenticación
    );
  }
}