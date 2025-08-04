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

  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _ciClienteController = TextEditingController();

  String? nombreEstablecimiento;
  bool isLoading = true;
  String? error;

  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);

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
        const SnackBar(content: Text('Por favor ingrese el nombre del cliente')),
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
        SnackBar(content: Text('Error al guardar cliente: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Paso 1 - Datos del Cliente'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nombreEstablecimiento != null)
                        Text(
                          'Hotel: $nombreEstablecimiento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Información del Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nombreClienteController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ciClienteController,
                        decoration: InputDecoration(
                          labelText: 'CI / NIT (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge_outlined),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarClienteYContinuar,
                          icon: const Icon(Icons.navigate_next),
                          label: const Text('Siguiente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: darkBlue),
                            foregroundColor: darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
