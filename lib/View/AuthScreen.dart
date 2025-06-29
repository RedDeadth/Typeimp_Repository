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
  final TextEditingController _confirmationCodeController = TextEditingController(); // Para la confirmación

  bool _isSignUpMode = true; // Para alternar entre Sign Up y Sign In
  String? _message; // Para mostrar mensajes de éxito/error
  bool _isLoading = false; // Nuevo estado para controlar el CircularProgressIndicator
  bool _needsConfirmation = false; // Nuevo estado para controlar la UI de confirmación

  @override
  void initState() {
    super.initState();
    _checkCurrentUser(); // Verifica si ya hay un usuario autenticado al iniciar
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  // Verifica si ya hay un usuario autenticado al iniciar la pantalla
  Future<void> _checkCurrentUser() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      if (result.isSignedIn) {
        _navigateToHome(); // Navega a HomeScreen si ya hay una sesión activa
      }
    } on AuthException catch (e) {
      safePrint('Error al verificar sesión al inicio: ${e.message}');
    } finally {
      // Si _isLoading es true al inicio (debido a _initializeAppAndFetchData en HomeScreen
      // que se llama después de la navegación), no lo desactives aquí inmediatamente.
      // Este finally es más para asegurar que si hay una pantalla de carga previa a AuthScreen, se desactive.
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Manejo de mensajes para el usuario
  void _showMessage(String msg, {bool isError = false}) {
    setState(() {
      _message = msg;
      _isLoading = false;
      // No modificamos _needsConfirmation aquí, ya se maneja en _signUp
    });
    if (isError) {
      safePrint('Error: $msg');
    } else {
      safePrint('Mensaje: $msg');
    }
  }

  // --- Métodos de autenticación estándar (email/contraseña) ---

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _needsConfirmation = false;
    });
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: _emailController.text.trim(),
      };
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(), // Usamos email como username
        password: _passwordController.text,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      if (result.isSignUpComplete) {
        _showMessage('Registro exitoso. Puedes iniciar sesión.', isError: false);
        setState(() {
          _isSignUpMode = false; // Cambiar a modo de inicio de sesión
        });
      } else {
        // Si se requiere confirmación (común en Cognito)
        _showMessage('Registro exitoso. Se envió un código de confirmación a tu email.', isError: false);
        setState(() {
          _needsConfirmation = true; // Mostrar UI para ingresar código
        });
        _showConfirmationDialog(context); // Mostrar diálogo de confirmación
      }
    } on AuthException catch (e) {
      _showMessage('Error al registrar: ${e.message}', isError: true);
    }
  }

  Future<void> _confirmSignUp(BuildContext context) async {
    setState(() { _isLoading = true; _message = null; });
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _confirmationCodeController.text.trim(),
      );
      if (result.isSignUpComplete) {
        _showMessage('Cuenta confirmada. Ahora puedes iniciar sesión.', isError: false);
        setState(() {
          _isSignUpMode = false; // Cambiar a modo login
          _needsConfirmation = false; // Ocultar UI de confirmación
        });
        if (Navigator.of(context).canPop()) { // Solo hacer pop si el diálogo está abierto
          Navigator.of(context).pop(); // Cerrar el diálogo de confirmación
        }
      }
    } on AuthException catch (e) {
      _showMessage('Error al confirmar: ${e.message}', isError: true);
    }
  }

  Future<void> _signIn() async {
    setState(() { _isLoading = true; _message = null; });
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (result.isSignedIn) {
        _showMessage('Inicio de sesión exitoso.', isError: false);
        _navigateToHome(); // Navega a la pantalla principal
      } else {
         _showMessage('Inicio de sesión fallido. Verifica tus credenciales.', isError: true);
      }
    } on AuthException catch (e) {
      _showMessage('Error al iniciar sesión: ${e.message}', isError: true);
    }
  }

  // Método mejorado de inicio de sesión con Google
  Future<void> _signInWithGoogle() async {
    setState(() { 
      _isLoading = true; 
      _message = null; 
    });
    
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
        options: const SignInWithWebUIOptions(
          pluginOptions: CognitoSignInWithWebUIPluginOptions(
            isPreferPrivateSession: false,
          ),
        ),
      );
      
      if (result.isSignedIn) {
        // Verificar que el usuario esté realmente autenticado
        final authSession = await Amplify.Auth.fetchAuthSession();
        if (authSession.isSignedIn) {
          _showMessage('Inicio de sesión con Google exitoso.', isError: false);
          _navigateToHome();
        } else {
          _showMessage('Error: Sesión no válida después del login.', isError: true);
        }
      } else {
        _showMessage('Inicio de sesión con Google incompleto.', isError: true);
      }
    } on AuthException catch (e) {
      String errorMessage = 'Error al iniciar sesión con Google: ${e.message}';
      
      // Manejo específico de errores comunes
      if (e.message.contains('UserCancel') || 
          e.message.contains('cancelled') || 
          e.message.contains('browser closed')) {
        errorMessage = 'Inicio de sesión cancelado por el usuario.';
      } else if (e.message.contains('network')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.message.contains('InvalidParameter')) {
        errorMessage = 'Error de configuración. Contacta al administrador.';
      }
      
      _showMessage(errorMessage, isError: true);
      safePrint('AuthException details: ${e.toString()}');
    } catch (e) {
      _showMessage('Error inesperado: ${e.toString()}', isError: true);
      safePrint('Unexpected error: ${e.toString()}');
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe confirmar o cancelar explícitamente
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Registro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Se envió un código a tu email. Ingrésalo a continuación:'),
              TextField(
                controller: _confirmationCodeController,
                decoration: const InputDecoration(labelText: 'Código de Confirmación'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                _confirmSignUp(dialogContext); // Pasar dialogContext
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                setState(() {
                  _needsConfirmation = false;
                  _isLoading = false;
                });
                Navigator.of(dialogContext).pop();
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
      body: Center(
        child: SingleChildScrollView(
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
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('Error') ? Colors.red : Colors.green
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isSignUpMode ? _signUp : _signIn,
                      child: Text(_isSignUpMode ? 'Registrarse' : 'Iniciar Sesión'),
                    ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode;
                    _message = null;
                    _needsConfirmation = false; // Ocultar confirmación al cambiar de modo
                  });
                },
                child: Text(_isSignUpMode
                    ? '¿Ya tienes una cuenta? Iniciar Sesión'
                    : '¿No tienes una cuenta? Registrarse'),
              ),
              const SizedBox(height: 20),
              // Botón de inicio de sesión con Google
              _isLoading
                  ? const SizedBox.shrink() // Ocultar si está cargando
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.network(
                        'https://img.icons8.com/color/48/000000/google-logo.png', // Icono de Google
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata), // Fallback
                      ),
                      label: const Text('Iniciar sesión con Google'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, 
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
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