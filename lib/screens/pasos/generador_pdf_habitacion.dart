import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List> generarPdfCotizacionHabitacion({
  required String nombreHotel,
  String? logoUrl,
  String? membreteUrl,
  required String idCotizacion,
  required String nombreCliente,
  required String ciCliente,
  required String nombreUsuario,
  Map<String, dynamic>? cotizacionData,
  required List<Map<String, dynamic>> items,
  required double totalFinal,
}) async {
  final pdf = pw.Document();

  // Cargar fuente Acterum Signature para la firma
  final acterumSignature = pw.Font.ttf(
    await rootBundle.load('assets/fonts/acterum-signature-font.ttf'),
  );

  // Colores y estilos generales
  final azulOscuro = PdfColor.fromInt(0xFF0D3B66); // azul oscuro fuerte
  final estiloTitulo = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final estiloNegrita = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 11);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: azulOscuro, // firma azul oscuro
  );

  // Carga de imágenes
  pw.MemoryImage? logoImage;
  pw.MemoryImage? membreteImage;

  if (logoUrl != null && logoUrl.isNotEmpty) {
    try {
      final logoBytes = await _networkImageToBytes(logoUrl);
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}
  }

  if (membreteUrl != null && membreteUrl.isNotEmpty) {
    try {
      final membreteBytes = await _networkImageToBytes(membreteUrl);
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
                    child: pw.Text(nombreHotel,
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
                        'Ref.: Cotización de Servicios de Hospedaje',
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
                    'Nuestro servicio de hospedaje está diseñado para adaptarse a diferentes necesidades, ofreciendo espacios cómodos, seguros y funcionales. Nos enfocamos en proporcionar bienestar en cada momento de la estadía.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Presentamos a continuación el detalle de la cotización para su estadía:',
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
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(1.5),
                      4: pw.FlexColumnWidth(1.5),
                      5: pw.FlexColumnWidth(2),
                      6: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _cell('Habitación'),
                          _cell('Ingreso'),
                          _cell('Salida'),
                          _cell('Cantidad de hab.'),
                          _cell('Noches'),
                          _cell('P. Unitario'),
                          _cell('Subtotal'),
                        ],
                      ),
                      ...items.map((item) {
                        final detalles = item['detalles'] ?? {};
                        return pw.TableRow(
                          children: [
                            _cell(detalles['nombre_habitacion'] ?? 'Sin nombre'),
                            _cell(formatFecha(detalles['fecha_ingreso'])),
                            _cell(formatFecha(detalles['fecha_salida'])),
                            _cell(detalles['cantidad'].toString()),
                            _cell(detalles['cantidad_noches'].toString()),
                            _cell('Bs ${detalles['tarifa'].toStringAsFixed(2)}'),
                            _cell('Bs ${detalles['subtotal'].toStringAsFixed(2)}'),
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
                          color: azulOscuro,
                        ),
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
                  ..._condicionesGenerales(estiloNegrita, estiloNormal),
                  pw.SizedBox(height: 30),
                  pw.Text('Atentamente:', style: estiloNegrita),
                  pw.SizedBox(height: 40),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        // Solo la firma en azul oscuro
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
                        pw.SizedBox(height: 4),

                        pw.Text('Gerente de Ventas', style: estiloNormal),
                        pw.SizedBox(height: 2),
                        pw.Text(nombreHotel, style: estiloNormal),
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

List<pw.Widget> _condicionesGenerales(
    pw.TextStyle estiloNegrita, pw.TextStyle estiloNormal) {
  final condiciones = [
    {
      'titulo': 'Validez de la cotización:',
      'contenido': 'Esta propuesta es válida por 15 días calendario a partir de la fecha de emisión.'
    },
    {
      'titulo': 'Horarios establecidos:',
      'contenido': '- Check-in: Desde las 15:00 hrs.\n- Check-out: Hasta las 12:00 hrs.'
    },
    {
      'titulo': 'Formas de pago aceptadas:',
      'contenido': 'Transferencia bancaria, tarjetas de crédito o débito, y efectivo.'
    },
    {
      'titulo': 'Política de cancelaciones:',
      'contenido': 'Cancelaciones con un mínimo de 48 horas antes del evento no generan penalización.'
    },
    {
      'titulo': 'Modificaciones:',
      'contenido': 'Cualquier cambio en los servicios deberá ser notificado y aprobado con antelación.'
    },
    {
      'titulo': 'Responsabilidades del cliente:',
      'contenido': 'El cliente se compromete a respetar las normas del hotel y cuidar las instalaciones.'
    },
    {
      'titulo': 'Atención personalizada:',
      'contenido': 'Nuestro equipo estará disponible para acompañarlo en todo el proceso y asegurar el éxito del evento.'
    },
  ];

  return condiciones.expand((c) {
    final contenido = c['contenido']!;
    final esLista = contenido.contains('\n');
    return [
      pw.Bullet(text: c['titulo']!, style: estiloNegrita),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 14),
        child: esLista
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: contenido
                    .split('\n')
                    .map((linea) => pw.Text(linea, style: estiloNormal))
                    .toList(),
              )
            : pw.Text(contenido, style: estiloNormal, textAlign: pw.TextAlign.justify),
      ),
      pw.SizedBox(height: 18),
    ];
  }).toList();
}

Future<Uint8List> _networkImageToBytes(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Error al descargar imagen');
  }
}