/*
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/cotizacion_model.dart';
import 'resumen.dart';

class CotizacionPage extends StatefulWidget {
  final String hotelName;
  final Color primaryColor;
  final String logoPath;
  
  

  const CotizacionPage({
    super.key,
    required this.hotelName,
    required this.primaryColor,
    required this.logoPath,
  });

  @override
  State<CotizacionPage> createState() => _CotizacionPageState();
}

class _CotizacionPageState extends State<CotizacionPage> {
  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _detalleController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioUnitarioController =
      TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  List<CotizacionItem> _cotizaciones = [];
  int _editingIndex = -1;
  String _tituloSeleccionado = 'Sr.';
  final List<String> _titulos = ['Sr.', 'Sra.', 'Srta.', 'Dr.', 'Lic.'];
  @override
  void initState() {
    super.initState();
    _cantidadController.addListener(_calcularTotal);
    _precioUnitarioController.addListener(_calcularTotal);
  }

  void _calcularTotal() {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final precioUnitario = double.tryParse(_precioUnitarioController.text) ?? 0;
    final total = cantidad * precioUnitario;

    setState(() {
      _totalController.text = total > 0 ? total.toStringAsFixed(2) : '';
    });
  }

  void _agregarOEditarItem() {
     final nombreCompleto = '$_tituloSeleccionado ${_nombreClienteController.text.trim()}';
     final detalle = _detalleController.text.trim();
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final precioUnitario = double.tryParse(_precioUnitarioController.text) ?? 0;
    final total = double.tryParse(_totalController.text) ?? 0;
    if (nombreCompleto.trim().isEmpty || detalle.isEmpty || cantidad <= 0 || precioUnitario <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor complete todos los campos correctamente'),
        backgroundColor: AppColors.errorColor,
      ),
    );
    return;
  }

    setState(() {
      if (_editingIndex >= 0) {
        _cotizaciones[_editingIndex] = CotizacionItem(
          nombreCliente: nombreCompleto,
          detalle: detalle,
          cantidad: cantidad,
          precioUnitario: precioUnitario,
          total: total,
        );
        _editingIndex = -1;
      } else {
        _cotizaciones.add(
          CotizacionItem(
            nombreCliente: nombreCompleto,
            detalle: detalle,
            cantidad: cantidad,
            precioUnitario: precioUnitario,
            total: total,
          ),
        );
      }
      _limpiarFormulario();
    });
  }

  void _limpiarFormulario() {
   _tituloSeleccionado = 'Sr.'; 
    _nombreClienteController.clear();
    _detalleController.clear();
    _cantidadController.clear();
    _precioUnitarioController.clear();
    _totalController.clear();
  }

  void _editarItem(int index) {
    setState(() {
      _editingIndex = index;
      final item = _cotizaciones[index];
      _nombreClienteController.text = item.nombreCliente;
      _detalleController.text = item.detalle;
      _cantidadController.text = item.cantidad.toString();
      _precioUnitarioController.text = item.precioUnitario.toStringAsFixed(2);
      _totalController.text = item.total.toStringAsFixed(2);
    });
  }

  void _borrarItem(int index) {
    setState(() {
      _cotizaciones.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = -1;
        _limpiarFormulario();
      }
    });
  }

  void _realizarCotizacion() {
    if (_cotizaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agregue al menos un item a la cotización'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResumenPage(
              cotizaciones: _cotizaciones,
              hotelName: widget.hotelName,
              primaryColor: widget.primaryColor,
              logoPath: widget.logoPath,
            ),
      ),
    );
  }

  double get _totalCosto =>
      _cotizaciones.fold(0, (sum, item) => sum + item.total);

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _detalleController.dispose();
    _cantidadController.dispose();
    _precioUnitarioController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cotización - ${widget.hotelName}'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: widget.primaryColor.withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Row(
            children: [
              DropdownButton<String>(
                value: _tituloSeleccionado,
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: widget.primaryColor),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                underline: Container(
                  height: 2,
                  color: widget.primaryColor,
                ),
                items: _titulos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _tituloSeleccionado = newValue!;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nombreClienteController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente',
                    hintText: 'Ej: Juan Pérez',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            TextField(
              controller: _detalleController,
              decoration: InputDecoration(
                labelText: 'Detalle del servicio',
                hintText: 'Ej: Habitación Ejecutiva',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      hintText: 'Ej: 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _precioUnitarioController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Precio Unitario (Bs)',
                      hintText: 'Ej: 750.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total (Bs)',
                hintText: 'Se calcula automáticamente',
                filled: true,
                enabled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 24),
            // Botón principal con efecto 3D
            Material(
              elevation: 6,
              shadowColor: widget.primaryColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _agregarOEditarItem,
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        widget.primaryColor,
                        Color.lerp(widget.primaryColor, Colors.black, 0.1)!,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _editingIndex >= 0 ? 'ACTUALIZAR ITEM' : 'AGREGAR ITEM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_editingIndex >= 0) ...[
              const SizedBox(height: 12),
              // Botón de cancelar con efecto "neumorphic"
              Material(
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _editingIndex = -1;
                      _limpiarFormulario();
                    });
                  },
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.primaryColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'CANCELAR EDICIÓN',
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(thickness: 1, height: 1, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'ITEMS AGREGADOS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _cotizaciones.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay items agregados',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _cotizaciones.length,
                        itemBuilder: (context, index) {
                          final item = _cotizaciones[index];
                          return Card(
                            child:ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nombreCliente,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.primaryColor,
                                  ),
                                ),
                                Text(item.detalle),
                              ],
                              ),                                                  
                              subtitle: Text(
                                '${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} Bs',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.total.toStringAsFixed(2)} Bs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 22,
                                          color: widget.primaryColor,
                                        ),
                                        onPressed: () => _editarItem(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 22,
                                          color: AppColors.errorColor,
                                        ),
                                        onPressed: () => _borrarItem(index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const Divider(thickness: 1, height: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL COSTO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_totalCosto.toStringAsFixed(2)} Bs',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Botón final con efecto de "pulsación"
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor,
                    Color.lerp(widget.primaryColor, Colors.black, 0.15)!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _realizarCotizacion,
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: const Center(
                      child: Text(
                        'REALIZAR COTIZACIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */