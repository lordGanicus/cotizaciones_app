import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pasos/crear_cotizacion_habitacion_step1.dart';
import 'gestion_general_screen.dart';
import 'pasossalon/crear_cotizacion_salon_step1.dart';
import 'pasoEstablecimiento/pantalla_establecimientos.dart';
import '../screens/pasosUsuarios/usuarios_list.dart';
import '../screens/pasoscomida/crear_cotizacion_comida_step1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/establecimiento_dropdown.dart';


import '../../models/establecimiento.dart';
import '../../providers/establecimiento_provider.dart';
import '../../providers/usuario_provider.dart';

class HotelSelectionPage extends StatefulWidget {
  const HotelSelectionPage({super.key});

  @override
  State<HotelSelectionPage> createState() => _HotelSelectionPageState();
}

class _HotelSelectionPageState extends State<HotelSelectionPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? hotelUnico;
  List<Map<String, dynamic>> hotelesMultiples = [];
  Map<String, dynamic>? subestablecimientoUnico;
  Map<String, dynamic>? datosUsuario;
  Map<String, dynamic>? rolUsuario;
  List<Map<String, dynamic>> cotizaciones = [];
  List<Map<String, dynamic>> cotizacionesFiltradas = [];
  bool isLoading = true;
  bool showCreateDialog = false;
  bool showManageDialog = false;
  final TextEditingController _searchController = TextEditingController();

  // Variables para el selector de establecimientos
  List<Establecimiento> establecimientosDisponibles = [];
  Establecimiento? establecimientoSeleccionado;
  String? establecimientoSeleccionadoId;
  bool cargandoEstablecimientos = false;

  @override
  void initState() {
    super.initState();
    _cargarInformacion().then((_) {
      if (rolUsuario?['nombre'] == 'Administrador') {
          _cargarInformacion();
          _searchController.addListener(_filtrarCotizaciones);
      }
    });
    _searchController.addListener(_filtrarCotizaciones);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarCotizaciones() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        cotizacionesFiltradas = List.from(cotizaciones);
      } else {
        cotizacionesFiltradas = cotizaciones.where((cotizacion) {
          final nombre =
              (cotizacion['nombre_cliente'] ?? '').toString().toLowerCase();
          final ci = (cotizacion['ci_cliente'] ?? '').toString().toLowerCase();
          final tipo =
              (_obtenerTipo(cotizacion) ?? '').toString().toLowerCase();
          return nombre.contains(query) ||
              ci.contains(query) ||
              tipo.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _cargarInformacion() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final responseUser = await supabase.from('usuarios').select('''
            nombre_completo,
            ci,
            genero,
            avatar,
            id_establecimiento,
            id_subestablecimiento,
            roles!usuarios_id_rol_fkey(nombre),
            establecimientos!usuarios_id_establecimiento_fkey(nombre, logotipo, id),
            subestablecimientos(nombre, logotipo, id)
          ''').eq('id', user.id).maybeSingle();

      print('responseUser: $responseUser');

      if (responseUser != null) {
        datosUsuario = {
          'nombre': responseUser['nombre_completo'],
          'ci': responseUser['ci'],
          'genero': responseUser['genero'],
          'avatar': responseUser['avatar'],
        };

        rolUsuario = responseUser['roles'];

        if (responseUser['establecimientos'] != null) {
          setState(() {
            hotelUnico = responseUser['establecimientos'];
          });
        }

        if (responseUser['subestablecimientos'] != null) {
          setState(() {
            subestablecimientoUnico = responseUser['subestablecimientos'];
          });
        }
      }

      await _cargarCotizaciones();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cargarCotizaciones() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase.rpc('obtener_historial_clientes2',
          params: {'p_id_usuario': user.id});

      setState(() {
        cotizaciones = List<Map<String, dynamic>>.from(response);
        cotizacionesFiltradas = List.from(cotizaciones);
      });
    } catch (e) {
      print('Error al cargar cotizaciones: $e');
      setState(() {
        cotizaciones = [];
        cotizacionesFiltradas = [];
      });
    }
  }

  Widget _buildAvatar() {
    if (datosUsuario?['avatar'] != null) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(datosUsuario!['avatar']),
        onBackgroundImageError: (_, __) {},
        child: datosUsuario!['avatar'] == null ? _getDefaultAvatar() : null,
      );
    }
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey[300],
      child: _getDefaultAvatar(),
    );
  }

  Widget _getDefaultAvatar() {
    final genero = datosUsuario?['genero']?.toString().toLowerCase();
    if (genero == 'masculino' || genero == 'm') {
      return const Icon(Icons.person, color: Colors.blue, size: 30);
    } else if (genero == 'femenino' || genero == 'f') {
      return const Icon(Icons.person, color: Colors.pink, size: 30);
    }
    return const Icon(Icons.person, color: Colors.grey, size: 30);
  }

  String _formatearFecha(dynamic fechaInput) {
    if (fechaInput == null) return 'N/D';

    try {
      final fecha = fechaInput is String
          ? DateTime.parse(fechaInput)
          : fechaInput as DateTime;
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (_) {
      return fechaInput.toString();
    }
  }

  String _obtenerTipo(Map<String, dynamic> cotizacion) {
    if (cotizacion['tipo'] != null) {
      final tipo = cotizacion['tipo'].toString().toLowerCase();
      if (tipo.contains('habitación') || tipo.contains('habitacion')) {
        return 'Habitación';
      } else if (tipo.contains('restaurante') || tipo.contains('comida')) {
        return 'Restaurante';
      } else if (tipo.contains('salón') || tipo.contains('salon')) {
        return 'Salón';
      }
      return cotizacion['tipo'];
    }
    return 'General';
  }

  Future<void> _crearNuevaCotizacionHabitacion() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final nuevaCotizacion = await supabase
        .from('cotizaciones')
        .insert({
          'id_usuario': user.id,
        })
        .select()
        .single();

    if (context.mounted) {
      setState(() => showCreateDialog = false);
      final idCotizacion = nuevaCotizacion['id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CrearCotizacionHabitacionStep1(idCotizacion: idCotizacion),
        ),
      );
    }
  }

  Future<void> _crearNuevaCotizacionSalon() async {
    final user = supabase.auth.currentUser;
    if (user == null || hotelUnico == null) return;

    try {
      final nuevaCotizacion = await supabase
          .from('cotizaciones')
          .insert({
            'id_usuario': user.id,
          })
          .select()
          .single();

      if (context.mounted) {
        setState(() => showCreateDialog = false);

        final idCotizacion = nuevaCotizacion['id'];
        print('Nueva cotización creada con ID: $idCotizacion');
        print('Establecimiento seleccionado: $establecimientoSeleccionadoId');
        print('Usuario actual: ${user.id}');
        print('Subestablecimiento: ${subestablecimientoUnico?['id']}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Paso1CotizacionSalonPage(
              idCotizacion: idCotizacion,
              idEstablecimiento: establecimientoSeleccionadoId!, // <-- fuerza no null
              idUsuario: user.id,
              idSubestablecimiento: subestablecimientoUnico?['id'],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creando cotización: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creando cotización: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _crearNuevaCotizacionComida() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final nuevaCotizacion = await supabase
        .from('cotizaciones')
        .insert({
          'id_usuario': user.id,
        })
        .select()
        .single();

    if (context.mounted) {
      setState(() => showCreateDialog = false);
      final idCotizacion = nuevaCotizacion['id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionComidaStep1(
            idCotizacion: idCotizacion,
            idEstablecimiento: establecimientoSeleccionadoId, // <- valor actualizado
            idUsuario: user.id,
            idSubestablecimiento: subestablecimientoUnico?['id'],
          ),
        ),
      );
    }
  }

  Widget _buildCreateDialog() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.create, color: Color(0xFF2D4059)),
                  const SizedBox(width: 10),
                  const Text(
                    'Crear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4059),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDialogButton(
                'Crear cotización de habitación',
                Icons.bed,
                _crearNuevaCotizacionHabitacion,
              ),
              const SizedBox(height: 10),
              _buildDialogButton(
                'Crear cotización de salón',
                Icons.event,
                _crearNuevaCotizacionSalon,
              ),
              const SizedBox(height: 10),
              _buildDialogButton(
                'Crear cotización de restaurante',
                Icons.restaurant_menu,
                _crearNuevaCotizacionComida,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => showCreateDialog = false),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageDialog() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF2D4059)),
                  const SizedBox(width: 10),
                  const Text(
                    'Gestionar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4059),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDialogButton(
                'Gestionar Servicios Generales',
                Icons.manage_accounts,
                () {
                  setState(() => showManageDialog = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionGeneralScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildDialogButton(
                'Gestionar Establecimiento',
                Icons.business,
                () {
                  setState(() => showManageDialog = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantallaEstablecimientos(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildDialogButton(
                'Crear Usuario',
                Icons.person_add,
                () {
                  setState(() => showManageDialog = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UsuarioListPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => showManageDialog = false),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(
      String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B894),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

Widget _buildCotizacionItem(Map<String, dynamic> cotizacion) {
  String tipo = _obtenerTipo(cotizacion);

  Color colorFondo;
  Color colorTexto;

  switch (tipo) {
    case 'Habitación':
     colorFondo = const Color(0xFF223144); 
       // azul clarito
      colorTexto = Colors.white; // texto blanco
      break;
    case 'Salón':
     // azul oscuro
     colorFondo = const Color.fromARGB(255, 155, 178, 206);
      colorTexto = Colors.white; // texto blanco
      break;
    case 'Restaurante':
      colorFondo = const Color(0xFF374E6D); // azul intermedio
      colorTexto = Colors.white; // texto blanco
      break;
    default:
      colorFondo = const Color(0xFF2D4059); // color por defecto
      colorTexto = Colors.white; // texto legible
  }

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cotizacion['nombre_cliente'] ?? 'N/D',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 100, // ancho fijo para todos los tipos
                height: 30, // altura uniforme
                alignment: Alignment.center, // centrar texto
                decoration: BoxDecoration(
                  color: colorFondo, // fondo según tipo
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tipo,
                  style: TextStyle(
                    color: colorTexto, // texto adaptado al fondo
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'CI: ${cotizacion['ci_cliente'] ?? 'N/D'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha : ${_formatearFecha(cotizacion['primera_fecha'])}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                'Bs. ${cotizacion['total_acumulado']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B894),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Future<void> _cambiarEstablecimiento(
  BuildContext context,
  WidgetRef ref,
  String nuevoId,
  List<Establecimiento> establecimientos,
) async {
  final nuevoEstablecimiento = establecimientos.firstWhere((e) => e.id == nuevoId);
  
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar cambio'),
      content: Text('¿Estás seguro de cambiar al establecimiento ${nuevoEstablecimiento.nombre}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    final antiguoPrincipalId = establecimientoSeleccionadoId;
    print('Iniciando cambio de establecimiento: $antiguoPrincipalId -> $nuevoId');

    // 1. Insertar antiguo principal en usuarios_establecimientos si no existe
    if (antiguoPrincipalId != null) {
      final response = await supabase
          .from('usuarios_establecimientos')
          .select()
          .eq('id_usuario', user.id)
          .eq('id_establecimiento', antiguoPrincipalId);

      // 'response' es dynamic (generalmente List<dynamic>)
      if (response == null || (response is List && response.isEmpty)) {
        print('Insertando antiguo principal en secundarios');
        await supabase.from('usuarios_establecimientos').insert({
          'id_usuario': user.id,
          'id_establecimiento': antiguoPrincipalId,
        });
      }
    }

    // 2. Eliminar el nuevo seleccionado de usuarios_establecimientos
    print('Eliminando nuevo seleccionado de secundarios');
    await supabase
        .from('usuarios_establecimientos')
        .delete()
        .eq('id_usuario', user.id)
        .eq('id_establecimiento', nuevoId);

    // 3. Actualizar usuarios.id_establecimiento
    print('Actualizando usuario.id_establecimiento');
    await supabase
        .from('usuarios')
        .update({'id_establecimiento': nuevoId})
        .eq('id', user.id);

    // Actualizar estado local
    setState(() {
      establecimientoSeleccionadoId = nuevoId;
      establecimientoSeleccionado = nuevoEstablecimiento;
    });

    // Refrescar providers
    ref.invalidate(usuarioActualProvider);
    ref.invalidate(establecimientosFiltradosProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Establecimiento cambiado con éxito')),
      );
    }
  } catch (e) {
    print('Error al cambiar establecimiento: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar establecimiento')),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEAEAEA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = rolUsuario?['nombre'] == 'Administrador';
    final isGerente = rolUsuario?['nombre'] == 'Gerente';
    final isUsuarioNormal = rolUsuario?['nombre'] == 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      body: Stack(
        children: [
          Column(
            children: [
              // Header azul claro
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2D4059),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(5, 5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Spacer(),

                        // Botón con ícono + texto "Actualizar"
                        TextButton.icon(
                          onPressed: _cargarCotizaciones,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'Actualizar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    if (establecimientosFiltradosProvider != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF2D4059), width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final establecimientosAsync = ref.watch(establecimientosFiltradosProvider);
                                  final usuarioAsync = ref.watch(usuarioActualProvider);

                                  print('--- REBUILD DROPDOWN ---');
                                  print('Estado establecimientosAsync: ${establecimientosAsync.value}');
                                  print('Estado usuarioAsync: ${usuarioAsync.value}');

                                  return establecimientosAsync.when(
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (error, stack) {
                                      print('Error cargando establecimientos: $error');
                                      return Text('Error: $error');
                                    },
                                    data: (establecimientos) {
                                      return usuarioAsync.when(
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (error, stack) {
                                          print('Error cargando usuario: $error');
                                          return Text('Error: $error');
                                        },
                                        data: (usuario) {
                                          print('Establecimientos disponibles: ${establecimientos.length}');
                                          print('ID establecimiento usuario: ${usuario.idEstablecimiento}');
                                          print('Estado local seleccionado: $establecimientoSeleccionadoId');

                                          // Inicializar selección solo si es necesario
                                          if (establecimientoSeleccionadoId == null && establecimientos.isNotEmpty) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              final nuevoId = usuario.idEstablecimiento ?? establecimientos.first.id;
                                              final estSeleccionado = establecimientos.firstWhere(
                                                (e) => e.id == nuevoId,
                                                orElse: () => establecimientos.first,
                                              );
                                              setState(() {
                                                establecimientoSeleccionadoId = nuevoId;
                                                establecimientoSeleccionado = estSeleccionado; // inicializa el logo también
                                              });
                                              print('Inicializando selección con: $nuevoId');
                                            });
                                          }

                                          // Si no hay establecimientos
                                          if (establecimientos.isEmpty) {
                                            return const Text('No hay establecimientos disponibles');
                                          }

                                          // Ordenar establecimientos (principal primero)
                                          final listaOrdenada = List<Establecimiento>.from(establecimientos);
                                          if (usuario.idEstablecimiento != null) {
                                            listaOrdenada.sort((a, b) {
                                              if (a.id == usuario.idEstablecimiento) return -1;
                                              if (b.id == usuario.idEstablecimiento) return 1;
                                              return 0;
                                            });
                                          }

                                          return DropdownButton<String>(
                                            isExpanded: true,
                                            value: establecimientoSeleccionadoId,
                                            underline: const SizedBox(),
                                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D4059)),
                                            items: listaOrdenada.map((e) {
                                              return DropdownMenuItem<String>(
                                                value: e.id,
                                                child: Text(
                                                  e.nombre ?? 'Sin nombre',
                                                  style: const TextStyle(color: Color(0xFF2D4059)),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (nuevoId) async {
                                              if (nuevoId != null && nuevoId != establecimientoSeleccionadoId) {
                                                _cambiarEstablecimiento(context, ref, nuevoId, listaOrdenada);
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Logo que se actualiza automáticamente según el establecimiento seleccionado
                        if (establecimientoSeleccionado != null &&
                            establecimientoSeleccionado!.logotipo != null) ...[
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D4059),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  establecimientoSeleccionado!.logotipo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    print('Error cargando logo de ${establecimientoSeleccionado!.nombre}');
                                    return const Icon(
                                      Icons.business,
                                      color: Colors.white,
                                      size: 50,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                                            // Usuario info
                      if (datosUsuario != null) ...[
                        Row(
                          children: [
                            _buildAvatar(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    datosUsuario!['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'CI: ${datosUsuario!['ci'] ?? 'Sin CI'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (rolUsuario != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rol: ${rolUsuario!['nombre']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],

                      // Barra de búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar cotizaciones...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título de sección
                      const Text(
                        'Historial de cotizaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D4059),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lista de cotizaciones
                      if (cotizacionesFiltradas.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No hay cotizaciones registradas.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ] else ...[
                        ...cotizacionesFiltradas
                            .map((cotizacion) =>
                                _buildCotizacionItem(cotizacion))
                            .toList(),
                      ],

                      const SizedBox(
                          height: 120), // Espacio para los botones flotantes
                    ],
                  ),
                ),
              )
            ],
          ),

          // Botones flotantes en la parte inferior con roles de usuario
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 98,
              decoration: const BoxDecoration(
                color: Color(0xFF2D4059),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: showCreateDialog
                          ? const Color(0xFF00B894)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() {
                          showCreateDialog = !showCreateDialog;
                          showManageDialog = false;
                        }),
                        child: Container(
                          height: 98,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Crear',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isAdmin || isGerente)
                    Expanded(
                      child: Material(
                        color: showManageDialog
                            ? const Color(0xFF00B894)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: isUsuarioNormal
                              ? null
                              : () => setState(() {
                                    showManageDialog = !showManageDialog;
                                    showCreateDialog = false;
                                  }),
                          child: Container(
                            height: 98,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder,
                                  color: isUsuarioNormal
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gestionar',
                                  style: TextStyle(
                                    color: isUsuarioNormal
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Diálogos superpuestos
          if (showCreateDialog)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showCreateDialog = false),
                child: Container(
                  color: Colors.black54,
                  child: Center(child: _buildCreateDialog()),
                ),
              ),
            ),

          if (showManageDialog)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showManageDialog = false),
                child: Container(
                  color: Colors.black54,
                  child: Center(child: _buildManageDialog()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
