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
  required String celular,
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
  final estiloTitulo = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNegrita = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 11);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: azulOscuro,
  );

  // Carga de imágenes
  pw.MemoryImage? logoImage;
  pw.MemoryImage? membreteImage;

  if (logoSubestablecimiento != null && logoSubestablecimiento.isNotEmpty) {
    try {
      final logoBytes = await _downloadCloudinaryOriginal(logoSubestablecimiento);
      logoImage = pw.MemoryImage(logoBytes);
      print('✅ Logo descargado: ${logoBytes.lengthInBytes} bytes');
    } catch (e) {
      print('❌ Error cargando logo: $e');
    }
  }

  if (membreteSubestablecimiento != null && membreteSubestablecimiento.isNotEmpty) {
    try {
      final membreteBytes = await _downloadCloudinaryOriginal(membreteSubestablecimiento);
      membreteImage = pw.MemoryImage(membreteBytes);
      print('✅ Membrete descargado: ${membreteBytes.lengthInBytes} bytes');
    } catch (e) {
      print('❌ Error cargando membrete: $e');
    }
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

  // ==================== PÁGINA 1 ====================
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
                  // Datos cliente
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 58),
                      pw.Row(children: [
                        pw.Text('N° de Cotización: ', style: estiloNegrita),
                        pw.Text(obtenerCodigoCorto(idCotizacion), style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 5),
                      pw.Row(children: [
                        pw.Text('Cliente: ', style: estiloNegrita),
                        pw.Text(nombreCliente, style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 5),
                      pw.Row(children: [
                        pw.Text('C.I / NIT: ', style: estiloNegrita),
                        pw.Text(
                          ciCliente?.isNotEmpty == true ? ciCliente : 'No especificado',
                          style: estiloNormal,
                        ),
                      ]),
                      pw.SizedBox(height: 5),
                      pw.Row(children: [
                        pw.Text('Fecha: ', style: estiloNegrita),
                        pw.Text(formatFecha(cotizacionData?['fecha_creacion']), style: estiloNormal),
                      ]),
                    ],
                  ),

                  pw.SizedBox(height: 16),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Ref.: Cotización de Servicios de Salón',
                      style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 16),
                  pw.Text('Estimado(a):', style: estiloNegrita),
                  pw.SizedBox(height: 8),

                  pw.RichText(
                    textAlign: pw.TextAlign.justify,
                    text: pw.TextSpan(
                      style: estiloNormal,
                      children: [
                        const pw.TextSpan(
                          text: 'Brindamos un servicio completo para la organización de eventos, enfocado en confort, seguridad y atención personalizada, perfecto para reuniones corporativas, familiares o recreativas. ',
                        ),
                        pw.TextSpan(text: 'Nos aseguramos de cuidar cada detalle', style: estiloNegrita),
                        const pw.TextSpan(
                          text: ' para el éxito de su evento.',
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Seguidamente, le mostraremos los datos según sus requerimientos:',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),

                  pw.SizedBox(height: 16),
                  // Información del evento
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: 'Evento programado: ', style: estiloNegrita),
                            pw.TextSpan(text: nombreSalon, style: estiloNormal),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: 'Fecha tentativa: ', style: estiloNegrita),
                            pw.TextSpan(text: formatFecha(fechaEvento), style: estiloNormal),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: 'Horario: ', style: estiloNegrita),
                            pw.TextSpan(text: '${formatHora(horaInicio)} a ${formatHora(horaFin)}', style: estiloNormal),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: 'Modalidad de armado: ', style: estiloNegrita),
                            pw.TextSpan(text: tipoArmado, style: estiloNormal),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(text: 'Participantes: ', style: estiloNegrita),
                            pw.TextSpan(text: '$participantes personas', style: estiloNormal),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Text('DETALLES DE LA COTIZACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 18),

                  // Tabla
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
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
                  pw.SizedBox(height: 58),
                  pw.Text('CONDICIONES GENERALES', style: estiloTitulo),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Para confirmar la reserva del evento, es necesario realizar un anticipo del 60 % del monto total cotizado. El 40 % restante deberá ser cancelado con una anticipación mínima de 72 horas a la fecha del evento.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Los pagos podrán realizarse directamente en las oficinas del Hotel, en su defecto, mediante depósito o transferencia bancaria.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'En caso de no recibir el anticipo correspondiente, la reserva no será considerada confirmada, y no se garantiza la disponibilidad del salón.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text('VIGENCIA DE LA COTIZACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'La presente cotización tiene una vigencia de 10 días calendario desde la fecha de emisión.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'La disponibilidad del espacio está sujeta a confirmación escrita por parte del cliente.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Asimismo, se requiere que la reserva sea gestionada con un mínimo de 72 horas de anticipación respecto a la fecha del evento.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text('ANULACIÓN AND REPROGRAMACIÓN', style: estiloTitulo),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Toda cancelación deberá ser comunicada por escrito, con al menos 15 días naturales de anticipación. Si la anulación se realiza fuera de este plazo, se aplicará un cargo por no presentación (No Show) equivalente al 50 % del valor total cotizado.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Las solicitudes de reprogramación deberán realizarse también por escrito, con un mínimo de 7 días de anticipación, y estarán sujetas a una penalidad del 20 % sobre el total del evento.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text('CONSIDERACIONES IMPORTANTES', style: estiloTitulo),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'No está permitido el ingreso de alimentos externos al salón.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'El ingreso de bebidas será permitido únicamente bajo la modalidad de descorche, con un recargo del 40 % sobre el valor declarado. Este costo cubre el servicio de atención, vajilla y cristalería.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'El incumplimiento de estas condiciones podrá resulten en la cancelación inmediata del servicio sin derecho a reembolso.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'Gracias por considerar nuestros servicios. Estamos atentos a cualquier detalle adicional que nos permita asegurar el éxito de su evento.',
                    style: estiloNormal,
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 13),
                  pw.Text('Atentamente:', style: estiloNegrita),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          '${nombreUsuario.split(' ').take(2).join(' ')}',
                          style: estiloFirma.copyWith(color: azulOscuro),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 150,
                          height: 2,
                          color: PdfColors.grey,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ' ${nombreUsuario.split(' ').take(2).join(' ')}',
                          style: estiloNormal,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Gerente de Ventas',
                          style: estiloNormal,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          nombreSubestablecimiento,
                          style: estiloNormal,
                        ),
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
// Función para descargar la imagen desde Cloudinary en máxima calidad
Future<Uint8List> _downloadCloudinaryOriginal(String url) async {
  print('🌐 Descargando imagen original desde: $url');
  // Forzar calidad máxima (q_100) y sin transformación
  Uri uri = Uri.parse(url);
  // Evitar query params automáticos
  final cleanUrl = uri.replace(queryParameters: {}).toString();

  final response = await http.get(Uri.parse(cleanUrl));
  print('📥 Status code: ${response.statusCode}, length: ${response.contentLength}');
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  throw Exception('Error al descargar imagen');
}
