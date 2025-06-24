import 'package:flutter/material.dart';
import 'package:cotizaciones_app/screens/pasos/crear_cotizacion_habitacion_step3.dart';

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

  @override
  Widget build(BuildContext context) {
    final fechaOk = _fechaIngreso != null && _fechaSalida != null && cantidadNoches > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 2: Fechas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _seleccionarFechaIngreso,
              child: Text(_fechaIngreso == null
                  ? 'Seleccionar Fecha de Ingreso'
                  : 'Ingreso: ${_fechaIngreso!.toLocal()}'.split(' ')[0]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fechaIngreso == null ? null : _seleccionarFechaSalida,
              child: Text(_fechaSalida == null
                  ? 'Seleccionar Fecha de Salida'
                  : 'Salida: ${_fechaSalida!.toLocal()}'.split(' ')[0]),
            ),
            if (fechaOk)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('Cantidad de noches: $cantidadNoches',
                    style: const TextStyle(fontSize: 16)),
              ),
            const Spacer(),
            ElevatedButton(
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
              child: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}