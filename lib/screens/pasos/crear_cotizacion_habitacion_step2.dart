import 'package:flutter/material.dart';
import 'package:cotizaciones_app/screens/pasos/crear_cotizacion_habitacion_step3.dart';
import 'package:intl/intl.dart'; // Para dar formato bonito a las fechas

class PasoFechaPage extends StatefulWidget {
  final String idCotizacion;
  final int cantidad;
  final String tipoHabitacion;
  final String nombreCliente;
  final String ciCliente;

  const PasoFechaPage({
    super.key,
    required this.idCotizacion,
    required this.cantidad,
    required this.tipoHabitacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  @override
  State<PasoFechaPage> createState() => _PasoFechaPageState();
}

class _PasoFechaPageState extends State<PasoFechaPage> {
  DateTime? _fechaIngreso;
  DateTime? _fechaSalida;

  Future<void> _seleccionarFechaIngreso() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _fechaIngreso = picked;
        if (_fechaSalida != null && _fechaSalida!.isBefore(picked)) {
          _fechaSalida = null;
        }
      });
    }
  }

  Future<void> _seleccionarFechaSalida() async {
    if (_fechaIngreso == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSalida ?? _fechaIngreso!.add(const Duration(days: 1)),
      firstDate: _fechaIngreso!,
      lastDate: DateTime(_fechaIngreso!.year + 2),
    );
    if (picked != null) {
      setState(() => _fechaSalida = picked);
    }
  }

  int get cantidadNoches {
    if (_fechaIngreso != null && _fechaSalida != null) {
      return _fechaSalida!.difference(_fechaIngreso!).inDays;
    }
    return 0;
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final fechaOk = _fechaIngreso != null && _fechaSalida != null && cantidadNoches > 0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso 2 - Fechas de Hospedaje'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha de ingreso'),
              subtitle: Text(
                _fechaIngreso != null ? _formatearFecha(_fechaIngreso!) : 'No seleccionada',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: _seleccionarFechaIngreso,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de salida'),
              subtitle: Text(
                _fechaSalida != null ? _formatearFecha(_fechaSalida!) : 'No seleccionada',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: _fechaIngreso == null ? null : _seleccionarFechaSalida,
              ),
            ),
            const SizedBox(height: 16),
            if (fechaOk)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.night_shelter_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Cantidad de noches: $cantidadNoches',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: fechaOk
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PasoResumenPage(
                            idCotizacion: widget.idCotizacion,
                            cantidad: widget.cantidad,
                            tipoHabitacion: widget.tipoHabitacion,
                            fechaIngreso: _fechaIngreso!,
                            fechaSalida: _fechaSalida!,
                            nombreCliente: widget.nombreCliente,
                            ciCliente: widget.ciCliente,
                          ),
                        ),
                      );
                    }
                  : null,
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
          ],
        ),
      ),
    );
  }
}
