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

  // Fuente para firma
  final acterumSignature = pw.Font.ttf(
    await rootBundle.load('assets/fonts/acterum-signature-font.ttf'),
  );

  // Estilos
  final azulOscuroFirma = PdfColor.fromInt(0xFF0D3B66);
  final azulOscuro = PdfColor.fromInt(0xFF0D3B66);
  final estiloTitulo = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNegrita = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
  final estiloNormal = pw.TextStyle(fontSize: 11);
  final estiloParrafo = pw.TextStyle(fontSize: 9);
  final estiloFirma = pw.TextStyle(
    fontSize: 28,
    font: acterumSignature,
    color: azulOscuroFirma,
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

  // Función para fecha y hora
  String formatFechaHora(dynamic fecha) {
    try {
      if (fecha == null) return 'N/D';
      final dtLocal = fecha is DateTime ? fecha.toLocal() : DateTime.parse(fecha.toString()).toLocal();
      return '${dtLocal.day.toString().padLeft(2, '0')}/'
          '${dtLocal.month.toString().padLeft(2, '0')}/'
          '${dtLocal.year} ';
    } catch (_) {
      return fecha?.toString() ?? 'N/D';
    }
  }

  String obtenerCodigoCorto(String id) => id.substring(0, 8).toUpperCase();

  // ---------------- PÁGINA 1 ----------------
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
                        pw.Text(ciCliente, style: estiloNormal),
                      ]),
                      pw.SizedBox(height: 6),
                      pw.Row(children: [
                        pw.Text('Fecha: ', style: estiloNegrita),
                        pw.Text(formatFechaHora(cotizacionData?['fecha_creacion']), style: estiloNormal),
                      ]),
                    ],
                  ),

                  pw.SizedBox(height: 40),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Ref.: Cotización de Servicios Restaurante',
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
                          text: 'Nuestro restaurante ha sido cuidadosamente diseñado para ofrecerle un ',
                        ),
                        pw.TextSpan(text: 'ambiente exclusivo, cálido y privado', style: estiloNegrita),
                        const pw.TextSpan(
                          text: ', perfecto para todo tipo de ocasión: desde celebraciones familiares hasta eventos empresariales, cenas conmemorativas o encuentros especiales.',
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Presentamos a continuación el detalle de la cotización para su evento:',
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

  // ---------------- PÁGINA 2 ----------------
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
                  pw.Center(child: pw.Text('CONDICIONES GENERALES', style: estiloTitulo)),
                  pw.SizedBox(height: 8),
                  ..._condicionesGeneralesRestaurante(estiloNegrita, estiloNormal),
                  pw.SizedBox(height: 10),
                  pw.Text('Atentamente:', style: estiloNegrita),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          '${nombreUsuario.split(' ').take(2).join(' ')}',
                          style: estiloFirma,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(width: 150, height: 2, color: PdfColors.grey),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${nombreUsuario.split(' ').take(2).join(' ')}',
                          style: estiloFirma,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Gerente de ventas', style: estiloNormal),
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

// 🔹 CAMBIO AQUÍ: quité las viñetas y puse títulos en negrita sin bullet
List<pw.Widget> _condicionesGeneralesRestaurante(
    pw.TextStyle estiloNegrita, pw.TextStyle estiloParrafo) {
  final condiciones = <Map<String, dynamic>>[
    {
      'titulo': 'Presupuesto del Servicio:',
      'contenido': 'El presupuesto emitido tendrá carácter referencial y estará sujeto a variación según el menú seleccionado, la disponibilidad de insumos y los precios vigentes, en coordinación con la Encargada de Restaurantes.'
    },
    {
      'titulo': 'Reservas:',
      'contenido': 'Las reservas deberán formalizarse con una anticipación mínima de 48 horas, proporcionando la siguiente información: nombre del solicitante, cantidad de personas, fecha y hora del evento, lista de platos seleccionados y comprobante de anticipo equivalente al 50% del monto total.'
    },
    {
      'titulo': 'Condiciones de pago:',
      'contenido': 'El anticipo constituye requisito indispensable para la confirmación de la reserva. El saldo deberá ser cancelado en su totalidad antes del inicio del evento, pudiendo realizarse los pagos en efectivo, tarjeta de débito/crédito o transferencia bancaria, conforme a los medios habilitados.'
    },
    {
      'titulo': 'Duración del servicio:',
      'contenido': 'La prestación del servicio de alimentación tendrá una duración estimada de 2 horas, sujeta a ajustes de acuerdo con las características del evento y la coordinación previa con la Encargada de Restaurantes.'
    },
    {
      'titulo': 'Coordinación del evento:',
      'contenido': 'Todos los aspectos relativos al desarrollo del evento, incluyendo menú, ambientación, logística y requerimientos adicionales, deberán ser definidos de manera directa con la Encargada de Restaurantes.'
    },
    {
      'titulo': 'Exclusividad de espacios:',
      'contenido': 'El alquiler del ambiente confiere al cliente el derecho de uso exclusivo del mismo durante el tiempo contratado, quedando prohibida su cesión o uso compartido sin autorización expresa del Restaurante.'
    },
    {
      'titulo': 'Modificaciones y cancelaciones:',
      'contenido': 'Cualquier modificación en el menú, número de asistentes u otros detalles deberá notificarse con una anticipación mínima de 24 horas. En caso de cancelación por parte del cliente, el anticipo no será reembolsable, salvo que la suspensión se deba a causas imputables al Restaurante.'
    },
    {
      'titulo': 'Puntualidad:',
      'contenido': 'El cliente deberá respetar estrictamente el horario establecido. El retraso mayor a 30 minutos podrá afectar la calidad y continuidad del servicio sin responsabilidad alguna para el Restaurante.'
    },
  ];

  return condiciones.expand((c) {
    return [
      pw.Text(c['titulo'] as String, style: estiloNegrita),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 0, top: 2),
        child: pw.Text(
          c['contenido'] as String,
          style: estiloParrafo,
          textAlign: pw.TextAlign.justify,
        ),
      ),
      pw.SizedBox(height: 14),
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
