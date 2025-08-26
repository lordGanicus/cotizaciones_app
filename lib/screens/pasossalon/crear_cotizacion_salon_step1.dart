import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../models/cotizacion_salon.dart';
import '../../models/salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import '../../providers/salones_provider.dart';
import 'crear_cotizacion_salon_step2.dart';
import '../../providers/pestablecimiento.dart';

class Paso1CotizacionSalonPage extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const Paso1CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  @override
  ConsumerState<Paso1CotizacionSalonPage> createState() =>
      _Paso1CotizacionSalonPageState();
}

class _Paso1CotizacionSalonPageState
    extends ConsumerState<Paso1CotizacionSalonPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();
  final _tipoEventoController = TextEditingController();
  final _participantesController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime? _fechaEvento;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  String _tipoArmado = 'Auditorio';
  final List<String> _tiposArmado = [
    'Auditorio',
    'Escuela',
    'Mesas redondas',
    'En U',
    'A definir',
  ];

  Salon? _salonSeleccionado;

  // Colores definidos
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color errorColor = Colors.redAccent;
  final Color cardBackground = Colors.white;
  final Color textColor = const Color(0xFF2D4059);
  final Color secondaryTextColor = const Color(0xFF555555);

  // Expresiones regulares para validación
  final RegExp _nombreRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  final RegExp _tipoEventoRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\-]+$');

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _tipoEventoController.dispose();
    _participantesController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Función para capitalizar cada palabra del nombre
  String _capitalizarNombreCompleto(String nombre) {
    return nombre
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((palabra) =>
            palabra[0].toUpperCase() + palabra.substring(1).toLowerCase())
        .join(' ');
  }

  // Función para capitalizar el tipo de evento
  String _capitalizarTipoEvento(String tipoEvento) {
    return tipoEvento
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((palabra) =>
            palabra[0].toUpperCase() + palabra.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _seleccionarFechaEvento(BuildContext context) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'), // Configurar español
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
    if (fecha != null) {
      setState(() {
        _fechaEvento = fecha;
      });
    }
  }

  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final ahora = TimeOfDay.now();
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? (_horaInicio ?? ahora) : (_horaFin ?? ahora),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryGreen,
                onPrimary: Colors.white,
                onSurface: darkBlue,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (horaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = horaSeleccionada;
        } else {
          _horaFin = horaSeleccionada;
        }
      });
    }
  }

  void _guardarYContinuar() {
    if (_formKey.currentState!.validate()) {
      if (_fechaEvento == null || _horaInicio == null || _horaFin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor selecciona fecha y horarios'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }
      if (_salonSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor selecciona un salón'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      final inicio = DateTime(
        _fechaEvento!.year,
        _fechaEvento!.month,
        _fechaEvento!.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );
      final fin = DateTime(
        _fechaEvento!.year,
        _fechaEvento!.month,
        _fechaEvento!.day,
        _horaFin!.hour,
        _horaFin!.minute,
      );

      if (!fin.isAfter(inicio)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('La hora fin debe ser posterior a la hora inicio'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      // Validar que el evento dure al menos 30 minutos
      if (fin.difference(inicio).inMinutes < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('La duración mínima del evento debe ser de 30 minutos'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      // Validar capacidad del salón
      final participantes = int.tryParse(_participantesController.text) ?? 0;
      if (participantes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La cantidad de participantes debe ser mayor a cero'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      if (_salonSeleccionado!.capacidadSillas < participantes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'La capacidad del salón (${_salonSeleccionado!.capacidadSillas}) es menor a los participantes ($participantes)'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      final precioSalon = double.tryParse(_precioController.text) ?? 0.0;
      if (precioSalon <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El precio total del salón debe ser mayor a cero'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      // Capitalizar el nombre y tipo de evento antes de guardar
      final nombreCliente = _capitalizarNombreCompleto(_nombreController.text);
      final tipoEvento = _capitalizarTipoEvento(_tipoEventoController.text);
      final ciCliente = _ciController.text.trim();

      final notifier = ref.read(cotizacionSalonProvider.notifier);
      final listaSalones = ref.read(cotizacionSalonProvider);

      final nuevoItemSalon = ItemSalon(
        idUsuario: widget.idUsuario,
        idSalon: _salonSeleccionado!.id,
        nombreSalon: _salonSeleccionado!.nombre,
        capacidad: _salonSeleccionado!.capacidadSillas,
        descripcion: _salonSeleccionado!.descripcion ?? '',
        nombreCliente: nombreCliente,
        ciCliente: ciCliente,
        tipoEvento: tipoEvento,
        fechaEvento: _fechaEvento!,
        horaInicio: inicio,
        horaFin: fin,
        participantes: participantes,
        tipoArmado: _tipoArmado,
        precioSalonTotal: precioSalon,
        serviciosSeleccionados: [],
        itemsAdicionales: [],
        idSubestablecimiento: _salonSeleccionado!.idSubestablecimiento,
      );

      if (listaSalones.isEmpty) {
        notifier.agregarSalon(nuevoItemSalon);
      } else {
        notifier.actualizarSalon(0, nuevoItemSalon);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Paso2CotizacionSalonPage(
            idCotizacion: widget.idCotizacion,
            idEstablecimiento: widget.idEstablecimiento,
            idUsuario: widget.idUsuario,
            idSubestablecimiento: _salonSeleccionado!.idSubestablecimiento,
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: darkBlue.withOpacity(0.8)),
      floatingLabelStyle: TextStyle(color: primaryGreen),
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkBlue,
        ),
      ),
    );
  }

  Widget _buildDateTimeButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cardBackground,
        foregroundColor: darkBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: darkBlue.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primaryGreen),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: darkBlue.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_drop_down, color: darkBlue.withOpacity(0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar diferente provider según si idSubestablecimiento es null o no
    final salonesAsync = widget.idSubestablecimiento == null
        ? ref.watch(salonesPorEstablecimientoProvider(widget.idEstablecimiento))
        : ref.watch(
            salonesPorSubestablecimientoProvider(widget.idSubestablecimiento!));

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Cotización de salón - Paso 1'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección Selección de Salón
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: darkBlue.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Selección de Salón'),
                      const SizedBox(height: 12),
                      salonesAsync.when(
                        data: (salones) {
                          if (salones.isEmpty) {
                            return Text(
                              'No hay salones disponibles',
                              style: TextStyle(color: secondaryTextColor),
                            );
                          }
                          if (_salonSeleccionado == null && salones.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _salonSeleccionado = salones.first;
                              });
                            });
                          }

                          return DropdownButtonFormField<Salon>(
                            value: _salonSeleccionado,
                            items: salones
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.nombre,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (salon) {
                              setState(() {
                                _salonSeleccionado = salon;
                              });
                            },
                            decoration: _inputDecoration('Salón'),
                            dropdownColor: cardBackground,
                            style: TextStyle(color: textColor),
                            validator: (value) =>
                                value == null ? 'Seleccione un salón' : null,
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        ),
                        error: (e, st) => Text(
                          'Error al cargar salones: $e',
                          style: TextStyle(color: errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sección Datos del Cliente
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: darkBlue.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Datos del Cliente'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreController,
                        decoration: _inputDecoration('Nombre del cliente'),
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (!_nombreRegExp.hasMatch(value.trim())) {
                            return 'Solo se permiten letras y espacios';
                          }
                          if (value.trim().split(' ').length < 2) {
                            return 'Ingrese al menos un nombre y un apellido';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        onChanged: (val) {
                          final textoCapitalizado = _capitalizarNombreCompleto(val);
                          if (val != textoCapitalizado) {
                            final cursorPos = _nombreController.selection;
                            _nombreController.value = TextEditingValue(
                              text: textoCapitalizado,
                              selection: cursorPos,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ciController,
                        decoration: _inputDecoration('CI o NIT'),
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: false, decimal: false),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El CI o NIT es obligatorio';
                          }
                          if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                            return 'Solo se permiten números en CI o NIT';
                          }
                          if (value.trim().length < 4) {
                            return 'El CI/NIT debe tener al menos 4 dígitos';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sección Detalles del Evento
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: darkBlue.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Detalles del Evento'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tipoEventoController,
                        decoration: _inputDecoration('Tipo de evento'),
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El tipo de evento es obligatorio';
                          }
                          if (!_tipoEventoRegExp.hasMatch(value.trim())) {
                            return 'Solo se permiten letras, espacios y guiones';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\-]')),
                        ],
                        onChanged: (val) {
                          final textoCapitalizado = _capitalizarTipoEvento(val);
                          if (val != textoCapitalizado) {
                            final cursorPos = _tipoEventoController.selection;
                            _tipoEventoController.value = TextEditingValue(
                              text: textoCapitalizado,
                              selection: cursorPos,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeButton(
                        _fechaEvento == null
                            ? 'Seleccionar fecha'
                            : '${_fechaEvento!.day.toString().padLeft(2, '0')}/${_fechaEvento!.month.toString().padLeft(2, '0')}/${_fechaEvento!.year}',
                        Icons.calendar_today,
                        () => _seleccionarFechaEvento(context),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTimeButton(
                              _horaInicio == null
                                  ? 'Hora inicio'
                                  : _horaInicio!.format(context),
                              Icons.access_time,
                              () => _seleccionarHora(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateTimeButton(
                              _horaFin == null
                                  ? 'Hora fin'
                                  : _horaFin!.format(context),
                              Icons.access_time,
                              () => _seleccionarHora(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _participantesController,
                        decoration:
                            _inputDecoration('Cantidad de participantes'),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La cantidad de participantes es obligatoria';
                          }
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Ingrese una cantidad válida mayor a cero';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _tipoArmado,
                        decoration: _inputDecoration('Tipo de armado'),
                        dropdownColor: cardBackground,
                        style: TextStyle(color: textColor),
                        items: _tiposArmado
                            .map((tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo,
                                      style: TextStyle(color: textColor)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _tipoArmado = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _precioController,
                        decoration: _inputDecoration(
                          'Precio total del salón (Bs)',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              'Bs',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          final precio = double.tryParse(value.trim());
                          if (precio == null || precio <= 0) {
                            return 'Ingrese un precio válido mayor a cero';
                          }
                          if (precio > 100000) {
                            return 'El precio no puede exceder Bs 100,000';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Botón Siguiente
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarYContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continuar', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}