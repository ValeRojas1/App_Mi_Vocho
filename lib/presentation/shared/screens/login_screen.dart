import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_notifier.dart';
class LoginScreen extends StatefulWidget {
  final AuthNotifier authNotifier;

  const LoginScreen({super.key, required this.authNotifier});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _loading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Animación del logotipo
  late AnimationController _logoAnimController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeInOut),
    );
    _logoAnimController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (widget.authNotifier.isOwner) {
      context.go('/owner');
    } else {
      context.go('/client');
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _formKey.currentState?.reset();
      _nameController.clear();
      _confirmPasswordController.clear();
    });
  }

  // Lógica principal de envío (Login o Registro)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_isRegisterMode) {
        // --- FLUJO DE REGISTRO ---
        // Usar data: {'full_name': name} para que coincida con el trigger de profiles
        final authRes = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
          },
        );

        if (!mounted) return;

        // Caso 1: Confirmación de Email Deshabilitada en Supabase (Sesión activa al instante)
        if (authRes.session != null) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': name,
              },
            ),
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada con éxito! Bienvenido(a)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await widget.authNotifier.loadRole();
          if (!mounted) return;
          _goHome();
        } else {
          // Caso 2: Confirmación de Email Habilitada en Supabase (Manejo de estado 'Email No Confirmado')
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined, color: Colors.orange, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Confirmar Correo',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              content: const Text(
                '¡Tu cuenta ha sido creada con éxito!\n\n'
                'Te hemos enviado un enlace de verificación a tu correo electrónico. '
                'Por favor, revisa tu bandeja de entrada (y spam) para confirmar tu cuenta antes de iniciar sesión.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    // Cambiar a modo Login para que puedan iniciar sesión una vez verificado
                    setState(() {
                      _isRegisterMode = false;
                      _formKey.currentState?.reset();
                      _nameController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      } else {
        // --- FLUJO DE INGRESO ---
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (!mounted) return;

        await widget.authNotifier.loadRole();
        if (!mounted) return;
        _goHome();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      
      // Limpiar campos de contraseña para seguridad y corrección
      _passwordController.clear();
      _confirmPasswordController.clear();

      String message = e.message;
      if (message.contains('already registered') || message.contains('already exists')) {
        message = 'Este correo electrónico ya está registrado. Por favor, inicia sesión.';
      } else if (message.contains('Invalid login credentials')) {
        message = 'Correo o contraseña incorrectos. Por favor, verifica.';
      } else if (message.contains('Email not confirmed')) {
        message = 'Tu correo electrónico no ha sido verificado. Por favor, revísalo.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC8102E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: const Color(0xFFC8102E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF003087); // Azul VW
    const accentColor = Color(0xFFFFC72C);  // Amarillo cálido

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8), // Fondo crema claro vintage de clientes
      body: Stack(
        children: [
          // Decoración de fondo premium (Círculos difuminados de color)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logotipo animado
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 64,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'La Casa del Volkswagen',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mi Vocho',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Tarjeta de Formulario Principal
                      Card(
                        elevation: 4,
                        color: const Color(0xFFFAF5E6), // Fondo crema cálido premium para la tarjeta
                        shadowColor: primaryColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(color: primaryColor, width: 2.5), // Borde Azul Marino VW
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRegisterMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRegisterMode
                                    ? 'Regístrate para realizar tus pedidos'
                                    : 'Ingresa para ver repuestos y ofertas',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Campo Nombre Completo (Solo en modo Registro)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isRegisterMode
                                    ? Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: TextFormField(
                                          controller: _nameController,
                                          textCapitalization: TextCapitalization.words,
                                          decoration: InputDecoration(
                                            labelText: 'Nombre completo',
                                            prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                                          ),
                                          validator: (v) {
                                            if (_isRegisterMode) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'Por favor ingresa tu nombre';
                                              }
                                              // Validar que solo contenga letras y espacios
                                              final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
                                              if (!nameRegex.hasMatch(v.trim())) {
                                                return 'El nombre solo debe contener letras';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              
                              // Campo Correo
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!regex.hasMatch(v.trim())) {
                                    return 'Ingresa un correo electrónico válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Campo Contraseña
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: primaryColor.withValues(alpha: 0.6),
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  if (v.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  if (_isRegisterMode) {
                                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                      return 'Debe incluir al menos una letra mayúscula';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                                      return 'Debe incluir al menos un número';
                                    }
                                    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+\\\/\[\]~`;]').hasMatch(v)) {
                                      return 'Debe incluir al menos un carácter especial (ej. @, #, \$, &)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              
                              // Campo Confirmar Contraseña (Solo en modo Registro)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isRegisterMode
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          decoration: InputDecoration(
                                            labelText: 'Confirmar contraseña',
                                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: primaryColor.withValues(alpha: 0.6),
                                              ),
                                              onPressed: () {
                                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                              },
                                            ),
                                          ),
                                          validator: (v) {
                                            if (_isRegisterMode) {
                                              if (v == null || v.isEmpty) {
                                                return 'Confirma tu contraseña';
                                              }
                                              if (v != _passwordController.text) {
                                                return 'Las contraseñas no coinciden';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // Botón de Envío
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shadowColor: primaryColor.withValues(alpha: 0.3),
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isRegisterMode ? 'REGISTRARSE' : 'INGRESAR',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Enlace para alternar entre ingresar y registrarse
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegisterMode
                                ? '¿Ya tienes cuenta?'
                                : '¿No tienes cuenta?',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isRegisterMode ? 'Inicia sesión' : 'Regístrate aquí',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}