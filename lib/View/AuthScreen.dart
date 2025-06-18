import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'HomeScreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationCodeController = TextEditingController();

  bool _isSignUpMode = true;
  String? _message; // Para mostrar mensajes de éxito/error

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() { _message = null; });
    try {
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(), // Usamos email como username
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
          },
        ),
      );
      if (result.isSignUpComplete) {
        setState(() {
          _message = 'Registro exitoso. Puedes iniciar sesión.';
          _isSignUpMode = false; // Cambiar a modo login si el registro es directo
        });
      } else {
        // En Cognito, a menudo se requiere confirmación por email
        setState(() {
          _message = 'Registro exitoso. Se envió un código de confirmación a tu email.';
          // Aquí puedes mostrar la UI para ingresar el código de confirmación
        });
        _showConfirmationDialog(context);
      }
    } on AuthException catch (e) {
      setState(() { _message = 'Error al registrar: ${e.message}'; });
    }
  }

  Future<void> _confirmSignUp(BuildContext context) async {
    setState(() { _message = null; });
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _confirmationCodeController.text.trim(),
      );
      if (result.isSignUpComplete) {
        setState(() {
          _message = 'Cuenta confirmada. Ahora puedes iniciar sesión.';
          _isSignUpMode = false; // Cambiar a modo login
        });
        Navigator.of(context).pop(); // Cerrar el diálogo de confirmación
      }
    } on AuthException catch (e) {
      setState(() { _message = 'Error al confirmar: ${e.message}'; });
    }
  }

  Future<void> _signIn() async {
    setState(() { _message = null; });
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (result.isSignedIn) {
        setState(() { _message = 'Inicio de sesión exitoso.'; });
        // Aquí podrías navegar a la pantalla principal de tu aplicación
        safePrint('Usuario logueado: ${result.isSignedIn}');
        Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(), // Reemplaza HomeScreen() con tu pantalla principal
        ),
        );
      } else {
         setState(() { _message = 'Inicio de sesión fallido. Verifica tus credenciales.'; });
      }
    } on AuthException catch (e) {
      setState(() { _message = 'Error al iniciar sesión: ${e.message}'; });
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Registro'),
          content: TextField(
            controller: _confirmationCodeController,
            decoration: const InputDecoration(labelText: 'Código de Confirmación'),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                _confirmSignUp(dialogContext); // Pasar dialogContext
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUpMode ? 'Registrarse' : 'Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSignUpMode ? _signUp : _signIn,
              child: Text(_isSignUpMode ? 'Registrarse' : 'Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUpMode = !_isSignUpMode;
                  _message = null;
                });
              },
              child: Text(_isSignUpMode
                  ? '¿Ya tienes una cuenta? Iniciar Sesión'
                  : '¿No tienes una cuenta? Registrarse'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_message!,
                    style: TextStyle(
                        color: _message!.contains('Error') ? Colors.red : Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}