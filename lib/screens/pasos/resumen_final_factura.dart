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
        error = '❌ Error cargando datos: $e';
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

    final total = (item['cantidad'] ?? 0) * (item['precio_unitario'] ?? 0.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(item['servicio'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingreso: $fechaIngreso'),
            Text('Salida: $fechaSalida'),
            Text('Cantidad: ${item['cantidad']}'),
            Text('Precio Unitario: Bs ${item['precio_unitario']}'),
          ],
        ),
        trailing: Text(
          'Bs ${total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreHotel ?? 'Resumen de cotización'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            logoHotel!,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.hotel, size: 100, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        nombreHotel ?? '',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('Cliente:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(widget.nombreCliente),
                            Text('CI/NIT: ${widget.ciCliente}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Items de la cotización',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _buildItem(items[index], index),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función de PDF en desarrollo')),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función de envío en desarrollo')),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar por correo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}