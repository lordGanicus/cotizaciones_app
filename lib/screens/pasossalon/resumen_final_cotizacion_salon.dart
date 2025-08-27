import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'generador_pdf_salon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class ResumenFinalCotizacionSalonPage extends StatefulWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;
  final String? idSubestablecimiento;

  const ResumenFinalCotizacionSalonPage({
    Key? key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
    this.idSubestablecimiento,
  }) : super(key: key);

  @override
  State<ResumenFinalCotizacionSalonPage> createState() =>
      _ResumenFinalCotizacionSalonPageState();
}

class _ResumenFinalCotizacionSalonPageState
    extends State<ResumenFinalCotizacionSalonPage> {
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
  String? nombreSubestablecimiento;
  String? logoSubestablecimiento;
  String? membreteSubestablecimiento;
  String? nombreUsuario;
  String ? celular;
  Map<String, dynamic>? cotizacionData;
  List<Map<String, dynamic>> items = [];
  double totalFinal = 0;
  bool isLoading = true;
  String? error;
  int capacidadEsperada = 0;
  String? fechaEvento;
  String? horaInicio;
  String? horaFin;
  String nombreSalon = '';
  String tipoArmado = '';
  int participantes = 0;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _loadData();
  }

  // Bloqueo de retroceso
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text(
            'Si regresas al inicio, perderás el progreso de esta cotización.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regresar al inicio'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      // Navegar a hotel_selection.dart
      Navigator.of(context).popUntil((route) => route.isFirst);
      return false; // No permitir el pop normal
    }
    return false;
  }

  String _formatId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Obtener datos del usuario
      final usuarioResp = await supabase
          .from('usuarios')
          .select('id_subestablecimiento, nombre_completo, celular')
          .eq('id', user.id)
          .single();
   
      celular = (usuarioResp['celular'] ?? '--');


    nombreUsuario = (usuarioResp['nombre_completo'] ?? '').toString().trim();
      // Usar el idSubestablecimiento pasado como parámetro si está disponible
      final idSubestablecimiento =
          widget.idSubestablecimiento ?? usuarioResp['id_subestablecimiento'];

      if (idSubestablecimiento == null)
        throw 'Subestablecimiento no encontrado';

      // Obtener datos del SUBestablecimiento
      final subestablecimientoResp = await supabase
          .from('subestablecimientos')
          .select('nombre, logotipo, membrete')
          .eq('id', idSubestablecimiento)
          .single();

      nombreSubestablecimiento = subestablecimientoResp['nombre'] as String?;
      logoSubestablecimiento = subestablecimientoResp['logotipo'] as String?;
      
      membreteSubestablecimiento =
          subestablecimientoResp['membrete'] as String?;

      // Obtener datos de la cotización
      final cotizacionResp = await supabase
          .from('cotizaciones')
          .select()
          .eq('id', widget.idCotizacion)
          .single();

      cotizacionData = cotizacionResp;

      // Obtener items de la cotización
      final itemsResp = await supabase
          .from('items_cotizacion')
          .select()
          .eq('id_cotizacion', widget.idCotizacion);

      items = List<Map<String, dynamic>>.from(itemsResp);

      // Procesar detalles específicos de salón
      for (var item in items) {
        if ((item['tipo'] ?? '') == 'salon') {
          final detalles = item['detalles'];
          if (detalles is Map) {
            capacidadEsperada = detalles['capacidad_sillas'] ?? 0;
            fechaEvento = detalles['fecha'];
            horaInicio = detalles['hora_inicio'];
            horaFin = detalles['hora_fin'];
            nombreSalon = detalles['nombre_salon'] ?? '';
            tipoArmado = detalles['tipo_armado'] ?? '';
            participantes = detalles['participantes'] ?? 0;
          } else if (detalles is String) {
            try {
              final decoded = jsonDecode(detalles);
              if (decoded is Map) {
                capacidadEsperada = decoded['capacidad_sillas'] ?? 0;
                fechaEvento = decoded['fecha'];
                horaInicio = decoded['hora_inicio'];
                horaFin = decoded['hora_fin'];
                nombreSalon = decoded['nombre_salon'] ?? '';
                tipoArmado = decoded['tipo_armado'] ?? '';
                participantes = decoded['participantes'] ?? 0;
              }
            } catch (_) {}
          }
          break; // Solo necesitamos el primer item de tipo salon
        }
      }

      // Calcular total final
      totalFinal = items.fold<double>(0, (prev, item) {
        double totalItem = 0;
        final val = item['total'];
        if (val is num) {
          totalItem = val.toDouble();
        } else {
          final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
          final precio =
              double.tryParse(item['precio_unitario'].toString()) ?? 0;
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

  Map<String, dynamic>? parseDetallesSalon(dynamic detalles) {
    if (detalles == null) return null;

    try {
      if (detalles is String) {
        return jsonDecode(detalles) as Map<String, dynamic>;
      } else if (detalles is Map) {
        return detalles.cast<String, dynamic>();
      }
    } catch (e) {
      debugPrint('Error parsing detalles salon: $e');
    }
    return null;
  }

  String formatHora(dynamic hora) {
    try {
      if (hora is String) {
        // Extrae solo la parte de la hora del string ISO
        final dateTime = DateTime.parse(hora);
        return DateFormat('HH:mm').format(dateTime);
      }
      return hora?.toString() ?? 'N/D';
    } catch (_) {
      return hora?.toString() ?? 'N/D';
    }
  }

  Future<Uint8List> _generatePDFBytes() async {
    return await generarPdfCotizacionSalon(
      nombreSubestablecimiento: nombreSubestablecimiento ?? 'Salón de Eventos',
      logoSubestablecimiento: logoSubestablecimiento,
      membreteSubestablecimiento: membreteSubestablecimiento,
      idCotizacion: widget.idCotizacion,
      nombreCliente: widget.nombreCliente,
      ciCliente: widget.ciCliente,
      cotizacionData: cotizacionData,
      items: items,
      totalFinal: totalFinal,
      nombreUsuario: nombreUsuario ?? 'Usuario',
      capacidadEsperada: capacidadEsperada,
      fechaEvento: fechaEvento,
      horaInicio: horaInicio,
      horaFin: horaFin,
      nombreSalon: nombreSalon,
      tipoArmado: tipoArmado,
      participantes: participantes,
      celular: celular ?? 'Celular',
    );
  }

  Future<void> _savePDF() async {
    if (_isGeneratingPDF) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdfBytes = await _generatePDFBytes();

      // Usamos getExternalStorageDirectory para Android y getApplicationDocumentsDirectory para iOS
      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw 'No se pudo acceder al directorio de almacenamiento';
      }

      // Crear subdirectorio si no existe
      final saveDir = Directory('${directory.path}/Cotizaciones');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Crear nombre del archivo
      final fileName =
          '${widget.nombreCliente.replaceAll(RegExp(r'[^\w\s-]'), '')} - Cotización de Salón.pdf';
      final filePath = '${saveDir.path}/$fileName';
      final file = File(filePath);

      // Guardar el archivo
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en: $filePath'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: primaryGreen,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () async {
                if (Platform.isAndroid || Platform.isIOS) {
                  final result = await File(filePath).exists();
                  if (result) {
                    await Share.shareXFiles([XFile(filePath)]);
                  }
                }
              },
            ),
          ),
        );
      }
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
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Future<void> _shareCotizacion() async {
    if (_isGeneratingPDF) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdfBytes = await _generatePDFBytes();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.nombreCliente.replaceAll(RegExp(r'[^\w\s-]'), '')} - Cotización Salón.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Verificar si el archivo existe
      if (!await file.exists()) {
        throw 'El archivo no se creó correctamente';
      }

      // Configuración específica para compartir
      final RenderBox? box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Cotización de salón para ${widget.nombreCliente}',
        subject: 'Cotización de Evento',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: lightBackground,
        appBar: AppBar(
          title: const Text(
            'Resumen de Cotización - Salón',
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
          automaticallyImplyLeading: false,
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
                        // Encabezado con logo
                        if (logoSubestablecimiento != null &&
                            logoSubestablecimiento!.isNotEmpty)
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
                                logoSubestablecimiento!,
                                height: 80,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.event,
                                  size: 60,
                                  color: darkBlue.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        if (nombreSubestablecimiento != null)
                          Center(
                            child: Text(
                              nombreSubestablecimiento!,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: darkBlue,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Información de la cotización
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cotización N° ${_formatId(widget.idCotizacion)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: darkBlue,
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
                              _buildInfoRow(
                                  'CI/NIT:',
                                  widget.ciCliente.isEmpty
                                      ? 'No especificado'
                                      : widget.ciCliente),
                              if (nombreSalon.isNotEmpty)
                                _buildInfoRow('Salón:', nombreSalon),
                              if (capacidadEsperada > 0)
                                _buildInfoRow('Capacidad:',
                                    '$capacidadEsperada personas'),
                              if (fechaEvento != null)
                                _buildInfoRow(
                                    'Fecha evento:', formatFecha(fechaEvento)),
                              if (horaInicio != null && horaFin != null)
                                _buildInfoRow(
                                  'Horario:',
                                  '${formatHora(horaInicio)} - ${formatHora(horaFin)}',
                                ),
                              if (tipoArmado.isNotEmpty)
                                _buildInfoRow('Tipo de armado:', tipoArmado),
                              if (participantes > 0)
                                _buildInfoRow('Participantes:',
                                    '$participantes personas'),
                              const SizedBox(height: 8),
                              _buildInfoRow('Estado:',
                                  cotizacionData?['estado'] ?? 'N/D'),
                              _buildInfoRow(
                                  'Fecha creación:',
                                  formatFecha(
                                      cotizacionData?['fecha_creacion'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Detalle de items del salón
                        Text(
                          'Detalle de Servicios',
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
                                'No hay items en esta cotización',
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
                                // Encabezado de la tabla
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal:
                                          12), // Reducido el padding horizontal
                                  decoration: BoxDecoration(
                                    color: darkBlue.withOpacity(0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex:
                                            2, // Reducido el flex para descripción
                                        child: Text(
                                          'Descripción',
                                          style: TextStyle(
                                            fontSize:
                                                12, // Tamaño de fuente más pequeño
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Cant.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'P. Unit.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Filas de la tabla
                                ...items.map((item) {
                                  final descripcion =
                                      item['descripcion'] ?? 'Sin descripción';
                                  final cantidad = item['cantidad'] ?? 0;
                                  final precioUnitario =
                                      (item['precio_unitario'] ?? 0).toDouble();
                                  final subtotal = cantidad * precioUnitario;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal:
                                            12), // Reducido el padding horizontal
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
                                          flex:
                                              2, // Reducido el flex para descripción
                                          child: Text(
                                            descripcion.toString(),
                                            style: const TextStyle(
                                              fontSize:
                                                  12, // Tamaño de fuente más pequeño
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines:
                                                2, // Permitir múltiples líneas
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            cantidad.toString(),
                                            style:
                                                const TextStyle(fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Bs ${precioUnitario.toStringAsFixed(2)}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Bs ${subtotal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: primaryGreen,
                                            ),
                                            textAlign: TextAlign.end,
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

                        // Total final
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

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isGeneratingPDF ? null : _savePDF,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkBlue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isGeneratingPDF
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                onPressed:
                                    _isGeneratingPDF ? null : _shareCotizacion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isGeneratingPDF
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
      ),
    );
  }
}
