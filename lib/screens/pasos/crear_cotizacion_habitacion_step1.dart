import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crear_cotizacion_habitacion_step2.dart';

class CrearCotizacionHabitacionStep1 extends StatefulWidget {
  final String idCotizacion;

  const CrearCotizacionHabitacionStep1({super.key, required this.idCotizacion});

  @override
  State<CrearCotizacionHabitacionStep1> createState() =>
      _CrearCotizacionHabitacionStep1State();
}

class _CrearCotizacionHabitacionStep1State
    extends State<CrearCotizacionHabitacionStep1> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _ciClienteController = TextEditingController();

  String? nombreEstablecimiento;
  bool isLoading = true;
  String? error;

  // Colores del diseño
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D4059);
  static const Color textSecondary = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _cargarEstablecimientoUsuario();
  }

  Future<void> _cargarEstablecimientoUsuario() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no logueado';

      final usuarioRes = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioRes['id_establecimiento'] as String;

      final establecimientoRes = await supabase
          .from('establecimientos')
          .select('nombre')
          .eq('id', idEstablecimiento)
          .single();

      setState(() {
        nombreEstablecimiento = establecimientoRes['nombre'] as String?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando establecimiento: $e';
        isLoading = false;
      });
    }
  }

  bool _validarNombre(String nombre) {
    final regex = RegExp(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*$');
    return regex.hasMatch(nombre);
  }

  Future<void> _guardarClienteYContinuar() async {
    String nombre = _nombreClienteController.text.trim();
    final ci = _ciClienteController.text.trim();

    // Formatear el nombre a Capitalización
    nombre = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');

    if (nombre.isEmpty || !_validarNombre(nombre)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un nombre válido (solo letras y con mayúscula inicial en cada palabra)'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          backgroundColor: darkBlue,
        ),
      );
      return;
    }

    if (ci.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(ci)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El CI/NIT solo puede contener números'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          backgroundColor: Color.fromARGB(255, 161, 1, 22),
        ),
      );
      return;
    }

    try {
      final response = await supabase.from('clientes').upsert({
        'ci': ci.isEmpty ? null : ci,
        'nombre_completo': nombre,
      }, onConflict: 'ci').select('id').single();

      final String idCliente = response['id'] as String;

      await supabase.from('cotizaciones').update({
        'id_cliente': idCliente,
      }).eq('id', widget.idCotizacion);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrearCotizacionHabitacionStep2(
            idCotizacion: widget.idCotizacion,
            nombreCliente: nombre,
            ciCliente: ci,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cliente: $e'),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Datos del Cliente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta info hotel
                  Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hotel,
                            color: primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            nombreEstablecimiento ?? 'No especificado',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Información del cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulario
                  Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Nombre
                        TextFormField(
                          controller: _nombreClienteController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                          ],
                          style: const TextStyle(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // CI/NIT
                        TextFormField(
                          controller: _ciClienteController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'CI / NIT (opcional)',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Botón continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardarClienteYContinuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('CONTINUAR'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}