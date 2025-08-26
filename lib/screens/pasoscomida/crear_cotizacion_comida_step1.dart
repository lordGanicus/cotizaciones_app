import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para filtros
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/cotizacion_comida_provider.dart';
import '../../screens/pasoscomida/crear_cotizacion_comida_step2.dart';

class CrearCotizacionComidaStep1 extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idUsuario;
  final String? idSubestablecimiento;

  /// Nuevo: puedes pasar el establecimiento desde el push
  /// o dejarlo en null para que se lea del usuario logueado.
  final String? idEstablecimiento;

  const CrearCotizacionComidaStep1({
    Key? key,
    required this.idCotizacion,
    required this.idUsuario,
    this.idSubestablecimiento,
    this.idEstablecimiento, // <-- nuevo param opcional
  }) : super(key: key);

  @override
  ConsumerState<CrearCotizacionComidaStep1> createState() =>
      _CrearCotizacionComidaStep1State();
}

class _CrearCotizacionComidaStep1State
    extends ConsumerState<CrearCotizacionComidaStep1> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();

  DateTime? _fechaEvento;
  TimeOfDay? _horaEvento;

  String? _selectedSubestablecimientoId;
  String? _selectedSubestablecimientoNombre;

  bool _isLoading = true;

  String? _idEstablecimientoActual;

  // Streams en tiempo real
  Stream<List<Map<String, dynamic>>>? _establecimientoStream;
  Stream<List<Map<String, dynamic>>>? _subestablecimientosStream;

  // Colores (no usar `const` dentro de Icon cuando depende de estos)
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _selectedSubestablecimientoId = widget.idSubestablecimiento;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.idEstablecimiento != null &&
        widget.idEstablecimiento!.isNotEmpty) {
      _idEstablecimientoActual = widget.idEstablecimiento;
      _initStreams(_idEstablecimientoActual!);
      setState(() => _isLoading = false);
      return;
    }
    await _cargarEstablecimientoDesdeUsuario();
  }

  Future<void> _cargarEstablecimientoDesdeUsuario() async {
    final supabase = Supabase.instance.client;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no logueado';

      final usuarioRes = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEst = usuarioRes['id_establecimiento'] as String?;
      if (idEst == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'No tienes un establecimiento asignado. Selecciónalo primero.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        return;
      }

      _idEstablecimientoActual = idEst;
      _initStreams(idEst);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando establecimiento: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _initStreams(String idEst) {
    final supabase = Supabase.instance.client;

    // Stream en tiempo real del establecimiento (para obtener nombre actualizado)
    _establecimientoStream = supabase
        .from('establecimientos')
        .stream(primaryKey: ['id'])
        .eq('id', idEst);

    // Stream en tiempo real de subestablecimientos del establecimiento
    _subestablecimientosStream = supabase
        .from('subestablecimientos')
        .stream(primaryKey: ['id'])
        .eq('id_establecimiento', idEst);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEvento ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaEvento = picked);
    }
  }

  Future<void> _selectHora() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaEvento ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _horaEvento = picked);
    }
  }

  bool _validarNombre(String nombre) {
    final regex =
        RegExp(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*$');
    return regex.hasMatch(nombre);
  }

  void _guardarYContinuar() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_fechaEvento == null || _horaEvento == null) {
        _showError('Debe seleccionar fecha y hora del evento');
        return;
      }
      if (_selectedSubestablecimientoId == null) {
        _showError('Debe seleccionar un subestablecimiento');
        return;
      }
      if (_idEstablecimientoActual == null) {
        _showError('No hay establecimiento seleccionado');
        return;
      }

      // Capitalizar el nombre
      String nombre = _nombreController.text.trim();
      nombre = nombre
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');

      if (!_validarNombre(nombre)) {
        _showError(
          'Ingrese un nombre válido (solo letras y espacios, con mayúscula inicial en cada palabra)',
        );
        return;
      }

      final ci = _ciController.text.trim();
     /* if (ci.isEmpty ) {
        _showError('El CI/NIT es obligatorio');
        return;
      }*/
      if (!RegExp(r'^[0-9]+$').hasMatch(ci)) {
        _showError('El CI/NIT solo puede contener números');
        return;
      }
      if (ci.length < 5) {
        _showError('Ingrese un CI/NIT válido');
        return;
      }

      final notifier = ref.read(cotizacionComidaProvider.notifier);

      notifier.setCliente(nombre: nombre, ci: ci);
      notifier.setIds(
        idCotizacion: widget.idCotizacion,
        idEstablecimiento: _idEstablecimientoActual!, // <- non-null aquí
        idUsuario: widget.idUsuario,
        idSubestablecimiento: _selectedSubestablecimientoId!,
      );
      notifier.setSubestablecimiento(
        id: _selectedSubestablecimientoId!,
        nombre: _selectedSubestablecimientoNombre ?? '',
      );

      final fechaHora = DateTime(
        _fechaEvento!.year,
        _fechaEvento!.month,
        _fechaEvento!.day,
        _horaEvento!.hour,
        _horaEvento!.minute,
      );

      notifier.setFechaYHoraEvento(_fechaEvento!, fechaHora);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearCotizacionComidaStep2(
            idCotizacion: widget.idCotizacion,
            idEstablecimiento: _idEstablecimientoActual!,
            idUsuario: widget.idUsuario,
            idSubestablecimiento: _selectedSubestablecimientoId,
          ),
        ),
      );
    }
  }

  void _showError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  String _formatearFecha() {
    if (_fechaEvento == null) return 'Seleccionar fecha';
    return DateFormat('dd/MM/yyyy').format(_fechaEvento!);
  }

  String _formatearHora() {
    if (_horaEvento == null) return 'Seleccionar hora';
    return '${_horaEvento!.hour.toString().padLeft(2, '0')}:${_horaEvento!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Datos del cliente y evento'),
        backgroundColor: darkBlue,
        centerTitle: true,
      ),
      body: _isLoading || _idEstablecimientoActual == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Tarjeta info establecimiento (nombre en tiempo real)
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _establecimientoStream,
                      builder: (context, snapEst) {
                        final nombreEstablecimiento =
                            (snapEst.data != null && snapEst.data!.isNotEmpty)
                                ? (snapEst.data!.first['nombre'] as String?)
                                : 'No especificado';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                child: Icon( // <- sin const
                                  Icons.restaurant_menu,
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
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Subestablecimientos en tiempo real
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _subestablecimientosStream,
                      builder: (context, snapSubs) {
                        if (snapSubs.connectionState ==
                                ConnectionState.waiting &&
                            !(snapSubs.hasData)) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final list = List<Map<String, dynamic>>.from(
                            snapSubs.data ?? const []);
                        // Ordenar por nombre localmente
                        list.sort((a, b) =>
                            (a['nombre'] ?? '').toString().toLowerCase().compareTo(
                                  (b['nombre'] ?? '')
                                      .toString()
                                      .toLowerCase(),
                                ));

                        // Si tenemos id inicial, sincronizar el nombre
                        if (_selectedSubestablecimientoId != null) {
                          final found = list.firstWhere(
                            (e) => e['id'] == _selectedSubestablecimientoId,
                            orElse: () => {},
                          );
                          if (found.isNotEmpty) {
                            _selectedSubestablecimientoNombre =
                                (found['nombre'] as String?) ?? '';
                          }
                        }

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Subestablecimiento',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: list
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e['id'] as String?,
                                  child: Text((e['nombre'] as String?) ?? ''),
                                ),
                              )
                              .toList(),
                          value: _selectedSubestablecimientoId,
                          onChanged: (value) {
                            if (value == null) return;
                            final seleccionado = list.firstWhere(
                              (e) => e['id'] == value,
                              orElse: () => {},
                            );
                            setState(() {
                              _selectedSubestablecimientoId = value;
                              _selectedSubestablecimientoNombre =
                                  (seleccionado['nombre'] as String?) ?? '';
                            });
                          },
                          validator: (value) => value == null
                              ? 'Seleccione un subestablecimiento'
                              : null,
                          isExpanded: true,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Cliente',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (value.trim().length < 3) {
                          return 'Ingrese un nombre válido (mínimo 3 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _ciController,
                      decoration: InputDecoration(
                        labelText: 'CI / NIT',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El CI/NIT es obligatorio';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Solo se permiten números';
                        }
                        if (value.trim().length < 5) {
                          return 'Ingrese un CI/NIT válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectFecha,
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: darkBlue.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _formatearFecha(),
                              style: TextStyle(
                                color: _fechaEvento == null
                                    ? Colors.grey
                                    : darkBlue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectHora,
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: darkBlue.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _formatearHora(),
                              style: TextStyle(
                                color: _horaEvento == null
                                    ? Colors.grey
                                    : darkBlue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _guardarYContinuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
