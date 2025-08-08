import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'generador_pdf_comida.dart';

class ResumenFinalCotizacionComidaPage extends StatefulWidget {
  final String idCotizacion;
  final String nombreCliente;
  final String ciCliente;

  const ResumenFinalCotizacionComidaPage({
    Key? key,
    required this.idCotizacion,
    required this.nombreCliente,
    required this.ciCliente,
  }) : super(key: key);

  @override
  State<ResumenFinalCotizacionComidaPage> createState() =>
      _ResumenFinalCotizacionComidaPageState();
}

class _ResumenFinalCotizacionComidaPageState
    extends State<ResumenFinalCotizacionComidaPage> {
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

      // Obtener datos del usuario
      final usuarioResp = await supabase
          .from('usuarios')
          .select('id_subestablecimiento, nombre_completo')
          .eq('id', user.id)
          .single();

      nombreUsuario = (usuarioResp['nombre_completo'] ?? '').toString().trim();
      final idSubestablecimiento = usuarioResp['id_subestablecimiento'];

      if (idSubestablecimiento == null) throw 'Subestablecimiento no encontrado';

      // Obtener datos del SUBestablecimiento
      final subestablecimientoResp = await supabase
          .from('subestablecimientos')
          .select('nombre, logotipo, membrete')
          .eq('id', idSubestablecimiento)
          .single();

      nombreSubestablecimiento = subestablecimientoResp['nombre'] as String?;
      logoSubestablecimiento = subestablecimientoResp['logotipo'] as String?;
      membreteSubestablecimiento = subestablecimientoResp['membrete'] as String?;

      // Obtener datos de la cotización
      final cotizacionResp = await supabase
          .from('cotizaciones')
          .select()
          .eq('id', widget.idCotizacion)
          .single();

      cotizacionData = cotizacionResp;

      // Obtener items de tipo comida
      final itemsResp = await supabase
          .from('items_cotizacion')
          .select()
          .eq('id_cotizacion', widget.idCotizacion)
          .eq('tipo', 'comida');

      items = List<Map<String, dynamic>>.from(itemsResp);

      // Calcular total final
      totalFinal = 0;
      for (var item in items) {
        final cantidad = (item['cantidad'] ?? 0) as int;
        final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();
        final subtotal = precioUnitario * cantidad;
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
    try {
      final pdfBytes = await generarPdfCotizacionComida(
        nombreSubestablecimiento: nombreSubestablecimiento ?? 'Restaurante',
        logoSubestablecimiento: logoSubestablecimiento,
        membreteSubestablecimiento: membreteSubestablecimiento,
        idCotizacion: widget.idCotizacion,
        nombreCliente: widget.nombreCliente,
        ciCliente: widget.ciCliente,
        cotizacionData: cotizacionData,
        items: items,
        totalFinal: totalFinal,
        nombreUsuario: nombreUsuario ?? 'Usuario',
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Resumen de Cotización - Comida',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Generar PDF',
          ),
        ],
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
                      if (logoSubestablecimiento != null && logoSubestablecimiento!.isNotEmpty)
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
                                Icons.restaurant,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cotización N° ${widget.idCotizacion}',
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
                            _buildInfoRow('CI/NIT:', widget.ciCliente.isEmpty ? 'No especificado' : widget.ciCliente),
                            const SizedBox(height: 8),
                            _buildInfoRow('Estado:', cotizacionData?['estado'] ?? 'N/D'),
                            _buildInfoRow('Fecha creación:', formatFecha(cotizacionData?['fecha_creacion'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Detalle de items de comida
                      Text(
                        'Detalle de Servicios de Comida',
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
                              'No hay items de comida en esta cotización',
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
                                      flex: 3,
                                      child: Text(
                                        'Descripción',
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
                                        'P. Unitario',
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
                              // Filas de la tabla
                              ...items.map((item) {
                                final descripcion = item['descripcion'] ?? 'Sin descripción';
                                final cantidad = item['cantidad'] ?? 0;
                                final precioUnitario = (item['precio_unitario'] ?? 0).toDouble();
                                final subtotal = cantidad * precioUnitario;

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
                                        flex: 3,
                                        child: Text(
                                          descripcion.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                          'Bs ${precioUnitario.toStringAsFixed(2)}',
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

                      // Botón de generar PDF
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generatePDF,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: darkBlue.withOpacity(0.3),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 20),
                              SizedBox(width: 8),
                              Text('GENERAR PDF'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}