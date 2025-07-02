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

  bool _isSignInMode = true; // true para Iniciar Sesión, false para Registro
  bool _isLoading = false;
  String? _message;
  bool _passwordVisible = false;
  // bool _needsConfirmation = false; // No es necesario un estado separado para esto, el diálogo lo maneja.

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
      // No mostramos un mensaje al usuario aquí, ya que es una verificación silenciosa.
    }
  }

  void _navigateToHome() {
    if (!mounted) return; // Asegurarse de que el widget sigue montado
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Manejo de mensajes para el usuario (usando SnackBar para consistencia)
  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFEF233C) : const Color(0xFF28A745),
      ),
    );
    if (isError) {
      safePrint('Error: $msg');
    } else {
      safePrint('Mensaje: $msg');
    }
  }

  // --- Método para Registro ---
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: _emailController.text.trim(),
      };
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(), // Usamos email como username
        password: _passwordController.text.trim(),
        options: SignUpOptions(userAttributes: userAttributes),
      );
      safePrint('Sign Up Result: ${result.nextStep.signUpStep}');
      if (!mounted) return;

      if (result.isSignUpComplete) {
        _showMessage('¡Registro exitoso! Ya puedes iniciar sesión.', isError: false);
        setState(() {
          _isSignInMode = true; // Cambiar a modo de inicio de sesión
        });
      } else if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        _showMessage('¡Registro exitoso! Se envió un código de confirmación a tu correo.', isError: false);
        _showConfirmationDialog(context); // Mostrar diálogo de confirmación
      }
    } on AuthException catch (e) {
      _showMessage('Error al registrar: ${e.message}', isError: true);
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // --- Método para Confirmar Registro ---
  Future<void> _confirmSignUp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _confirmationCodeController.text.trim(),
      );
      if (result.isSignUpComplete) {
        if (!mounted) return;
        // Cerrar el diálogo si está abierto
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showMessage('¡Cuenta confirmada! Ahora puedes iniciar sesión.', isError: false);
        setState(() {
          _isSignInMode = true; // Cambiar a modo de inicio de sesión
        });
      } else {
        _showMessage('Error al confirmar: Verifica el código.', isError: true);
      }
    } on AuthException catch (e) {
      _showMessage('Error al confirmar: ${e.message}', isError: true);
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // --- Método para Iniciar Sesión (Email/Contraseña) ---
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      safePrint('Sign In Result: ${result.nextStep.signInStep}');
      if (!mounted) return;
      if (result.isSignedIn) {
        _showMessage('Inicio de sesión exitoso.', isError: false);
        _navigateToHome(); // Navega a la pantalla principal
      } else {
        _showMessage('Inicio de sesión fallido. Verifica tus credenciales.', isError: true);
      }
    } on AuthException catch (e) {
      _showMessage('Error al iniciar sesión: ${e.message}', isError: true);
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // --- Método para Iniciar Sesión con Google ---
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
            isPreferPrivateSession: false, // Puedes cambiar a true si prefieres sesiones privadas
          ),
        ),
      );

      if (result.isSignedIn) {
        // Verificar que el usuario esté realmente autenticado después del WebUI
        final authSession = await Amplify.Auth.fetchAuthSession();
        if (authSession.isSignedIn) {
          _showMessage('Inicio de sesión con Google exitoso.', isError: false);
          _navigateToHome();
        } else {
          _showMessage('Error: Sesión no válida después del login con Google.', isError: true);
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
        errorMessage = 'Inicio de sesión con Google cancelado por el usuario.';
      } else if (e.message.contains('network')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.message.contains('InvalidParameter')) {
        errorMessage = 'Error de configuración de Google. Contacta al administrador.';
      }

      _showMessage(errorMessage, isError: true);
      safePrint('AuthException details: ${e.toString()}');
    } catch (e) {
      _showMessage('Error inesperado: ${e.toString()}', isError: true);
      safePrint('Unexpected error: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // --- Diálogo para ingresar el código de confirmación ---
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirma tu Registro', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Se envió un código de confirmación a tu correo electrónico. Por favor, ingrésalo aquí para activar tu cuenta.', style: TextStyle(color: Color(0xFF333333))),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmationCodeController,
                  decoration: InputDecoration(
                    labelText: 'Código de Confirmación',
                    hintText: 'Ej. 123456',
                    prefixIcon: const Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _confirmSignUp(), // Permite confirmar con Enter
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF333333))),
              onPressed: () {
                if (!mounted) return;
                Navigator.of(dialogContext).pop(); // Cierra el diálogo sin confirmar
                _showMessage('Confirmación de registro cancelada.', isError: true); // Usar _showMessage para notificar
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
              onPressed: () => _confirmSignUp(),
              child: _isLoading // Usar el _isLoading principal
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
              // --- IMAGEN DEL APK AQUÍ ---
              Image.asset(
                'assets/app_icon.jpeg', // Ruta de tu imagen
                height: 120, // Ajusta el tamaño como desees
                width: 120, // Ajusta el tamaño como desees
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.note, size: 120, color: Colors.white70), // Fallback
              ),
              const SizedBox(height: 20),

              Text(
                _isSignInMode ? 'Iniciar Sesión' : 'Registro',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isSignInMode ? '¡Bienvenido de nuevo a Notas Divertidas!' : '¡Únete a Notas Divertidas!',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFCCCCCC),
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
                  labelStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFFCCCCCC)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                style: const TextStyle(color: Colors.white, fontFamily: 'Open Sans'),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFCCCCCC)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFFCCCCCC),
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botón de acción (Iniciar Sesión / Registrarse)
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFFF3B30))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSignInMode ? _signIn : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _isSignInMode ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                    _isSignInMode = !_isSignInMode;
                    _emailController.clear();
                    _passwordController.clear();
                    _message = null; // Limpiar mensaje al cambiar modo
                    _passwordVisible = false; // Resetear visibilidad al cambiar de modo
                  });
                },
                child: Text(
                  _isSignInMode
                      ? '¿No tienes una cuenta? Regístrate'
                      : '¿Ya tienes una cuenta? Inicia Sesión',
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
              const SizedBox(height: 20), // Espacio antes del botón de Google
              // Botón de inicio de sesión con Google
              _isLoading
                  ? const SizedBox.shrink() // Ocultar si está cargando
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.network(
                          'https://img.icons8.com/color/48/000000/google-logo.png', // Icono de Google
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue), // Fallback
                        ),
                        label: const Text(
                          'Iniciar sesión con Google',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333), // Color de texto para el botón de Google
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF333333), // Color del texto y el icono
                          backgroundColor: Colors.white, // Fondo blanco para el botón de Google
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey), // Borde gris claro
                          ),
                          elevation: 5,
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