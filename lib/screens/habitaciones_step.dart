/*import 'package:flutter/material.dart';
import '../models/habitacion_model.dart';

class HabitacionesStepPage extends StatefulWidget {
  final String nombreCliente;

  const HabitacionesStepPage({
    super.key,
    required this.nombreCliente,
  });

  @override
  State<HabitacionesStepPage> createState() => _HabitacionesStepPageState();
}

class _HabitacionesStepPageState extends State<HabitacionesStepPage> {
  List<HabitacionSeleccionada> habitaciones = [];
  final List<String> tiposHabitacion = [
    'Suite Simple',
    'Suite Doble',
    'Suite Triple',
    'Suite Matrimonial',
    'Suite Ejecutiva',
    'Suite Ejecutiva Matrimonial',
  ];

  void _agregarHabitacion() {
    setState(() {
      habitaciones.add(HabitacionSeleccionada(tipo: tiposHabitacion[0], cantidad: 1));
    });
  }

  void _eliminarHabitacion(int index) {
    setState(() {
      habitaciones.removeAt(index);
    });
  }

  void _continuar() {
    if (habitaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agrega al menos una habitación")),
      );
      return;
    }

    // Aquí luego vamos a pasar al paso 3 con Navigator
    // Navigator.push(context, MaterialPageRoute(...));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paso 2: Selección de habitaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Cliente: ${widget.nombreCliente}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: habitaciones.length,
                itemBuilder: (context, index) {
                  final habitacion = habitaciones[index];
                  return Card(
                    child: ListTile(
                      title: DropdownButtonFormField<String>(
                        value: habitacion.tipo,
                        items: tiposHabitacion.map((tipo) {
                          return DropdownMenuItem(value: tipo, child: Text(tipo));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            habitaciones[index] = HabitacionSeleccionada(
                              tipo: value!,
                              cantidad: habitacion.cantidad,
                            );
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Tipo de habitación'),
                      ),
                      subtitle: TextFormField(
                        initialValue: habitacion.cantidad.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        onChanged: (value) {
                          setState(() {
                            habitaciones[index] = HabitacionSeleccionada(
                              tipo: habitacion.tipo,
                              cantidad: int.tryParse(value) ?? 1,
                            );
                          });
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarHabitacion(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _agregarHabitacion,
              icon: const Icon(Icons.add),
              label: const Text('Agregar habitación'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _continuar,
              child: const Text('Continuar al siguiente paso'),
            ),
          ],
        ),
      ),
    );
  }
}*/