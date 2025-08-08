import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List> generarPdfCotizacionComida({
  required String nombreSubestablecimiento,
  String? logoSubestablecimiento,
  String? membreteSubestablecimiento,
  required String idCotizacion,
  required String nombreCliente,
  required String ciCliente,
  required String nombreUsuario,
  Map<String, dynamic>? cotizacionData,
  required List<Map<String, dynamic>> items,
  required double totalFinal,
}) async {
  final pdf = pw.Document();

  // Cargar fuente para firma
  final acterumSignature = pw.Font.ttf(
    await rootBundle.load('assets/fonts/acterum-signature-font.ttf'),
  );

  // Estilos
  final estiloTitulo = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final estiloNegrita = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 11);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: PdfColors.blue800,
  );

  // Carga de imágenes
  pw.MemoryImage? logoImage;
  pw.MemoryImage? membreteImage;

  if (logoSubestablecimiento != null && logoSubestablecimiento.isNotEmpty) {
    try {
      final logoBytes = await _networkImageToBytes(logoSubestablecimiento);
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}
  }

  if (membreteSubestablecimiento != null && membreteSubestablecimiento.isNotEmpty) {
    try {
      final membreteBytes = await _networkImageToBytes(membreteSubestablecimiento);
      membreteImage = pw.MemoryImage(membreteBytes);
    } catch (_) {}
  }

  String formatFecha(dynamic fecha) {
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha?.toString() ?? 'N/D';
    }
  }

  String obtenerCodigoCorto(String id) => id.substring(0, 8).toUpperCase();

  // PÁGINA 1
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            if (membreteImage != null)
              pw.Positioned.fill(
                child: pw.Image(membreteImage, fit: pw.BoxFit.cover),
              ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 80, 40, 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Center(child: pw.Image(logoImage, height: 80)),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(nombreSubestablecimiento,
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text('La Paz, ${formatFecha(DateTime.now())}', style: estiloNormal),
                  pw.SizedBox(height: 16),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('N° de Cotización: ${obtenerCodigoCorto(idCotizacion)}',
                              style: estiloNegrita),
                          pw.SizedBox(height: 8),
                          pw.Text('Cliente:', style: estiloNegrita),
                          pw.Text(nombreCliente, style: estiloNormal),
                          pw.SizedBox(height: 4),
                          pw.Text('CI / NIT: $ciCliente', style: estiloNormal),
                        ],
                      ),
                      pw.Text(
                        'Ref.: Cotización de Servicios de Catering',
                        style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 24),
                  pw.Text('Estimado(a):', style: estiloNegrita),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Nuestro servicio de catering ofrece una experiencia culinaria excepcional, con menús personalizados y de la más alta calidad, adaptándose a sus necesidades específicas.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Presentamos a continuación el detalle de la cotización para su evento:',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),

                  pw.SizedBox(height: 24),
                  pw.Text('DETALLES DE LA COTIZACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Text('Fecha de creación: ', style: estiloNegrita),
                      pw.Text(formatFecha(cotizacionData?['fecha_creacion']),
                          style: estiloNormal),
                    ],
                  ),
                  pw.SizedBox(height: 24),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: pw.FlexColumnWidth(3),
                      1: pw.FlexColumnWidth(1.5),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _cell('Descripción'),
                          _cell('Cantidad'),
                          _cell('P. Unitario'),
                          _cell('Subtotal'),
                        ],
                      ),
                      ...items.map((item) {
                        final descripcion = item['descripcion'] ?? 'Sin descripción';
                        final cantidad = item['cantidad'] ?? 0;
                        final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();
                        final subtotal = cantidad * precioUnitario;

                        return pw.TableRow(
                          children: [
                            _cell(descripcion.toString()),
                            _cell(cantidad.toString()),
                            _cell('Bs ${precioUnitario.toStringAsFixed(2)}'),
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
                      pw.Text('Total final: ', style: estiloNegrita),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Bs ${totalFinal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // PÁGINA 2
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            if (membreteImage != null)
              pw.Positioned.fill(
                child: pw.Image(membreteImage, fit: pw.BoxFit.cover),
              ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 80, 40, 60),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Condiciones Generales', style: estiloTitulo),
                  pw.SizedBox(height: 14),

                  ..._condicionesGeneralesCatering(estiloNegrita, estiloNormal),
                  pw.SizedBox(height: 30),
                  pw.Text('Atentamente:', style: estiloNegrita),
                  pw.SizedBox(height: 40),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Lic. ${nombreUsuario.split(' ').take(2).join(' ')}',
                          style: estiloFirma,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: 150,
                          height: 2,
                          color: PdfColors.grey,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Lic. $nombreUsuario',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Jefe de Catering', style: estiloNormal),
                        pw.SizedBox(height: 2),
                        pw.Text(nombreSubestablecimiento, style: estiloNormal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );
}

List<pw.Widget> _condicionesGeneralesCatering(
    pw.TextStyle estiloNegrita, pw.TextStyle estiloNormal) {
  final condiciones = [
    {
      'titulo': 'Validez de la cotización:',
      'contenido': 'Esta propuesta es válida por 15 días calendario a partir de la fecha de emisión.'
    },
    {
      'titulo': 'Horario de servicio:',
      'contenido': 'El horario de catering será coordinado previamente con el cliente.'
    },
    {
      'titulo': 'Política de cancelación:',
      'contenido': 'Cancelaciones con menos de 48 horas de anticipación incurrirán en un cargo del 30%.'
    },
    {
      'titulo': 'Personal requerido:',
      'contenido': 'Incluye 1 chef y 2 meseros por cada 50 invitados.'
    },
    {
      'titulo': 'Modificaciones:',
      'contenido': 'Cualquier cambio en el menú deberá ser notificado con 72 horas de anticipación.'
    },
    {
      'titulo': 'Servicio adicional:',
      'contenido': 'Decoración y montaje disponible con costo adicional.'
    },
  ];

  return condiciones.expand((c) {
    return [
      pw.Bullet(text: c['titulo']!, style: estiloNegrita),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 14),
        child: pw.Text(c['contenido']!, style: estiloNormal),
      ),
      pw.SizedBox(height: 18),
    ];
  }).toList();
}

Future<Uint8List> _networkImageToBytes(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  throw Exception('Error al descargar imagen');
}