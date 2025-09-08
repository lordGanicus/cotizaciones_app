import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List> generarPdfCotizacionHabitacionDetallada({
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
  // Agregamos directamente los horarios del establecimiento
  required String checkIn,
  required String checkOut,
}) async {
  final pdf = pw.Document();

  // Fuente personalizada para la firma
  final acterumSignature = pw.Font.ttf(
    await rootBundle.load('assets/fonts/acterum-signature-font.ttf'),
  );

  // Estilos
  final azulOscuro = PdfColor.fromInt(0xFF0D3B66);
  final estiloTitulo = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNegrita = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 11);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: azulOscuro,
  );

  // Cargar imágenes
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

  // Funciones auxiliares
  String formatFecha(dynamic fecha) {
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha?.toString() ?? 'N/D';
    }
  }

  String obtenerCodigoCorto(String id) => id.substring(0, 8).toUpperCase();

  String ciMostrar(String ci) {
    if (ci.trim().isEmpty) return "No especificado";
    return ci;
  }

  // =========================
  // PÁGINA 1: Cotización (sin cambios)
  // =========================
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
                  /*if (logoImage != null)
                  pw.Center(child: pw.Image(logoImage, height: 80)),*/
                  pw.SizedBox(height: 20),

                  // Datos cliente
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.Text('N° de Cotización: ', style: estiloNegrita),
                        pw.Text(obtenerCodigoCorto(idCotizacion), style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 6),
                      pw.Row(children: [
                        pw.Text('Cliente: ', style: estiloNegrita),
                        pw.Text(nombreCliente, style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 6),
                      pw.Row(children: [
                        pw.Text('C.I / NIT: ', style: estiloNegrita),
                        pw.Text(ciMostrar(ciCliente), style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 6),
                      pw.Row(children: [
                        pw.Text('Fecha: ', style: estiloNegrita),
                        pw.Text(formatFecha(cotizacionData?['fecha_creacion']), style: estiloNormal),
                      ]),
                    ],
                  ),

                  pw.SizedBox(height: 40),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Ref.: Cotización de Servicios de Hospedaje',
                      style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 24),
                  pw.Text('Estimado(a):', style: estiloNegrita),
                  pw.SizedBox(height: 8),

                  pw.RichText(
                    textAlign: pw.TextAlign.justify,
                    text: pw.TextSpan(
                      style: estiloNormal,
                      children: [
                        const pw.TextSpan(
                          text: 'Nuestro servicio de hospedaje está diseñado para adaptarse a diferentes necesidades, ofreciendo espacios ',
                        ),
                        pw.TextSpan(text: 'cómodos, seguros y funcionales', style: estiloNegrita),
                        const pw.TextSpan(
                          text: '. Nos enfocamos en proporcionar bienestar en cada momento de la estadía.',
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Presentamos a continuación el detalle de la cotización para su estadía:',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),

                  pw.SizedBox(height: 24),
                  pw.Text('DETALLES DE LA COTIZACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 20),

                  // Tabla
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
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
                            _cell('${formatFecha(detalles['fecha_ingreso'])}'),
                            _cell('${formatFecha(detalles['fecha_salida'])}'),
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

  // =========================
  // PÁGINA 2: Políticas y Condiciones
  // =========================
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
                  pw.SizedBox(height: 58),
                  pw.Center(child: pw.Text('Políticas y Condiciones', style: estiloTitulo)),
                  pw.SizedBox(height: 20),
                  ..._politicasYCondiciones(estiloNegrita, estiloNormal, checkIn, checkOut),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // =========================
  // PÁGINA 3: Obligaciones y Firma
  // =========================
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
                  pw.SizedBox(height: 58),
                  pw.Center(child: pw.Text('Obligaciones', style: estiloTitulo)),
                  pw.SizedBox(height: 20),
                  ..._obligaciones(estiloNegrita, estiloNormal),
                  pw.SizedBox(height: 40),
                  
                  pw.Text('Atentamente:', style: estiloNegrita),
                  pw.SizedBox(height: 40),

                  // Firma centrada (ahora en la tercera página)
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('${nombreUsuario.split(' ').take(2).join(' ')}', style: estiloFirma),
                        pw.SizedBox(height: 12),
                        pw.Container(width: 150, height: 2, color: PdfColors.grey),
                        pw.SizedBox(height: 6),
                        pw.Text('${nombreUsuario.split(' ').take(2).join(' ')}', style: estiloNormal),
                        pw.SizedBox(height: 6),
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

// Helpers
pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );
}

List<pw.Widget> _politicasYCondiciones(
  pw.TextStyle estiloNegrita,
  pw.TextStyle estiloNormal,
  String checkIn,
  String checkOut,
) {
  final politicas = [
    {
      'titulo': 'Horario de Ingreso (Check-In)',
      'contenido': 'El horario de ingreso es a partir de las $checkIn. En caso de que la llegada se efectúe durante la madrugada, la reserva deberá gestionarse a partir de la noche anterior, incluyendo una noche adicional.'
    },
    {
      'titulo': 'Horario de Salida (Check-Out)',
      'contenido': 'El horario de salida es hasta las $checkOut horas del mediodía.'
    },
    {
      'titulo': 'Llegada anticipada (Early Check-In)',
      'contenido': 'En caso de requerir la habitación antes del horario de ingreso, se puede solicitar un ingreso más temprano el cual estaría sujeto a disponibilidad del hotel y según precio establecido.'
    },
    {
      'titulo': 'Salida tardía (Late Check-Out)',
      'contenido': 'Si requiere ocupar la habitación pasado el horario de salida (mediodía), se incrementare el 50% de su tarifa hasta horas 18:00. Pasado este horario se procederá al cobro de una noche extra según el precio proporcionado.'
    },
    {
      'titulo': 'Modificación de Reserva',
      'contenido': 'Toda modificación se debe realizar hasta 24 horas antes de la llegada de cada huésped, caso contrario se realizará el cobro de la noche de hospedaje según la solicitud de reserva realizada inicialmente.'
    },
    {
      'titulo': 'Cancelación',
      'contenido': 'Toda cancelación de reserva, debe ser realizada con 24 horas de anticipación a la llegada de cada huésped, caso contrario se realizará el cobro de la primera noche.'
    },
    {
      'titulo': 'No-Show',
      'contenido': 'Se aplicará el No-Show, cuando el huésped no haya llegado al hotel, y su reserva no haya sido cancelada o modificada. Se procederá al cobro de la primera noche de hospedaje como penalidad.'
    },
    {
      'titulo': 'Personas con discapacidad',
      'contenido': 'El hotel cuenta con una habitación amplia y cómoda para personas con discapacidad, así como en áreas comunes como el restaurante y baños.'
    },
  ];

  return politicas.expand((p) {
    return [
      pw.Bullet(text: p['titulo']!, style: estiloNegrita),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 14, top: 2, bottom: 14),
        child: pw.Text(p['contenido']!, style: estiloNormal, textAlign: pw.TextAlign.justify),
      ),
    ];
  }).toList();
}

List<pw.Widget> _obligaciones(
  pw.TextStyle estiloNegrita,
  pw.TextStyle estiloNormal,
) {
  final obligaciones = [
    {
      'titulo': 'Niños',
      'contenido': 'Se admiten niños menores a 10 años sin ningún cargo, siempre y cuando compartan la cama con sus papas. Mayores a 10 años pagan como una persona adulta extra.'
    },
    {
      'titulo': 'Política de Edad Mínima',
      'contenido': 'Se permite el ingreso únicamente a huéspedes mayores de 18 años. Los menores de edad deberán estar acompañados por un familiar.'
    },
    {
      'titulo': 'Política de Libre de Tabaco',
      'contenido': 'El hotel es Libre de Tabaco (Ley Nro.1333 del Medio Ambiente). En caso de fumar dentro de nuestras habitaciones o áreas no asignadas, se realizará un cargo de limpieza de USD. 100.00.'
    },
    {
      'titulo': 'Ruidos y Molestias',
      'contenido': 'No es permitido realizar fiestas dentro nuestras habitaciones o suites. Cualquier reclamo por ruidos o molestias se realizará el desalojo del hotel sin el reembolso de la noche de hospedaje.'
    },
    {
      'titulo': 'Identificación',
      'contenido': 'Todo huésped debe presentar su documento de identificación o pasaporte al momento de su registro, en el caso de huéspedes extranjeros también deben presentar la boleta de ingreso al país o sello de ingreso al país en el pasaporte. Caso contrario no se permitirá el ingreso o registro a nuestro hotel.'
    },
    {
      'titulo': 'Formas de Pago',
      'contenido': 'Se admite el pago en efectivo, mediante tarjetas de débito o crédito (Visa y MasterCard) y a través de cobros por código QR.'
    },
  ];

  return obligaciones.expand((o) {
    return [
      pw.Bullet(text: o['titulo']!, style: estiloNegrita),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 14, top: 2, bottom: 14),
        child: pw.Text(o['contenido']!, style: estiloNormal, textAlign: pw.TextAlign.justify),
      ),
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