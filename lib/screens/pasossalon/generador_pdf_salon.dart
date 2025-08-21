import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

Future<Uint8List> generarPdfCotizacionSalon({
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
  required int capacidadEsperada,
  String? fechaEvento,
  String? horaInicio,
  String? horaFin,
  required String nombreSalon,
  required String tipoArmado,
  required int participantes,
}) async {
  final pdf = pw.Document();

  // Cargar fuente para firma
  final acterumSignature = pw.Font.ttf(
    await rootBundle.load('assets/fonts/acterum-signature-font.ttf'),
  );

  // Estilos
  final azulOscuro = PdfColor.fromInt(0xFF0D3B66);
  final estiloTitulo =
      pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final estiloNegrita =
      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 10);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: azulOscuro,
  );
/*print('Participantes antes de generar PDF: ${cotizacion.participantes}');*/
  // Carga de imágenes
  pw.MemoryImage? logoImage;
  pw.MemoryImage? membreteImage;

  if (logoSubestablecimiento != null && logoSubestablecimiento.isNotEmpty) {
    try {
      final logoBytes = await _networkImageToBytes(logoSubestablecimiento);
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}
  }

  if (membreteSubestablecimiento != null &&
      membreteSubestablecimiento.isNotEmpty) {
    try {
      final membreteBytes =
          await _networkImageToBytes(membreteSubestablecimiento);
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

  String formatHora(dynamic hora) {
    try {
      if (hora is String) {
        final dateTime = DateTime.parse(hora);
        return DateFormat('HH:mm').format(dateTime);
      }
      return hora?.toString() ?? 'N/D';
    } catch (_) {
      return hora?.toString() ?? 'N/D';
    }
  }

  String obtenerCodigoCorto(String id) => id.substring(0, 8).toUpperCase();
print('Participantes recibidos en PDF: $participantes');
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
                  pw.SizedBox(height: 60),
                  pw.Text('La Paz, ${formatFecha(DateTime.now())}',
                      style: estiloNormal),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              'N° de Cotización: ${obtenerCodigoCorto(idCotizacion)}',
                              style: estiloNegrita),
                          pw.SizedBox(height: 8),
                          pw.Text('Cliente:', style: estiloNegrita),
                          pw.Text(nombreCliente, style: estiloNormal),
                          pw.SizedBox(height: 4),
                          pw.Text('CI / NIT: $ciCliente', style: estiloNormal),
                        ],
                      ),
                      pw.Text(
                        'Ref.: Cotización de Servicios de Salón',
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
                    'Brindamos un servicio completo para la organización de eventos, enfocado en confort, seguridad y atención personalizada, perfecto para reuniones corporativas, familiares o recreativas. Nos aseguramos de cuidar cada detalle para el éxito de su evento.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Seguidamente, le mostraremos los datos según sus requerimientos',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 24),

                  // NUEVA SECCIÓN: Aspectos relevantes del evento
                   // debug
                  pw.Text('ASPECTOS RELEVANTES DEL EVENTO', style: estiloTitulo),
                  pw.SizedBox(height: 12),
                  pw.Bullet(
                    text: 'Evento programado: $nombreSalon',
                    style: estiloNormal,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Bullet(
                    text: 'Fecha tentativa: ${formatFecha(fechaEvento)}',
                    style: estiloNormal,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Bullet(
                    text:
                        'Horario: ${formatHora(horaInicio)} a ${formatHora(horaFin)}',
                    style: estiloNormal,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Bullet(
                    text: 'Modalidad de armado: $tipoArmado',
                    style: estiloNormal,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Bullet(
                    text: 'Participantes: $participantes personas',
                    style: estiloNormal,
                  ),
                  pw.SizedBox(height: 24),

                  pw.Text('DETALLES DE LA COTIZACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 12),
                  /*pw.Row(
                    children: [
                      pw.Text('Fecha de creación: ', style: estiloNegrita),
                      pw.Text(formatFecha(cotizacionData?['fecha_creacion']),
                          style: estiloNormal),
                    ],
                  ),
                  pw.SizedBox(height: 24),*/
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
                        final descripcion =
                            item['descripcion'] ?? 'Sin descripción';
                        final cantidad = item['cantidad'] ?? 0;
                        final precioUnitario =
                            (item['precio_unitario'] ?? 0).toDouble();
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
                 pw.SizedBox(height: 52),
                pw.Text('Condiciones Generales', style: estiloTitulo),
                pw.SizedBox(height: 10),
                ..._condicionesGeneralesSalon(estiloNegrita, estiloNormal),
                pw.Text(
                  'Gracias por considerar nuestros servicios. Estamos atentos a cualquier detalle adicional que nos permita asegurar el éxito de su evento.',
                  style: estiloNormal,
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 15),
                pw.Text('Atentamente:', style: estiloNegrita),
                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.Column(
                    children: [
                      // Nombre del firmante en fuente Acterum con azulOscuro
                      pw.Text(
                        'Lic. ${nombreUsuario.split(' ').take(2).join(' ')}',
                        style: estiloFirma.copyWith(color: azulOscuro),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: 150,
                        height: 2,
                        color: PdfColors.grey,
                      ),
                      pw.SizedBox(height: 8),
                     
                      pw.SizedBox(height: 4),
                      pw.Text('Coordinador de Eventos', style: estiloNormal),
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

List<pw.Widget> _condicionesGeneralesSalon(
    pw.TextStyle estiloNegrita, pw.TextStyle estiloNormal) {
  final condiciones = [
    {
      'titulo': 'Validez de la cotización:',
      'contenido':
          'Esta propuesta es válida por 15 días calendario a partir de la fecha de emisión.'
    },
    {
      'titulo': 'Horarios establecidos:',
      'contenido':
          'Check-in: Desde las 15:00 hrs\nCheck-out: Hasta las 12:00 hrs'
    },
    {
      'titulo': 'Formas de pago aceptadas:',
      'contenido':
          'Transferencia bancaria, tarjetas de crédito o débito, y efectivo.\nLa reserva será válida tras la confirmación del pago.'
    },
    {
      'titulo': 'Política de cancelaciones:',
      'contenido':
          'Cancelaciones con un mínimo de 48 horas antes del evento no generan penalización. Posteriores a este plazo están sujetas a cargos por cancelación.'
    },
    {
      'titulo': 'Modificaciones:',
      'contenido':
          'Cualquier cambio en los servicios deberá ser notificado y aprobado con antelación.'
    },
    {
      'titulo': 'Responsabilidades del cliente:',
      'contenido':
          'El cliente se compromete a respetar las normas del hotel y cuidar las instalaciones.\nCualquier daño podrá generar cargos adicionales.'
    },
    {
      'titulo': 'Atención personalizada:',
      'contenido':
          'Nuestro equipo estará disponible para acompañarlo en todo el proceso y asegurar el éxito de su evento.'
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
