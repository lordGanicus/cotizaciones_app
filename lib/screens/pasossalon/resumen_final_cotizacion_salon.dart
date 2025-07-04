import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResumenFinalCotizacionSalonPage extends StatefulWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const ResumenFinalCotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  }) : super(key: key);

  @override
  State<ResumenFinalCotizacionSalonPage> createState() => _ResumenFinalCotizacionSalonPageState();
}

class _ResumenFinalCotizacionSalonPageState extends State<ResumenFinalCotizacionSalonPage> {
  late final SupabaseClient supabase;

  String? nombreHotel;
  String? logoHotel;
  Map<String, dynamic>? cotizacionData;
  List<Map<String, dynamic>> items = [];
  double totalFinal = 0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      final usuarioResp = await supabase
          .from('usuarios')
          .select('id_establecimiento')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioResp['id_establecimiento'];
      if (idEstablecimiento == null) throw 'Establecimiento no encontrado';

      final establecimientoResp = await supabase
          .from('establecimientos')
          .select('nombre, logotipo')
          .eq('id', idEstablecimiento)
          .single();

      nombreHotel = establecimientoResp['nombre'] as String?;
      logoHotel = establecimientoResp['logotipo'] as String?;

      final cotizacionResp = await supabase
          .from('cotizaciones')
          .select()
          .eq('id', widget.idCotizacion)
          .single();

      cotizacionData = cotizacionResp;

      final itemsResp = await supabase
          .from('items_cotizacion')
          .select()
          .eq('id_cotizacion', widget.idCotizacion);

      items = List<Map<String, dynamic>>.from(itemsResp);

      totalFinal = items.fold<double>(0, (prev, item) {
        double totalItem = 0;
        if (item.containsKey('total') && item['total'] != null) {
          final val = item['total'];
          if (val is num) {
            totalItem = val.toDouble();
          }
        }
        if (totalItem == 0) {
          final cantidad = item['cantidad'] ?? 0;
          final precioUnitario = item['precio_unitario'] ?? 0;
          if (precioUnitario is num && cantidad is int) {
            totalItem = precioUnitario.toDouble() * cantidad;
          }
        }
        return prev + totalItem;
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando datos: $e';
        isLoading = false;
      });
    }
  }

  String formatFecha(dynamic fecha) {
    try {
      final dt = DateTime.parse(fecha.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return fecha?.toString() ?? 'N/D';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreHotel ?? 'Resumen Cotización'),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logoHotel != null && logoHotel!.isNotEmpty)
                        Center(
                          child: Image.network(
                            logoHotel!,
                            height: 100,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.business, size: 100),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (nombreHotel != null)
                        Center(
                          child: Text(
                            nombreHotel!,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      const SizedBox(height: 24),

                      Text('La Paz, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                      const SizedBox(height: 4),
                      Text('COT N°: ${widget.idCotizacion}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Señores:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.nombreCliente),
                      Text('CI: ${widget.ciCliente}'),
                      const SizedBox(height: 24),

                      Text('DETALLES DEL EVENTO',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}'),
                      Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}'),
                      const SizedBox(height: 16),

                      Text('🧾 Detalle de la propuesta:',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Colors.grey),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Descripción',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Cantidad',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('P. Unitario',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Total',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...items.map((item) {
                            final desc = item['descripcion'] ?? 'Sin descripción';
                            final cantidad = item['cantidad'] ?? 0;
                            final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();

                            double totalItem = 0;
                            if (item.containsKey('total') && item['total'] != null) {
                              final val = item['total'];
                              if (val is num) {
                                totalItem = val.toDouble();
                              }
                            }
                            if (totalItem == 0 && cantidad is int) {
                              totalItem = precioUnitario * cantidad;
                            }

                            return TableRow(
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(desc.toString())),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(cantidad.toString())),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Bs ${precioUnitario.toStringAsFixed(2)}')),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Bs ${totalItem.toStringAsFixed(2)}')),
                              ],
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Total final: ',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(width: 10),
                          Text('Bs ${totalFinal.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: primaryColor)),
                        ],
                      ),

                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función exportar PDF en desarrollo'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función enviar correo en desarrollo'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar por correo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
