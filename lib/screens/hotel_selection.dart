import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'registro_usuario_page.dart';
import 'pasos/crear_cotizacion_habitacion_step1.dart';
import 'pasoscomida/crear_cotizacion_comida_step.dart';
import 'servicios/servicios_screen.dart';
import 'refrigerios/refrigerios_screen.dart';
import 'salon/salones_screen.dart';
import 'habitaciones/habitaciones_screen.dart';
import 'gestion_general_screen.dart';
import 'pasossalon/crear_cotizacion_salon_step1.dart';

class HotelSelectionPage extends StatefulWidget {
  const HotelSelectionPage({super.key});

  @override
  State<HotelSelectionPage> createState() => _HotelSelectionPageState();
}

class _HotelSelectionPageState extends State<HotelSelectionPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? hotelUnico;
  List<Map<String, dynamic>> hotelesMultiples = [];
  Map<String, dynamic>? datosUsuario;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarInformacion();
  }

  Future<void> _cargarInformacion() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final responseUser = await supabase
          .from('usuarios')
          .select(
              'nombre_completo, ci, id_establecimiento, establecimientos!usuarios_id_establecimiento_fkey(nombre, logotipo, id)')
          .eq('id', user.id)
          .maybeSingle();

      if (responseUser != null) {
        datosUsuario = {
          'nombre': responseUser['nombre_completo'],
          'ci': responseUser['ci'],
        };

        if (responseUser['establecimientos'] != null) {
          setState(() {
            hotelUnico = responseUser['establecimientos'];
            isLoading = false;
          });
          return;
        }
      }

      final responseMultiples = await supabase
          .from('usuarios_establecimientos')
          .select('establecimientos(nombre, logotipo, id)')
          .eq('id_usuario', user.id);

      if (responseMultiples != null && responseMultiples.isNotEmpty) {
        List<Map<String, dynamic>> hoteles = (responseMultiples as List)
            .map<Map<String, dynamic>>(
                (e) => e['establecimientos'] as Map<String, dynamic>)
            .toList();

        setState(() {
          hotelesMultiples = hoteles;
          isLoading = false;
        });
        return;
      }

      setState(() {
        hotelUnico = null;
        hotelesMultiples = [];
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _cargarCotizaciones() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('cotizaciones')
        .select()
        .eq('id_usuario', user.id)
        .order('fecha_creacion', ascending: false);

    return response;
  }

  Future<void> _crearNuevaCotizacionHabitacion() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final nuevaCotizacion = await supabase.from('cotizaciones').insert({
      'id_usuario': user.id,
    }).select().single();

    if (context.mounted) {
      final idCotizacion = nuevaCotizacion['id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionHabitacionStep1(idCotizacion: idCotizacion),
        ),
      );
    }
  }

  Future<void> _crearNuevaCotizacionSalon() async {
    final user = supabase.auth.currentUser;
    if (user == null || hotelUnico == null) return;

    final nuevaCotizacion = await supabase.from('cotizaciones').insert({
      'id_usuario': user.id,
    }).select().single();

    if (context.mounted) {
      final idCotizacion = nuevaCotizacion['id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Paso1CotizacionSalonPage(
            idCotizacion: idCotizacion,
            idEstablecimiento: hotelUnico!['id'],
            idUsuario: user.id, 
          ),
        ),
      );
    }
  }

  Future<void> _crearNuevaCotizacionComida() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final nuevaCotizacion = await supabase.from('cotizaciones').insert({
      'id_usuario': user.id,
    }).select().single();

    if (context.mounted) {
      final idCotizacion = nuevaCotizacion['id'];

      final nombre = datosUsuario?['nombre'] ?? 'Sin nombre';
      final ci = datosUsuario?['ci'] ?? 'Sin CI';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionComidaStep(
            idCotizacion: idCotizacion,
            nombreCliente: nombre,
            ciCliente: ci,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hotelUnico != null) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          hotelUnico!['nombre'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (hotelUnico!['logotipo'] != null)
                          Image.network(
                            hotelUnico!['logotipo'],
                            height: 100,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        const SizedBox(height: 20),
                        if (datosUsuario != null) ...[
                          Text('👤 Usuario: ${datosUsuario!['nombre']}'),
                          Text('🪪 CI: ${datosUsuario!['ci']}'),
                        ],
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _crearNuevaCotizacionSalon,
                          icon: const Icon(Icons.event),
                          label: const Text('Crear cotización de salón'),
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _crearNuevaCotizacionHabitacion,
                          icon: const Icon(Icons.bed),
                          label: const Text('Crear cotización de habitación'),
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _crearNuevaCotizacionComida,
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Crear cotización de comida'),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GestionGeneralScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Gestionar Servicios, Refrigerios, Salones y Habitaciones'),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Tus cotizaciones anteriores:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _cargarCotizaciones(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final cotizaciones = snapshot.data!;
                            if (cotizaciones.isEmpty) {
                              return const Center(child: Text('No hay cotizaciones registradas.'));
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cotizaciones.length,
                              itemBuilder: (context, index) {
                                final c = cotizaciones[index];
                                return ListTile(
                                  title: Text('Cotización del ${c['fecha_creacion'].toString().split('T').first}'),
                                  subtitle: Text('Estado: ${c['estado'] ?? 'N/D'}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Aquí podrías navegar a un resumen futuro
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (hotelesMultiples.isNotEmpty) ...[
                  const Text(
                    'Selecciona un hotel para continuar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...hotelesMultiples.map((hotel) {
                    return ListTile(
                      leading: hotel['logotipo'] != null
                          ? Image.network(hotel['logotipo'], width: 50, height: 50, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                          : const Icon(Icons.hotel),
                      title: Text(hotel['nombre']),
                      onTap: () {
                        // Aquí podrías implementar selección múltiple si deseas
                      },
                    );
                  }),
                ],
                if (hotelUnico == null && hotelesMultiples.isEmpty && !isLoading) ...[
                  const Center(
                    child: Text('No se encontraron hoteles asignados a este usuario.'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
