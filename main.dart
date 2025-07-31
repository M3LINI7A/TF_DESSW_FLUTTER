import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Importa el archivo generado por FlutterFire

// El método `main` ahora usa el archivo de configuración `firebase_options.dart`
void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Opcional: para quitar la cinta de "Debug"
      title: 'App Final',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Clave global para identificar y validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar el texto de los campos
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable de estado para saber si estamos en modo login o registro
  bool _isLogin = true;
  // Variable para manejar el estado de carga
  bool _isLoading = false;

  // Método para manejar el envío del formulario
  void _submitForm() async {
    // Valida todos los campos del formulario
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return; // Si no es válido, no hace nada
    }

    // Si el formulario es válido, activa el estado de carga
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // --- MODO INICIO DE SESIÓN ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Si el login es exitoso, muestra un mensaje de bienvenida
        _showSuccessDialog("¡Bienvenido!", "Has iniciado sesión exitosamente.");
      } else {
        // --- MODO REGISTRO ---
        // 1. Mostrar los datos ingresados en un AlertDialog (Requisito 3.a)
        _showDataDialog();

        // 2. Registrar al usuario en Firebase
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de Firebase
      String message = 'Ocurrió un error.';
      if (e.code == 'user-not-found') {
        message = 'No se encontró un usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      } else if (e.code == 'email-already-in-use') {
        message = 'El correo electrónico ya está en uso.';
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog("Ocurrió un error inesperado.");
    }

    // Desactiva el estado de carga al finalizar
    setState(() {
      _isLoading = false;
    });
  }

  // Diálogo para mostrar los datos del formulario (Requisito 3.a)
  void _showDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos Ingresados'),
        content: Text(
          'Nombre: ${_nameController.text}\n'
          'Edad: ${_ageController.text}\n'
          'Correo: ${_emailController.text}',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Diálogo para mostrar mensajes de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Diálogo para mostrar mensajes de éxito (Requisito 3.c)
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Genial'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Liberar los controladores cuando el widget se destruye
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Campo de Nombre (solo en modo registro)
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu nombre.'; 
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),

                // Campo de Edad (solo en modo registro)
                if (!_isLogin)
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Edad'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu edad.'; 
                      }
                      final age = int.tryParse(value);
                      if (age == null || age <= 0) {
                        return 'La edad debe ser un número mayor que cero.'; 
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),

                // Campo de Correo Electrónico
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@') || !value.contains('.')) {
                      return 'Por favor, ingresa un correo válido.'; 
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true, // Oculta la contraseña
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Botón de envío, muestra un spinner si está cargando
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(_isLogin ? 'Iniciar Sesión' : 'Registrar'),
                  ),

                // Botón para cambiar entre login y registro
                TextButton(
                  child: Text(_isLogin
                      ? '¿No tienes una cuenta? Regístrate'
                      : '¿Ya tienes una cuenta? Inicia sesión'),
                  onPressed: () {
                    // Uso de setState para actualizar la interfaz (Requisito 3.b)
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}