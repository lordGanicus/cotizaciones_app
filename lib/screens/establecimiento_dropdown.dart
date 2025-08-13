import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establecimiento.dart';
import '../providers/usuario_provider.dart';
import '../providers/establecimiento_provider.dart';

class EstablecimientoDropdown extends ConsumerStatefulWidget {
  const EstablecimientoDropdown({Key? key}) : super(key: key);

  @override
  _EstablecimientoDropdownState createState() =>
      _EstablecimientoDropdownState();
}

class _EstablecimientoDropdownState
    extends ConsumerState<EstablecimientoDropdown> {
  Establecimiento? establecimientoSeleccionado;
  String? establecimientoSeleccionadoId;

  Future<void> _guardarUltimoEstablecimiento(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_establecimiento', id);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(usuarioActualProvider);
    final establecimientosAsync = ref.watch(establecimientosFiltradosProvider);

    return establecimientosAsync.when(
      data: (establecimientos) {
        if (establecimientos.isEmpty) {
          return const Center(child: Text('No hay establecimientos'));
        }

        // Inicializar seleccionado si aún no se hizo
        if (establecimientoSeleccionadoId == null) {
          String? savedId;
          usuarioAsync.maybeWhen(
              data: (usuario) => savedId = usuario.idEstablecimiento,
              orElse: () => null);

          final seleccionado = (savedId != null &&
                  establecimientos.any((e) => e.id == savedId))
              ? establecimientos.firstWhere((e) => e.id == savedId)
              : establecimientos.first;

          establecimientoSeleccionado = seleccionado;
          establecimientoSeleccionadoId = seleccionado.id;

          print(
              'EstablecimientoDropdown inicializado con: ${seleccionado.nombre}');
        }

        // Ordenar lista: seleccionado primero
        final listaOrdenada = List<Establecimiento>.from(establecimientos);
        listaOrdenada.sort((a, b) {
          if (a.id == establecimientoSeleccionadoId) return -1;
          if (b.id == establecimientoSeleccionadoId) return 1;
          return 0;
        });

        return DropdownButton<String>(
          isExpanded: true,
          value: establecimientoSeleccionadoId,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D4059)),
          items: listaOrdenada.map((e) {
            return DropdownMenuItem<String>(
              value: e.id,
              child: Text(
                e.nombre ?? 'Sin nombre',
                style: const TextStyle(color: Color(0xFF2D4059)),
              ),
            );
          }).toList(),
          onChanged: (nuevoId) async {
            if (nuevoId == null || nuevoId == establecimientoSeleccionadoId)
              return;

            final nuevoEstablecimiento =
                listaOrdenada.firstWhere((e) => e.id == nuevoId);

            final confirmar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar cambio'),
                content: Text(
                    '¿Estás seguro de cambiar al establecimiento ${nuevoEstablecimiento.nombre}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Aceptar')),
                ],
              ),
            );

            if (confirmar != true) return;

            final supabase = Supabase.instance.client;
            final user = supabase.auth.currentUser;
            if (user != null) {
              try {
                // Actualizar id_establecimiento del usuario
                await supabase
                    .from('usuarios')
                    .update({'id_establecimiento': nuevoId})
                    .eq('id', user.id);

                // Guardar en SharedPreferences
                await _guardarUltimoEstablecimiento(nuevoId);

                // Actualizar estado local
                setState(() {
                  establecimientoSeleccionadoId = nuevoId;
                  establecimientoSeleccionado = nuevoEstablecimiento;
                });

                // Refrescar provider
                ref.invalidate(usuarioActualProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Establecimiento cambiado con éxito')),
                );
              } catch (e) {
                print('Error al cambiar establecimiento: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error al cambiar establecimiento')),
                );
              }
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
