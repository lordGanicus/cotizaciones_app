import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistorialCotizacionesPage extends StatefulWidget {
  const HistorialCotizacionesPage({super.key});

  @override
  State<HistorialCotizacionesPage> createState() => _HistorialCotizacionesPageState();
}

class _HistorialCotizacionesPageState extends State<HistorialCotizacionesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> historialClientes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorialClientes();
  }

  Future<void> _cargarHistorialClientes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Implementación EXACTA de la consulta SQL proporcionada
      final response = await supabase.from('cotizaciones').select('''
        clientes:clientes(nombre_completo, ci),
        fecha_creacion,
        items_cotizacion(total)
      ''').eq('id_usuario', user.id);

      // Procesamiento según la consulta SQL
      final Map<String, Map<String, dynamic>> clientesMap = {};

      for (var cotizacion in response) {
        final cliente = cotizacion['clientes'];
        if (cliente != null) {
          final ci = cliente['ci'] ?? 'sin_ci';
          if (!clientesMap.containsKey(ci)) {
            clientesMap[ci] = {
              'nombre_cliente': cliente['nombre_completo'],
              'ci_cliente': ci,
              'primera_fecha': cotizacion['fecha_creacion'],
              'ultima_fecha': cotizacion['fecha_creacion'],
              'total_acumulado': 0.0,
            };
          }

          final fechaCreacion = DateTime.parse(cotizacion['fecha_creacion']);
          final primeraFecha = DateTime.parse(clientesMap[ci]!['primera_fecha']);
          final ultimaFecha = DateTime.parse(clientesMap[ci]!['ultima_fecha']);

          if (fechaCreacion.isBefore(primeraFecha)) {
            clientesMap[ci]!['primera_fecha'] = cotizacion['fecha_creacion'];
          }
          if (fechaCreacion.isAfter(ultimaFecha)) {
            clientesMap[ci]!['ultima_fecha'] = cotizacion['fecha_creacion'];
          }

          if (cotizacion['items_cotizacion'] != null) {
            for (var item in cotizacion['items_cotizacion']) {
              clientesMap[ci]!['total_acumulado'] += item['total'] ?? 0;
            }
          }
        }
      }

      setState(() {
        historialClientes = clientesMap.values.toList()
          ..sort((a, b) => DateTime.parse(b['ultima_fecha'])
              .compareTo(DateTime.parse(a['ultima_fecha'])));

        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar historial: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _mostrarDetalleCliente(Map<String, dynamic> cliente) async {
    final user = supabase.auth.currentUser;
    if (user == null || !mounted) return;

    try {
      final response = await supabase.from('cotizaciones').select('''
        id, fecha_creacion, estado, total,
        items_cotizacion(servicio, descripcion, unidad, cantidad, precio_unitario, total, tipo)
      ''').eq('id_usuario', user.id)
         .eq('clientes.ci', cliente['ci_cliente'])
         .order('fecha_creacion', ascending: false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cotizaciones de ${cliente['nombre_cliente']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CI: ${cliente['ci_cliente']}'),
                  const SizedBox(height: 10),
                  ...response.map((cotizacion) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text('Fecha: ${_formatearFecha(cotizacion['fecha_creacion'])}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Estado: ${cotizacion['estado']}'),
                        Text('Total: Bs. ${cotizacion['total']?.toStringAsFixed(2) ?? '0.00'}'),
                        const SizedBox(height: 8),
                        ...(cotizacion['items_cotizacion'] as List).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('- ${item['servicio'] ?? 'Sin nombre'} (${_formatearTipo(item['tipo'])})'),
                                if (item['descripcion'] != null) 
                                  Text('  Descripción: ${item['descripcion']}'),
                                Text('  Cantidad: ${item['cantidad']} ${item['unidad']}'),
                                Text('  Precio: Bs. ${item['precio_unitario']?.toStringAsFixed(2) ?? '0.00'}'),
                                Text('  Total: Bs. ${item['total']?.toStringAsFixed(2) ?? '0.00'}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar detalles')),
        );
      }
    }
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (_) {
      return fechaIso.split('T').first;
    }
  }

  String _formatearTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'comida': return 'Restaurante';
      case 'habitacion': return 'Habitación';
      case 'salon': return 'Salón';
      default: return tipo ?? 'General';
    }
  }

  Widget _buildClienteItem(Map<String, dynamic> cliente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleCliente(cliente),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente['nombre_cliente'] ?? 'N/D',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CI: ${cliente['ci_cliente'] ?? 'N/D'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Bs. ${cliente['total_acumulado']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B894),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Primera: ${_formatearFecha(cliente['primera_fecha'])}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Última: ${_formatearFecha(cliente['ultima_fecha'])}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorialClientes,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historialClientes.isEmpty
              ? const Center(child: Text('No hay historial disponible'))
              : ListView.builder(
                  itemCount: historialClientes.length,
                  itemBuilder: (_, index) => _buildClienteItem(historialClientes[index]),
                ),
    );
  }
}