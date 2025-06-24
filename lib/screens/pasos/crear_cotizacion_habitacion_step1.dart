import 'package:flutter/material.dart';
import 'package:cotizaciones_app/screens/pasos/crear_cotizacion_habitacion_step2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasoCantidadPage extends StatefulWidget {
  final String idCotizacion;

  const PasoCantidadPage({super.key, required this.idCotizacion});

  @override
  State<PasoCantidadPage> createState() => _PasoCantidadPageState();
}

class _PasoCantidadPageState extends State<PasoCantidadPage> {
  final _tipos = [
    'Suite simple',
    'Doble',
    'Triple',
    'Matrimonial',
    'Ejecutiva',
    'Ejecutiva matrimonial',
  ];

  String? _tipoSeleccionado;
  int _cantidad = 1;

  final TextEditingController _nombreClienteController = TextEditingController();
  final TextEditingController _ciClienteController = TextEditingController();

  final supabase = Supabase.instance.client;

  Future<void> _guardarClienteYContinuar() async {
    final nombre = _nombreClienteController.text.trim();
    final ci = _ciClienteController.text.trim();

    if (nombre.isEmpty) return;

    try {
      await supabase.from('clientes').upsert({
        'ci': ci,
        'nombre_completo': nombre,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasoFechaPage(
            idCotizacion: widget.idCotizacion,
            cantidad: _cantidad,
            tipoHabitacion: _tipoSeleccionado!,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cotización ID: ${widget.idCotizacion}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            TextField(
              controller: _nombreClienteController,
              decoration: InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _ciClienteController,
              decoration: InputDecoration(
                labelText: 'CI / NIT (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Tipo de habitación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.hotel_outlined),
              ),
              items: _tipos
                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                  .toList(),
              onChanged: (value) {
                setState(() => _tipoSeleccionado = value);
              },
            ),
            const SizedBox(height: 24),

            Text('Cantidad de habitaciones', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () {
                    if (_cantidad > 1) {
                      setState(() => _cantidad--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$_cantidad', style: const TextStyle(fontSize: 24)),
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _cantidad++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _tipoSeleccionado == null || _nombreClienteController.text.trim().isEmpty
                  ? null
                  : _guardarClienteYContinuar,
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
