import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  // Colores definidos
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color cardBackground = Colors.white;
  final Color textColor = const Color(0xFF2D4059);
  final Color secondaryTextColor = const Color(0xFF555555);
  final Color tableHeaderColor = const Color(0xFF2D4059);

  late final SupabaseClient supabase;
  String? nombreHotel;
  String? logoHotel;
  Map<String, dynamic>? cotizacionData;
  List<Map<String, dynamic>> items = [];
  double totalFinal = 0;
  bool isLoading = true;
  String? error;
  int capacidadEsperada = 0;

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

      nombreHotel = establecimientoResp['nombre'];
      logoHotel = establecimientoResp['logotipo'];

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

      // Buscar la capacidad esperada de sillas si hay un item de tipo "salon"
      for (var item in items) {
        if ((item['tipo'] ?? '') == 'salon') {
          final detalles = item['detalles'];
          if (detalles is Map && detalles.containsKey('capacidad_sillas')) {
            capacidadEsperada = detalles['capacidad_sillas'] ?? 0;
          } else if (detalles is String) {
            try {
              final decoded = jsonDecode(detalles);
              if (decoded is Map && decoded.containsKey('capacidad_sillas')) {
                capacidadEsperada = decoded['capacidad_sillas'] ?? 0;
              }
            } catch (_) {}
          }
        }
      }

      totalFinal = items.fold<double>(0, (prev, item) {
        double totalItem = 0;
        final val = item['total'];
        if (val is num) {
          totalItem = val.toDouble();
        } else {
          final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
          final precio = double.tryParse(item['precio_unitario'].toString()) ?? 0;
          totalItem = cantidad * precio;
        }
        return prev + totalItem;
      });

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = 'Error cargando datos: $e';
        isLoading = false;
      });
    }
  }

  String formatFecha(dynamic fecha) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha.toString()));
    } catch (_) {
      return fecha?.toString() ?? 'N/D';
    }
  }

  Future<Uint8List> _generarPdf() async {
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
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      final precioUnitario = double.tryParse(item['precio_unitario'].toString()) ?? 0.0;
      final totalItem = item['total'] is num ? item['total'].toDouble() : (precioUnitario * cantidad);

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
          if (logoImage != null) pw.Center(child: pw.Image(logoImage, height: 100)),
          if (nombreHotel != null)
            pw.Center(child: pw.Text(nombreHotel!, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 12),
          pw.Text('La Paz, $fechaActual'),
          pw.Text('COT N°: ${widget.idCotizacion}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Señores:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(widget.nombreCliente),
          pw.Text('CI: ${widget.ciCliente}'),
          if (capacidadEsperada > 0) ...[
            pw.SizedBox(height: 12),
            pw.Text('Capacidad esperada: $capacidadEsperada personas'),
          ],
          pw.SizedBox(height: 24),
          pw.Text('DETALLES DEL EVENTO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Fecha creación: ${formatFecha(cotizacionData?['fecha_creacion'])}'),
          pw.Text('Estado: ${cotizacionData?['estado'] ?? 'N/D'}'),
          pw.SizedBox(height: 16),
          pw.Text('🧾 Detalle de la propuesta:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Descripción', 'Cantidad', 'P. Unitario', 'Total'],
            data: itemsTable,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey700),
            cellAlignment: pw.Alignment.centerLeft,
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

    return pdf.save();
  }

  Future<void> _descargarPdf() async {
    final bytes = await _generarPdf();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> _compartirPdf() async {
    final bytes = await _generarPdf();
    await Printing.sharePdf(bytes: bytes, filename: 'cotizacion_salon_${widget.idCotizacion}.pdf');
  }

  Widget _buildHeader() {
    return Column(
      children: [
        if (logoHotel != null && logoHotel!.isNotEmpty)
          Center(
            child: Image.network(
              logoHotel!,
              height: 80,
              errorBuilder: (_, __, ___) => Icon(Icons.business, size: 80, color: darkBlue),
            ),
          ),
        const SizedBox(height: 12),
        if (nombreHotel != null)
          Text(
            nombreHotel!,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: darkBlue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Cliente:', style: TextStyle(color: secondaryTextColor)),
                ),
                Expanded(child: Text(widget.nombreCliente, style: TextStyle(color: textColor))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text('CI/NIT:', style: TextStyle(color: secondaryTextColor)),
                ),
                Expanded(child: Text(widget.ciCliente, style: TextStyle(color: textColor))),
              ],
            ),
            if (capacidadEsperada > 0) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text('Capacidad:', style: TextStyle(color: secondaryTextColor)),
                  ),
                  Expanded(
                    child: Text('$capacidadEsperada personas', style: TextStyle(color: textColor)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: darkBlue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del Evento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text('Cotización N°:', style: TextStyle(color: secondaryTextColor)),
                ),
                Expanded(child: Text(widget.idCotizacion, style: TextStyle(color: textColor))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text('Fecha creación:', style: TextStyle(color: secondaryTextColor)),
                ),
                Expanded(
                  child: Text(
                    formatFecha(cotizacionData?['fecha_creacion']),
                    style: TextStyle(color: textColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text('Estado:', style: TextStyle(color: secondaryTextColor)),
                ),
                Expanded(
                  child: Text(
                    cotizacionData?['estado'] ?? 'N/D',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: darkBlue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de la propuesta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(
                color: darkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: tableHeaderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Descripción',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Cantidad',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'P. Unitario',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Total',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...items.map((item) {
                  final desc = item['descripcion'] ?? 'Sin descripción';
                  final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
                  final precioUnitario = double.tryParse(item['precio_unitario'].toString()) ?? 0.0;
                  final totalItem = item['total'] is num
                      ? item['total'].toDouble()
                      : precioUnitario * cantidad;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: items.indexOf(item) % 2 == 0
                          ? lightBackground
                          : cardBackground,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          desc.toString(),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          cantidad.toString(),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Bs ${precioUnitario.toStringAsFixed(2)}',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Bs ${totalItem.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: darkBlue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total final:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            Text(
              'Bs ${totalFinal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _descargarPdf,
          icon: Icon(Icons.download, color: Colors.white),
          label: const Text('Descargar PDF', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _compartirPdf,
          icon: Icon(Icons.share, color: darkBlue),
          label: Text('Compartir', style: TextStyle(color: darkBlue)),
          style: ElevatedButton.styleFrom(
            backgroundColor: lightBackground,
            side: BorderSide(color: darkBlue.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Resumen de Cotización'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B894)))
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildClientInfo(),
                      const SizedBox(height: 16),
                      _buildEventDetails(),
                      const SizedBox(height: 16),
                      _buildItemsTable(),
                      const SizedBox(height: 16),
                      _buildTotalSection(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }
}