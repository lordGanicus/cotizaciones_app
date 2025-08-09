import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'generador_pdf_habitacion.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

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
  State<ResumenFinalCotizacionHabitacionPage> createState() =>
      _ResumenFinalCotizacionHabitacionPageState();
}

class _ResumenFinalCotizacionHabitacionPageState
    extends State<ResumenFinalCotizacionHabitacionPage> {
  // Colores del diseño
  static const Color primaryGreen = Color(0xFF00B894);
  static const Color darkBlue = Color(0xFF2D4059);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D4059);
  static const Color textSecondary = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFE74C3C);

  late final SupabaseClient supabase;
  String? nombreHotel;
  String? logoHotel;
  String? membreteHotel;
  String? nombreUsuario;
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
          .select('id_establecimiento, nombre_completo')
          .eq('id', user.id)
          .single();

      final idEstablecimiento = usuarioResp['id_establecimiento'];
      nombreUsuario = (usuarioResp['nombre_completo'] ?? '').toString().trim();

      if (idEstablecimiento == null) throw 'Establecimiento no encontrado';

      final establecimientoResp = await supabase
          .from('establecimientos')
          .select('nombre, logotipo, membrete')
          .eq('id', idEstablecimiento)
          .single();

      nombreHotel = establecimientoResp['nombre'] as String?;
      logoHotel = establecimientoResp['logotipo'] as String?;
      membreteHotel = establecimientoResp['membrete'] as String?;

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
        final cantidad = (item['cantidad'] ?? 0) as int;
        final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();
        final noches = (detalles['cantidad_noches'] ?? 1) is int
            ? detalles['cantidad_noches']
            : int.tryParse(detalles['cantidad_noches']?.toString() ?? '1') ?? 1;

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

  Future<Uint8List> _generatePDFBytes() async {
    return await generarPdfCotizacionHabitacion(
      nombreHotel: nombreHotel ?? 'Hotel',
      membreteUrl: membreteHotel,
      idCotizacion: widget.idCotizacion,
      nombreCliente: widget.nombreCliente,
      ciCliente: widget.ciCliente,
      cotizacionData: cotizacionData,
      items: items,
      totalFinal: totalFinal,
      nombreUsuario: nombreUsuario ?? 'Usuario',
    );
  }

  Future<void> _savePDF() async {
    try {
      final pdfBytes = await _generatePDFBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar PDF: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareCotizacion() async {
    try {
      final pdfBytes = await _generatePDFBytes();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Cotizacion_${widget.idCotizacion.substring(0, 8)}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Solución alternativa: Mostrar diálogo con opciones para compartir
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Compartir cotización'),
          content: const Text('Seleccione cómo desea compartir la cotización'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showShareOptions(file);
              },
              child: const Text('Compartir PDF'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showTextShareOptions();
              },
              child: const Text('Compartir texto'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar para compartir: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _showShareOptions(File file) {
    // Aquí puedes implementar tu propia lógica para compartir
    // Por ejemplo, podrías usar la API de intent de Android o UIActivityViewController en iOS
    // Esta es una implementación básica que muestra un diálogo informativo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir PDF'),
        content: const Text('La cotización en PDF está lista para compartir. '
            'Por favor, use la opción de compartir de su dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTextShareOptions() {
    final shareText = 'Cotización ${nombreHotel ?? 'Hotel'}\n'
        'Cliente: ${widget.nombreCliente}\n'
        'CI/NIT: ${widget.ciCliente}\n'
        'Total: Bs ${totalFinal.toStringAsFixed(2)}\n'
        'Fecha: ${formatFecha(DateTime.now())}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Texto para compartir'),
        content: SingleChildScrollView(
          child: Text(shareText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(shareText);
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto copiado al portapapeles')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Resumen de Cotización',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando resumen...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logoHotel != null && logoHotel!.isNotEmpty)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.network(
                              logoHotel!,
                              height: 80,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.hotel,
                                size: 60,
                                color: darkBlue.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (nombreHotel != null)
                        Center(
                          child: Text(
                            nombreHotel!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Cotización N° ${widget.idCotizacion.substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: darkBlue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatFecha(DateTime.now()),
                                  style: TextStyle(
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Cliente:', widget.nombreCliente),
                            _buildInfoRow('CI/NIT:', 
                                widget.ciCliente.isEmpty ? 'No especificado' : widget.ciCliente),
                            const SizedBox(height: 8),
                            _buildInfoRow('Estado:', 
                                cotizacionData?['estado'] ?? 'N/D'),
                            _buildInfoRow('Fecha creación:', 
                                formatFecha(cotizacionData?['fecha_creacion'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Detalle de Habitaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No hay habitaciones en esta cotización',
                              style: TextStyle(
                                color: textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: darkBlue.withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Habitación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Cant.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Noches',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...items.map((item) {
                                final detalles = item['detalles'] ?? {};
                                final nombreHabitacion =
                                    detalles['nombre_habitacion'] ?? 'Sin nombre';
                                final cantidad = detalles['cantidad'] ?? 0;
                                final noches = detalles['cantidad_noches'] ?? 0;
                                final subtotal = (detalles['subtotal'] ?? 0).toDouble();

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombreHabitacion.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${formatFecha(detalles['fecha_ingreso'])} - ${formatFecha(detalles['fecha_salida'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          cantidad.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          noches.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Bs ${subtotal.toStringAsFixed(2)}',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: darkBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Final:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Bs ${totalFinal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _savePDF,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text('GUARDAR'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _shareCotizacion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share, size: 20),
                                  SizedBox(width: 8),
                                  Text('COMPARTIR'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}