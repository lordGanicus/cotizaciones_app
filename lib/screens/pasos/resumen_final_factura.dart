import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';

class ResumenFinalCotizacionHabitacionPage extends StatefulWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const ResumenFinalCotizacionHabitacionPage({
    Key? key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  }) : super(key: key);

  @override
  State<ResumenFinalCotizacionHabitacionPage> createState() => _ResumenFinalCotizacionHabitacionPageState();
}

class _ResumenFinalCotizacionHabitacionPageState extends State<ResumenFinalCotizacionHabitacionPage> {
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

      totalFinal = 0;
      for (var item in items) {
        final detalles = item['detalles'] ?? {};
        final cantidad = item['cantidad'] ?? 0;
        final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();
        final noches = detalles['cantidad_noches'] ?? 1;
        final subtotal = precioUnitario * cantidad * noches;
        totalFinal += subtotal;
      }

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

 Future<void> _generatePDF() async {
  final pdf = pw.Document();

  pw.MemoryImage? logoBytes;

  // Cargar la imagen antes de crear el documento
  if (logoHotel != null && logoHotel!.isNotEmpty) {
    try {
      final bytes = await _networkImageToBytes(logoHotel!);
      logoBytes = pw.MemoryImage(bytes);
    } catch (_) {
      // Puedes manejar el error o dejar el logo como null
      logoBytes = null;
    }
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoBytes != null)
              pw.Center(
                child: pw.Image(logoBytes, height: 80),
              ),
            pw.SizedBox(height: 12),
            if (nombreHotel != null)
              pw.Center(
                child: pw.Text(
                  nombreHotel!,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.SizedBox(height: 24),
            pw.Text('La Paz, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
            pw.Text('COT N°: ${widget.idCotizacion}', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Señores:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(widget.nombreCliente),
            pw.Text('CI / NIT: ${widget.ciCliente}'),
            pw.SizedBox(height: 24),
            pw.Text('DETALLES DEL EVENTO', 
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}'),
            pw.Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}'),
            pw.SizedBox(height: 16),
            pw.Text('🧾 Detalles de la cotizacion:', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(2),
                6: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Habitación'),
                    _cell('Ingreso'),
                    _cell('Salida'),
                    _cell('Cantidad'),
                    _cell('Noches'),
                    _cell('P. Unitario'),
                    _cell('Subtotal'),
                  ],
                ),
                ...items.map((item) {
                  final detalles = item['detalles'] ?? {};
                  final nombreHabitacion = detalles['nombre_habitacion'] ?? 'Sin nombre';
                  final cantidad = detalles['cantidad'] ?? 0;
                  final fechaIngreso = detalles['fecha_ingreso'] ?? '';
                  final fechaSalida = detalles['fecha_salida'] ?? '';
                  final noches = detalles['cantidad_noches'] ?? 0;
                  final tarifa = (detalles['tarifa'] ?? 0).toDouble();
                  final subtotal = (detalles['subtotal'] ?? 0).toDouble();

                  return pw.TableRow(
                    children: [
                      _cell(nombreHabitacion.toString()),
                      _cell(formatFecha(fechaIngreso)),
                      _cell(formatFecha(fechaSalida)),
                      _cell(cantidad.toString()),
                      _cell(noches.toString()),
                      _cell('Bs ${tarifa.toStringAsFixed(2)}'),
                      _cell('Bs ${subtotal.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total final: ', 
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 10),
                pw.Text('Bs ${totalFinal.toStringAsFixed(2)}', 
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue)),
              ],
            ),
          ],
        );
      },
    ),
  );

  // Mostrar el diálogo de impresión/guardado
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

// Extra: función para reutilizar celdas con padding
pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
  );
}

  Future<Uint8List> _networkImageToBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to load image');
    } catch (e) {
      throw Exception('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreHotel ?? 'Resumen Cotización'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _generatePDF,
            tooltip: 'Generar PDF',
          ),
        ],
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
                            errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 100),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (nombreHotel != null)
                        Center(
                          child: Text(
                            nombreHotel!,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('La Paz, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text('COT N°: ${widget.idCotizacion}', 
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Señores:', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.nombreCliente, style: textTheme.bodyLarge),
                      Text('CI: ${widget.ciCliente}', style: textTheme.bodyLarge),
                      const SizedBox(height: 24),
                      Text('DETALLES DEL EVENTO', 
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}',
                          style: textTheme.bodyLarge),
                      Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}',
                          style: textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      Text('🧾 Detalle de la propuesta:', 
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Tabla mejorada
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DataTable(
                            columnSpacing: 20,
                            dataRowHeight: 48,
                            headingRowHeight: 48,
                            horizontalMargin: 12,
                            columns: [
                              DataColumn(
                                label: Text('Habitación', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Ingreso', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Salida', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Cantidad', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Noches', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('P. Unitario', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Subtotal', 
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                            rows: items.map((item) {
                              final detalles = item['detalles'] ?? {};
                              final nombreHabitacion = detalles['nombre_habitacion'] ?? 'Sin nombre';
                              final cantidad = detalles['cantidad'] ?? 0;
                              final fechaIngreso = detalles['fecha_ingreso'] ?? '';
                              final fechaSalida = detalles['fecha_salida'] ?? '';
                              final noches = detalles['cantidad_noches'] ?? 0;
                              final tarifa = (detalles['tarifa'] ?? 0).toDouble();
                              final subtotal = (detalles['subtotal'] ?? 0).toDouble();

                              return DataRow(
                                cells: [
                                  DataCell(Text(nombreHabitacion.toString(),
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text(formatFecha(fechaIngreso),
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text(formatFecha(fechaSalida),
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text(cantidad.toString(),
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text(noches.toString(),
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text('Bs ${tarifa.toStringAsFixed(2)}',
                                      style: textTheme.bodyMedium)),
                                  DataCell(Text('Bs ${subtotal.toStringAsFixed(2)}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ))),
                                ],
                              );
                            }).toList(),
                            headingRowColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) => primaryColor,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total final:', 
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                            Text('Bs ${totalFinal.toStringAsFixed(2)}', 
                                style: textTheme.headlineSmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _generatePDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Descargar PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}