import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  State<ResumenFinalCotizacionSalonPage> createState() =>
      _ResumenFinalCotizacionSalonPageState();
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

        // Validar campo total
        if (item.containsKey('total') && item['total'] != null) {
          final val = item['total'];
          if (val is num) {
            totalItem = val.toDouble();
          }
        }

        // Si total no existe, calcular cantidad * precio unitario
        if (totalItem == 0) {
          final cantidadRaw = item['cantidad'];
          final precioUnitarioRaw = item['precio_unitario'];

          final cantidad = cantidadRaw is int
              ? cantidadRaw
              : int.tryParse(cantidadRaw?.toString() ?? '') ?? 0;
          final precioUnitario = precioUnitarioRaw is num
              ? precioUnitarioRaw.toDouble()
              : double.tryParse(precioUnitarioRaw?.toString() ?? '') ?? 0.0;

          totalItem = cantidad * precioUnitario;
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

  Future<void> _exportarPdf() async {
    final pdf = pw.Document();
    final fechaActual = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pw.ImageProvider? logoImage;
    if (logoHotel != null && logoHotel!.isNotEmpty) {
      try {
        logoImage = await networkImage(logoHotel!);
      } catch (_) {}
    }

    final itemsTable = items.map((item) {
      final desc = item['descripcion'] ?? 'Sin descripción';
      final cantidadRaw = item['cantidad'];
      final precioUnitarioRaw = item['precio_unitario'];

      final cantidad = cantidadRaw is int
          ? cantidadRaw
          : int.tryParse(cantidadRaw?.toString() ?? '') ?? 0;
      final precioUnitario = precioUnitarioRaw is num
          ? precioUnitarioRaw.toDouble()
          : double.tryParse(precioUnitarioRaw?.toString() ?? '') ?? 0.0;

      double totalItem = 0;
      if (item.containsKey('total') && item['total'] != null) {
        final val = item['total'];
        if (val is num) {
          totalItem = val.toDouble();
        }
      }
      if (totalItem == 0) {
        totalItem = precioUnitario * cantidad;
      }

      return [
        desc.toString(),
        cantidad.toString(),
        'Bs ${precioUnitario.toStringAsFixed(2)}',
        'Bs ${totalItem.toStringAsFixed(2)}',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          if (logoImage != null)
            pw.Center(child: pw.Image(logoImage, height: 100)),
          if (nombreHotel != null)
            pw.Center(
              child: pw.Text(nombreHotel!,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
          pw.SizedBox(height: 12),
          pw.Text('La Paz, $fechaActual'),
          pw.Text('COT N°: ${widget.idCotizacion}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Señores:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(widget.nombreCliente),
          pw.Text('CI: ${widget.ciCliente}'),
          pw.SizedBox(height: 24),
          pw.Text('DETALLES DEL EVENTO',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}'),
          pw.Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}'),
          pw.SizedBox(height: 16),
          pw.Text('🧾 Detalle de la propuesta:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Descripción', 'Cantidad', 'P. Unitario', 'Total'],
            data: itemsTable,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey400),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total final: Bs ${totalFinal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          )
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cotizacion_salon_${widget.idCotizacion}.pdf',
    );
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
                      const Text('Señores:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.nombreCliente),
                      Text('CI: ${widget.ciCliente}'),
                      const SizedBox(height: 24),
                      Text('DETALLES DEL EVENTO', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}'),
                      Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}'),
                      const SizedBox(height: 16),
                      const Text('🧾 Detalle de la propuesta:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                            final cantidadRaw = item['cantidad'];
                            final precioUnitarioRaw = item['precio_unitario'];

                            final cantidad = cantidadRaw is int
                                ? cantidadRaw
                                : int.tryParse(cantidadRaw?.toString() ?? '') ?? 0;
                            final precioUnitario = precioUnitarioRaw is num
                                ? precioUnitarioRaw.toDouble()
                                : double.tryParse(precioUnitarioRaw?.toString() ?? '') ?? 0.0;

                            double totalItem = 0;
                            if (item.containsKey('total') && item['total'] != null) {
                              final val = item['total'];
                              if (val is num) {
                                totalItem = val.toDouble();
                              }
                            }
                            if (totalItem == 0) {
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
                        onPressed: _exportarPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
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
