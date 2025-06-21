// AuthScreen.dart
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
  bool _isSignIn = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      safePrint('Sign In Result: ${result.nextStep.signInStep}');
      if (!mounted) return;
      if (result.isSignedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.message}', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFEF233C), // Fondo rojo para el Snackbar de error
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: _emailController.text.trim(),
      };
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        options: SignUpOptions(userAttributes: userAttributes),
      );
      safePrint('Sign Up Result: ${result.nextStep.signUpStep}');
      if (!mounted) return;
      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. ¡Confirma tu correo electrónico!', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF28A745), // Verde para éxito
          ),
        );
        // Aquí podrías redirigir a una pantalla para que el usuario ingrese el código de confirmación
      }
    } on AuthException catch (e) {
      safePrint('Error signing up: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrarse: ${e.message}', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFEF233C), // Fondo rojo para el Snackbar de error
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fondo principal negro suave
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignIn ? 'Iniciar Sesión' : 'Registro',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Texto blanco
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isSignIn ? '¡Bienvenido de nuevo a Notas Divertidas!' : '¡Únete a Notas Divertidas!',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFCCCCCC), // Gris claro para texto secundario
                  fontFamily: 'Open Sans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Campo de Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontFamily: 'Open Sans'),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color(0xFFCCCCCC)), // Gris claro para etiqueta
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333), // Gris oscuro para fondo del campo
                  prefixIcon: const Icon(Icons.email, color: Color(0xFFCCCCCC)), // Gris claro para icono
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2), // Rojo de acento al enfocar
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Open Sans'),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333), // Gris oscuro para fondo del campo
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFCCCCCC)), // Gris claro para icono
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2), // Rojo de acento al enfocar
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botón de acción (Iniciar Sesión / Registrarse)
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFFF3B30)) // Rojo de acento para el spinner
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSignIn ? _signIn : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30), // Rojo de acento para el botón
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _isSignIn ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto blanco
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              // Botón para cambiar entre Iniciar Sesión y Registrarse
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignIn = !_isSignIn;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _isSignIn
                      ? '¿No tienes una cuenta? Regístrate'
                      : '¿Ya tienes una cuenta? Inicia Sesión',
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC), // Gris claro para el texto del botón
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}