import 'package:cotizaciones_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/hotel_selection.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const CotizacionApp());
}

class CotizacionApp extends StatelessWidget {
  const CotizacionApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Cotizaciones App',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.hotelColors['Rey Palac']!,
        secondary: AppColors.hotelColors['Madero']!,
        surface: Colors.white,
        background: const Color(0xFFF8F9FA),
        onBackground: const Color(0xFF212529),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212529),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212529),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6C757D)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.hotelColors['Rey Palac']!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.hotelColors['Rey Palac']!,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.hotelColors['Rey Palac']!,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    home: const AuthWrapper(),
  );
}
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.session != null) {
          return const MainAppScreen(); // Cambiado a MainAppScreen
        }
        
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        setState(() => _errorMessage = 'Credenciales incorrectas');
      }
    } on AuthException catch (error) {
      setState(() => _errorMessage = _parseAuthError(error.message));
    } catch (error) {
      setState(() => _errorMessage = 'Error inesperado. Intente nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseAuthError(String message) {
    if (message.contains('Email not confirmed')) {
      return 'Confirme su correo electrónico primero';
    } else if (message.contains('Invalid login credentials')) {
      return 'Credenciales incorrectas';
    } else if (message.contains('User already registered')) {
      return 'Usuario ya registrado';
    } else if (message.contains('404')) {
      return 'Error de conexión con el servidor';
    }
    return message;
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Ingrese un correo válido');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-password/',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enlace de recuperación enviado a $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (error) {
      setState(() => _errorMessage = _parseAuthError(error.message));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'COTIZACIONES',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.hotelColors['Rey Palac'],
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistema profesional de gestión hotelera',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212529),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey.shade600,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.hotelColors['Rey Palac'],
                              ),
                            ),
                            validator: (value) =>
                              (value == null || value.isEmpty || !value.contains('@')) 
                                ? 'Ingrese un correo válido' 
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey.shade600,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.hotelColors['Rey Palac'],
                              ),
                            ),
                            validator: (value) =>
                              (value == null || value.length < 6) 
                                ? 'Mínimo 6 caracteres' 
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: const Text('¿Olvidó su contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('INICIAR SESIÓN'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outlined,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡Bienvenid${user?.userMetadata?['gender'] == 'female' ? 'a' : 'o'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                         Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotelSelectionPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('COMENZAR'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}