import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/salon.dart';
import '../../providers/salones_provider.dart';
import '../../providers/pestablecimiento.dart';
import '../../providers/usuario_provider.dart';

class SalonForm extends ConsumerStatefulWidget {
  final Salon? salon;
  final String? idEstablecimientoInicial;
  final String? idSubestablecimientoInicial;

  const SalonForm({
    super.key,
    this.salon,
    this.idEstablecimientoInicial,
    this.idSubestablecimientoInicial,
  });

  @override
  ConsumerState<SalonForm> createState() => _SalonFormState();
}

class _SalonFormState extends ConsumerState<SalonForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _capMesasController;
  late TextEditingController _capSillasController;
  late TextEditingController _descripcionController;

  String? _idEstablecimientoSeleccionado;
  String? _idSubestablecimientoSeleccionado;
  bool _isLoading = false;

  final Color _azulOscuro = const Color(0xFF2D4059);
  final Color _verdeMenta = const Color(0xFF00B894);
  final Color _fondoClaro = const Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    final salon = widget.salon;

    _nombreController = TextEditingController(text: salon?.nombre ?? '');
    _capMesasController =
        TextEditingController(text: salon?.capacidadMesas.toString() ?? '');
    _capSillasController =
        TextEditingController(text: salon?.capacidadSillas.toString() ?? '');
    _descripcionController = TextEditingController(text: salon?.descripcion ?? '');

    _idSubestablecimientoSeleccionado =
        widget.idSubestablecimientoInicial ?? salon?.idSubestablecimiento;

    // Establecimiento seleccionado desde el screen
    _idEstablecimientoSeleccionado = widget.idEstablecimientoInicial;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _capMesasController.dispose();
    _capSillasController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  bool get _formValido {
    return _formKey.currentState?.validate() == true &&
        _idEstablecimientoSeleccionado != null &&
        _idSubestablecimientoSeleccionado != null &&
        !_isLoading;
  }

  Future<void> _guardar() async {
    if (!_formValido) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final nombre = _nombreController.text.trim();
    final capacidadMesas = int.tryParse(_capMesasController.text.trim()) ?? 0;
    final capacidadSillas = int.tryParse(_capSillasController.text.trim()) ?? 0;
    final descripcion = _descripcionController.text.trim();

    try {
      if (widget.salon == null) {
        await ref.read(salonesProvider.notifier).agregarSalon(
              nombre,
              capacidadMesas,
              capacidadSillas,
              descripcion.isEmpty ? null : descripcion,
              _idSubestablecimientoSeleccionado!,
            );
      } else {
        await ref.read(salonesProvider.notifier).editarSalon(
              widget.salon!.id,
              nombre,
              capacidadMesas,
              capacidadSillas,
              descripcion.isEmpty ? null : descripcion,
              _idSubestablecimientoSeleccionado!,
            );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(usuarioActualProvider);
    final establecimientosAsync = ref.watch(establecimientosProvider);

    return usuarioAsync.when(
      data: (usuario) {
        final esGerente = (usuario.rolNombre?.toLowerCase() == 'gerente');

        final subestablecimientosAsync = _idEstablecimientoSeleccionado == null
            ? const AsyncValue.data([])
            : ref.watch(subestablecimientosProvider(_idEstablecimientoSeleccionado!));

        return AbsorbPointer(
          absorbing: _isLoading,
          child: AlertDialog(
            backgroundColor: _fondoClaro,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              widget.salon == null ? 'Agregar Salón' : 'Editar Salón',
              style: TextStyle(
                color: _azulOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: establecimientosAsync.when(
              data: (establecimientos) {
                // Solo mostramos el establecimiento seleccionado
                final establecimientoSeleccionado = establecimientos
                    .firstWhere((e) => e.id == _idEstablecimientoSeleccionado);

                return SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    onChanged: () => setState(() {}),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mostrar establecimiento bloqueado
                        TextFormField(
                          initialValue: establecimientoSeleccionado.nombre,
                          decoration: InputDecoration(
                            labelText: 'Establecimiento',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          enabled: false,
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Subestablecimientos
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: subestablecimientosAsync.when(
                            data: (subs) {
                              // Evitamos duplicados
                              final subsFiltrados = subs.toSet().toList();

                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Subestablecimiento',
                                  labelStyle: TextStyle(color: _azulOscuro),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: subsFiltrados
                                    .map((e) => DropdownMenuItem<String>(
                                          value: e.id,
                                          child: Text(e.nombre,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                value: _idSubestablecimientoSeleccionado,
                                hint:
                                    const Text('Seleccione un subestablecimiento'),
                                onChanged: (value) => setState(
                                    () => _idSubestablecimientoSeleccionado = value),
                                validator: (value) => value == null
                                    ? 'Seleccione un subestablecimiento'
                                    : null,
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Error al cargar subestablecimientos: $e',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nombre salón
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del salón',
                            labelStyle: TextStyle(color: _azulOscuro),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
                        ),
                        const SizedBox(height: 16),

                        // Capacidad Mesas
                        TextFormField(
                          controller: _capMesasController,
                          decoration: InputDecoration(
                            labelText: 'Capacidad de mesas',
                            labelStyle: TextStyle(color: _azulOscuro),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = int.tryParse(value ?? '');
                            if (num == null || num < 0) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Capacidad Sillas
                        TextFormField(
                          controller: _capSillasController,
                          decoration: InputDecoration(
                            labelText: 'Capacidad de sillas',
                            labelStyle: TextStyle(color: _azulOscuro),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = int.tryParse(value ?? '');
                            if (num == null || num < 0) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Descripción
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción (opcional)',
                            labelStyle: TextStyle(color: _azulOscuro),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Error al cargar establecimientos: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: _azulOscuro)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verdeMenta,
                  disabledBackgroundColor: _verdeMenta.withOpacity(0.5),
                ),
                onPressed: _formValido ? _guardar : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar usuario: $e')),
    );
  }
}
