// lib/screens/pasos/resumen_final_factura.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ResumenFinalPage extends StatefulWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const ResumenFinalPage({
    super.key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  });

  @override
  State<ResumenFinalPage> createState() => _ResumenFinalPageState();
}

class _ResumenFinalPageState extends State<ResumenFinalPage> {
  final supabase = Supabase.instance.client;

  String? nombreHotel;
  String? logoHotel;
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'No hay usuario logueado';

      final usuarioResponse = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioResponse['id_establecimiento'] as String;

      final establecimientoResponse = await supabase
          .from('establecimientos')
          .select('nombre, logotipo')
          .eq('id', idEstablecimiento)
          .single();

      setState(() {
        nombreHotel = establecimientoResponse['nombre'] as String?;
        logoHotel = establecimientoResponse['logotipo'] as String?;
      });

      final itemsResponse = await supabase
          .from('items_cotizacion')
          .select()
          .eq('id_cotizacion', widget.idCotizacion);

      setState(() {
        items = List<Map<String, dynamic>>.from(itemsResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando datos: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildItem(Map<String, dynamic> item, int index) {
    final detalles = item['detalles'] as Map<String, dynamic>? ?? {};
    String fechaIngreso = detalles['fecha_ingreso'] ?? '-';
    String fechaSalida = detalles['fecha_salida'] ?? '-';

    try {
      fechaIngreso = DateFormat('dd-MM-yyyy').format(DateTime.parse(fechaIngreso));
    } catch (_) {}

    try {
      fechaSalida = DateFormat('dd-MM-yyyy').format(DateTime.parse(fechaSalida));
    } catch (_) {}

    return ListTile(
      leading: Text('${index + 1}'),
      title: Text(item['servicio'] ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingreso: $fechaIngreso'),
          Text('Salida: $fechaSalida'),
          Text('Precio Unitario: Bs ${item['precio_unitario']}'),
        ],
      ),
      trailing: Text('Total: Bs ${item['total']}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreHotel ?? 'Resumen de cotización'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (logoHotel != null && logoHotel!.isNotEmpty)
                        Image.network(
                          logoHotel!,
                          height: 100,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.hotel, size: 100, color: Colors.grey),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        nombreHotel ?? '',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text('Cliente:', style: Theme.of(context).textTheme.titleMedium),
                      Text('Nombre: ${widget.nombreCliente}'),
                      Text('CI: ${widget.ciCliente}'),
                      const Divider(height: 32),
                      Text('Items de la cotización:', style: Theme.of(context).textTheme.titleMedium),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _buildItem(items[index], index),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función en desarrollo')),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar PDF'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función en desarrollo')),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar por correo'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
