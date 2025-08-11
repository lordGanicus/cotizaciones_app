import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para filtros
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/cotizacion_comida_provider.dart';
import '../../screens/pasoscomida/crear_cotizacion_comida_step2.dart';

class CrearCotizacionComidaStep1 extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const CrearCotizacionComidaStep1({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
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
  List<Map<String, dynamic>> _subestablecimientos = [];
  bool _isLoadingSubestablecimientos = true;

  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _fetchSubestablecimientos();
  }

  Future<void> _fetchSubestablecimientos() async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .from('subestablecimientos')
          .select('id, nombre')
          .eq('id_establecimiento', widget.idEstablecimiento)
          .order('nombre', ascending: true) as List<dynamic>;

      setState(() {
        _subestablecimientos = data
            .map((e) => {
                  'id': e['id'] as String,
                  'nombre': e['nombre'] as String,
                })
            .toList();
        _isLoadingSubestablecimientos = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubestablecimientos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar subestablecimientos: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
      setState(() {
        _fechaEvento = picked;
      });
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
      setState(() {
        _horaEvento = picked;
      });
    }
  }

  bool _validarNombre(String nombre) {
    final regex = RegExp(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*$');
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

      // Capitalizar el nombre completo:
      String nombre = _nombreController.text.trim();
      nombre = nombre
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');

      if (!_validarNombre(nombre)) {
        _showError(
            'Ingrese un nombre válido (solo letras y espacios, con mayúscula inicial en cada palabra)');
        return;
      }

      final ci = _ciController.text.trim();

      if (ci.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(ci)) {
        _showError('El CI/NIT solo puede contener números');
        return;
      }

      final notifier = ref.read(cotizacionComidaProvider.notifier);

      notifier.setCliente(nombre: nombre, ci: ci);
      notifier.setIds(
        idCotizacion: widget.idCotizacion,
        idEstablecimiento: widget.idEstablecimiento,
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
            idEstablecimiento: widget.idEstablecimiento,
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
      body: _isLoadingSubestablecimientos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Subestablecimiento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _subestablecimientos
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e['id'],
                              child: Text(e['nombre']),
                            ),
                          )
                          .toList(),
                      value: _selectedSubestablecimientoId,
                      onChanged: (value) {
                        if (value == null) return;
                        final seleccionado = _subestablecimientos.firstWhere(
                          (e) => e['id'] == value,
                          orElse: () => <String, String>{'nombre': ''},
                        );
                        setState(() {
                          _selectedSubestablecimientoId = value;
                          _selectedSubestablecimientoNombre =
                              seleccionado['nombre'] ?? '';
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccione un subestablecimiento' : null,
                      isExpanded: true,
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
                            RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
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
                              side: BorderSide(color: darkBlue.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _formatearFecha(),
                              style: TextStyle(
                                color:
                                    _fechaEvento == null ? Colors.grey : darkBlue,
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
                              side: BorderSide(color: darkBlue.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _formatearHora(),
                              style: TextStyle(
                                color:
                                    _horaEvento == null ? Colors.grey : darkBlue,
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
