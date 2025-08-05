import 'package:flutter/material.dart';
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

  final TextEditingController _nombreClienteController = TextEditingController();
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

  Future<void> _guardarClienteYContinuar() async {
    final nombre = _nombreClienteController.text.trim();
    final ci = _ciClienteController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese el nombre del cliente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          backgroundColor: darkBlue,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando información...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _cargarEstablecimientoUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de información del hotel
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
                              child: Icon(
                                Icons.hotel,
                                color: primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hotel',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nombreEstablecimiento ?? 'No especificado',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título de sección
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Información del Cliente',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Complete los datos requeridos',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
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
                            // Campo de nombre
                            TextFormField(
                              controller: _nombreClienteController,
                              style: const TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Nombre completo',
                                labelStyle: TextStyle(color: textSecondary),
                                floatingLabelStyle:
                                    TextStyle(color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: darkBlue.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo de CI/NIT
                            TextFormField(
                              controller: _ciClienteController,
                              style: const TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CI / NIT (opcional)',
                                labelStyle: TextStyle(color: textSecondary),
                                floatingLabelStyle:
                                    TextStyle(color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: darkBlue.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Botón de continuar
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: primaryGreen.withOpacity(0.3),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('CONTINUAR'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón de cancelar
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}