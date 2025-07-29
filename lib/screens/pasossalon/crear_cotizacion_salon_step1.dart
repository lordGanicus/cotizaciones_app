import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotizacion_salon.dart';
import '../../providers/cotizacion_salon_provider.dart';
import 'crear_cotizacion_salon_step2.dart';

class Paso1CotizacionSalonPage extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;

  const Paso1CotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
  }) : super(key: key);

  @override
  ConsumerState<Paso1CotizacionSalonPage> createState() =>
      _Paso1CotizacionSalonPageState();
}

class _Paso1CotizacionSalonPageState extends ConsumerState<Paso1CotizacionSalonPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _tipoEventoController = TextEditingController();
  final TextEditingController _participantesController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

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

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _tipoEventoController.dispose();
    _participantesController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaEvento(BuildContext context) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaEvento = fecha;
      });
    }
  }

  // Nuevo método para seleccionar hora, con formato 24h fijo y picker separado:
  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final ahora = TimeOfDay.now();
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? (_horaInicio ?? ahora) : (_horaFin ?? ahora),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox(),
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
          const SnackBar(content: Text('Por favor selecciona fecha y horarios')),
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
          const SnackBar(content: Text('La hora fin debe ser posterior a la hora inicio')),
        );
        return;
      }

      final participantes = int.tryParse(_participantesController.text) ?? 0;
      final precioSalon = double.tryParse(_precioController.text) ?? 0.0;

      final notifier = ref.read(cotizacionSalonProvider.notifier);
      final listaSalones = ref.read(cotizacionSalonProvider);

      if (listaSalones.isEmpty) {
        notifier.agregarSalon(
          ItemSalon(
            idUsuario: widget.idUsuario,
            idSalon: '',
            nombreSalon: '',
            capacidad: 0,
            descripcion: '',
            nombreCliente: _nombreController.text.trim(),
            ciCliente: _ciController.text.trim(),
            tipoEvento: _tipoEventoController.text.trim(),
            fechaEvento: _fechaEvento!,
            horaInicio: inicio,
            horaFin: fin,
            participantes: participantes,
            tipoArmado: _tipoArmado,
            precioSalonTotal: precioSalon,
            serviciosSeleccionados: [],
            itemsAdicionales: [],
          ),
        );
      } else {
        final salonActual = listaSalones[0];
        final salonActualizado = salonActual.copyWith(
          nombreCliente: _nombreController.text.trim(),
          ciCliente: _ciController.text.trim(),
          tipoEvento: _tipoEventoController.text.trim(),
          fechaEvento: _fechaEvento!,
          horaInicio: inicio,
          horaFin: fin,
          participantes: participantes,
          tipoArmado: _tipoArmado,
          precioSalonTotal: precioSalon,
        );
        notifier.actualizarSalon(0, salonActualizado);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Paso2CotizacionSalonPage(
            idCotizacion: widget.idCotizacion,
            idEstablecimiento: widget.idEstablecimiento,
            idUsuario: widget.idUsuario,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 1: Datos del evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos del cliente', style: titleStyle),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ciController,
                decoration: const InputDecoration(
                  labelText: 'CI o NIT',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              Text('Detalles del evento', style: titleStyle),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoEventoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _seleccionarFechaEvento(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_fechaEvento == null
                          ? 'Seleccionar fecha'
                          : '${_fechaEvento!.day.toString().padLeft(2, '0')}/${_fechaEvento!.month.toString().padLeft(2, '0')}/${_fechaEvento!.year}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _seleccionarHora(context, true),
                      icon: const Icon(Icons.access_time),
                      label: Text(_horaInicio == null
                          ? 'Hora inicio'
                          : 'Desde: ${_horaInicio!.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _seleccionarHora(context, false),
                      icon: const Icon(Icons.access_time),
                      label: Text(_horaFin == null
                          ? 'Hora fin'
                          : 'Hasta: ${_horaFin!.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _participantesController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de participantes',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoArmado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de armado',
                  border: OutlineInputBorder(),
                ),
                items: _tiposArmado
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
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
                decoration: const InputDecoration(
                  labelText: 'Precio total del salón (Bs)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _guardarYContinuar,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
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
