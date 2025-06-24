import 'package:flutter/material.dart';
import 'package:cotizaciones_app/screens/pasos/crear_cotizacion_habitacion_step2.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Agregado

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

  final supabase = Supabase.instance.client; // ✅ Agregado

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
    return Scaffold(
      appBar: AppBar(title: const Text('Paso 1 - Cliente, Tipo y Cantidad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Cotización ID: ${widget.idCotizacion}'),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreClienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente (persona o empresa)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ciClienteController,
              decoration: const InputDecoration(
                labelText: 'CI / NIT (opcional)',
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo de habitación'),
              items: _tipos.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_cantidad > 1) {
                      setState(() => _cantidad--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text('$_cantidad', style: const TextStyle(fontSize: 24)),
                IconButton(
                  onPressed: () {
                    setState(() => _cantidad++);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _tipoSeleccionado == null || _nombreClienteController.text.trim().isEmpty
                  ? null
                  : _guardarClienteYContinuar, // ✅ Actualizado
              child: const Text('Siguiente'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

