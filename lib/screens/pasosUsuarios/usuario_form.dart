import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/usuario.dart';
import '../../providers/usuarios_provider.dart';
import '../../providers/roles_provider.dart';
import '../../providers/pestablecimiento.dart';

class UsuarioFormPage extends ConsumerStatefulWidget {
  final Usuario? usuarioEditar;
  const UsuarioFormPage({super.key, this.usuarioEditar});

  @override
  ConsumerState<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends ConsumerState<UsuarioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ciController = TextEditingController();
  final nombreController = TextEditingController();
  final celularController = TextEditingController();

  String? genero;
  String? idRol;
  String? idEstablecimiento;
  String? idSubestablecimiento;
  List<String> otrosEstablecimientos = [];

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioEditar;
    if (u != null) {
      ciController.text = u.ci;
      nombreController.text = u.nombreCompleto;
      celularController.text = u.celular;
      genero = u.genero;
      idRol = u.idRol;
      idEstablecimiento = u.idEstablecimiento;
      idSubestablecimiento = u.idSubestablecimiento;
      otrosEstablecimientos = List<String>.from(u.otrosEstablecimientos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final establecimientosAsync = ref.watch(establecimientosProvider);
    final subestablecimientosAsync = idEstablecimiento != null
        ? ref.watch(subestablecimientosProvider(idEstablecimiento!))
        : const AsyncValue.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuarioEditar == null ? 'Crear usuario' : 'Editar usuario'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: ciController,
              decoration: const InputDecoration(labelText: 'CI'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: celularController,
              decoration: const InputDecoration(labelText: 'Celular'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: genero,
              decoration: const InputDecoration(labelText: 'Género'),
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() => genero = value),
              validator: (v) => v == null ? 'Seleccione un género' : null,
            ),
           const SizedBox(height: 12),
           rolesAsync.when(
                data: (roles) => DropdownButtonFormField<String>(
                  value: idRol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                      .toList(),
                  onChanged: (value) => setState(() => idRol = value),
                  validator: (v) => v == null ? 'Seleccione un rol' : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error cargando roles: $e'),
              ),
            const SizedBox(height: 12),
            establecimientosAsync.when(
              data: (lista) => DropdownButtonFormField<String>(
                value: idEstablecimiento,
                decoration: const InputDecoration(labelText: 'Establecimiento principal'),
                items: lista
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    idEstablecimiento = val;
                    idSubestablecimiento = null;
                    otrosEstablecimientos.remove(val);
                  });
                },
                validator: (v) => v == null ? 'Seleccione un establecimiento' : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error cargando establecimientos: $e'),
            ),
            const SizedBox(height: 12),
            subestablecimientosAsync.when(
              data: (subs) => DropdownButtonFormField<String?>(
                value: idSubestablecimiento,
                decoration: const InputDecoration(labelText: 'Subestablecimiento (opcional)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Ninguno')),
                  ...subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                ],
                onChanged: (value) => setState(() => idSubestablecimiento = value),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error subestablecimientos: $e'),
            ),
            const SizedBox(height: 12),
            establecimientosAsync.when(
              data: (lista) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Otros establecimientos (opcional)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...lista
                      .where((e) => e.id != idEstablecimiento)
                      .map((e) => CheckboxListTile(
                            title: Text(e.nombre),
                            value: otrosEstablecimientos.contains(e.id),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  otrosEstablecimientos.add(e.id);
                                } else {
                                  otrosEstablecimientos.remove(e.id);
                                }
                              });
                            },
                          ))
                      .toList(),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final usuario = Usuario(
                    id: widget.usuarioEditar?.id ?? '',
                    ci: ciController.text.trim(),
                    nombreCompleto: nombreController.text.trim(),
                    celular: celularController.text.trim(),
                    genero: genero!,
                    avatar: '', // Avatar asignado automáticamente (si aplica)
                    idRol: idRol!,
                    idEstablecimiento: idEstablecimiento!,
                    idSubestablecimiento: idSubestablecimiento,
                    otrosEstablecimientos: otrosEstablecimientos,
                  );

                  final notifier = ref.read(usuariosProvider.notifier);
                  if (widget.usuarioEditar == null) {
                    await notifier.agregarUsuario(usuario);
                  } else {
                    await notifier.actualizarUsuario(usuario);
                  }

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ciController.dispose();
    nombreController.dispose();
    celularController.dispose();
    super.dispose();
  }
}
