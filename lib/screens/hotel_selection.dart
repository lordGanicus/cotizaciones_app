import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/hotel_card.dart';
import 'registro_usuario_page.dart';

// IMPORTA AQUÍ TU PANTALLA PASO 1
import 'pasos/crear_cotizacion_habitacion_step1.dart'; // Ajusta la ruta según tu estructura

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
      // Carga datos del usuario y hotel único
      final responseUser = await supabase
          .from('usuarios')
          .select(
              'nombre_completo, ci, id_establecimiento, establecimientos!usuarios_id_establecimiento_fkey(nombre, logotipo)')
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

      // Si no tiene hotel único, cargar múltiples
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

      // No hay hoteles asignados
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

  Future<void> _crearNuevaCotizacion() async {
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
          builder: (_) => PasoCantidadPage(idCotizacion: idCotizacion),
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
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        const SizedBox(height: 20),
                        if (datosUsuario != null) ...[
                          Text('👤 Usuario: ${datosUsuario!['nombre']}'),
                          Text('🪪 CI: ${datosUsuario!['ci']}'),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _crearNuevaCotizacion,
                          child: const Text('Crear nueva cotización'),
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
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final cotizaciones = snapshot.data!;
                            if (cotizaciones.isEmpty) {
                              return const Center(
                                  child: Text('No hay cotizaciones registradas.'));
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cotizaciones.length,
                              itemBuilder: (context, index) {
                                final c = cotizaciones[index];
                                return ListTile(
                                  title: Text(
                                      'Cotización del ${c['fecha_creacion'].toString().split('T').first}'),
                                  subtitle: Text('Estado: ${c['estado']}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Aquí irá la navegación al detalle de cotización
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ] else if (hotelesMultiples.isNotEmpty) ...[
                  const Text(
                    'Hoteles asignados:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: hotelesMultiples.length,
                    itemBuilder: (context, index) {
                      final hotel = hotelesMultiples[index];
                      return HotelCard(
                        name: hotel['nombre'],
                        imagePath: hotel['logotipo'] ?? '',
                        onTap: () {
                          // Aquí puedes manejar selección múltiple si deseas
                        },
                      );
                    },
                  ),
                ] else ...[
                  const Center(
                    child:
                        Text('No tienes un hotel asignado. Contacta con un administrador.'),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistroUsuarioPage()),
                    );
                  },
                  child: const Text('Registrar Usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}