import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itemComida.dart';
import '../../providers/cotizacion_comida_provider.dart';
import 'crear_cotizacion_comida_step2.dart';
import 'crear_cotizacion_comida_step4.dart';

class CrearCotizacionComidaStep3 extends ConsumerStatefulWidget {
  final String idCotizacion;
  final String idEstablecimiento;
  final String idUsuario;
  final String? idSubestablecimiento;

  const CrearCotizacionComidaStep3({
    Key? key,
    required this.idCotizacion,
    required this.idEstablecimiento,
    required this.idUsuario,
    this.idSubestablecimiento,
  }) : super(key: key);

  @override
  ConsumerState<CrearCotizacionComidaStep3> createState() =>
      _CrearCotizacionComidaStep3State();
}

class _CrearCotizacionComidaStep3State
    extends ConsumerState<CrearCotizacionComidaStep3> {
  // 🔹 Lista local solo para esta pestaña
  List<ItemComida> itemsLocal = [];

  @override
  void initState() {
    super.initState();
    // Inicializamos la lista local desde el provider si quieres mostrar datos previos
    itemsLocal = [...ref.read(cotizacionComidaProvider).itemsComida];
  }

  Future<bool> _onWillPop() async {
    // 🔹 Limpiar solo la lista local al retroceder
    setState(() {
      itemsLocal.clear();
    });
    return true; // permite retroceder
  }

  void _eliminarItem(String descripcion) async {
    final confirmado = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Seguro que quieres eliminar este ítem?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmado) return;

    setState(() {
      itemsLocal.removeWhere((item) => item.descripcion == descripcion);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ítem eliminado'),
        backgroundColor: Color(0xFF00B894),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _agregarMas() {
    // 🔹 No limpiar aquí, mantenemos la lista
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCotizacionComidaStep2(
          idCotizacion: widget.idCotizacion,
          idEstablecimiento: widget.idEstablecimiento,
          idUsuario: widget.idUsuario,
          idSubestablecimiento: widget.idSubestablecimiento,
        ),
      ),
    );
  }

  void _irAlResumen() {
    // 🔹 Limpiar solo la lista local antes de avanzar al resumen

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCotizacionComidaStep4(
          idCotizacion: widget.idCotizacion,
          idEstablecimiento: widget.idEstablecimiento,
          idUsuario: widget.idUsuario,
          idSubestablecimiento: widget.idSubestablecimiento,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text('Lista de Platos Agregados'),
          backgroundColor: const Color(0xFF2D4059),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (itemsLocal.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No hay platos agregados aún.',
                      style: TextStyle(
                        color: const Color(0xFF2D4059).withOpacity(0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: itemsLocal.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = itemsLocal[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Text(
                            item.descripcion,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Cantidad: ${item.cantidad}   |   Precio unitario: Bs ${item.precioUnitario.toStringAsFixed(2)}\nSubtotal: Bs ${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _eliminarItem(item.descripcion),
                            tooltip: 'Eliminar ítem',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _agregarMas,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Agregar más platos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2D4059),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: const Color(0xFF2D4059).withOpacity(0.7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: itemsLocal.isEmpty ? null : _irAlResumen,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ir al resumen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
