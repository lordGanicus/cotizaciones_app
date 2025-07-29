import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crear_cotizacion_habitacion_step2.dart';

class CrearCotizacionHabitacionStep1 extends StatefulWidget {
  final String idCotizacion;

  const CrearCotizacionHabitacionStep1({super.key, required this.idCotizacion});

  @override
  State<CrearCotizacionHabitacionStep1> createState() => _CrearCotizacionHabitacionStep1State();
}

class _CrearCotizacionHabitacionStep1State extends State<CrearCotizacionHabitacionStep1> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nombreClienteController = TextEditingController();
  final TextEditingController _ciClienteController = TextEditingController();

  String? nombreEstablecimiento;
  bool isLoading = true;
  String? error;

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
      // Upsert cliente y devolver id
      final response = await supabase.from('clientes').upsert({
        'ci': ci.isEmpty ? null : ci,
        'nombre_completo': nombre,
      }, onConflict: 'ci').select('id').single();

      final String idCliente = response['id'] as String;

      // Actualizar cotización con id_cliente
      await supabase.from('cotizaciones').update({
        'id_cliente': idCliente,
      }).eq('id', widget.idCotizacion);

      // Continuar al paso 2
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 1 - Datos del Cliente'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (nombreEstablecimiento != null)
                        Text(
                          'Hotel: $nombreEstablecimiento',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nombreClienteController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ciClienteController,
                        decoration: InputDecoration(
                          labelText: 'CI / NIT (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _guardarClienteYContinuar,
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('Siguiente'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
