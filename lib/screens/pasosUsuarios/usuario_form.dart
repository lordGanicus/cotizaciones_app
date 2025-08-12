import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? genero;
  String? idRol;
  String? idEstablecimiento;
  String? idSubestablecimiento;

  final supabase = Supabase.instance.client;

  // Colores definidos
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);
  final Color errorColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioEditar;
    if (u != null) {
      ciController.text = u.ci;
      nombreController.text = u.nombreCompleto;
      celularController.text = u.celular;
      emailController.text = u.email;
      genero = u.genero;
      idRol = u.idRol;
      idEstablecimiento = u.idEstablecimiento;
      idSubestablecimiento = u.idSubestablecimiento;
    }
  }

  @override
  void dispose() {
    ciController.dispose();
    nombreController.dispose();
    celularController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: darkBlue),
      filled: true,
      fillColor: lightBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryGreen, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: errorColor, width: 2)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: errorColor, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: darkBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final establecimientosAsync = ref.watch(establecimientosProvider);
    final subestablecimientosAsync = idEstablecimiento != null
        ? ref.watch(subestablecimientosProvider(idEstablecimiento!))
        : const AsyncValue.data([]);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: darkBlue,
        title: Text(widget.usuarioEditar == null ? 'Crear usuario' : 'Editar usuario'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
               
                TextFormField(
                  controller: ciController,
                  decoration: inputDecoration('CI'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: nombreController,
                  decoration: inputDecoration('Nombre completo'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),

               
                TextFormField(
                  controller: celularController,
                  decoration: inputDecoration('Celular'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

               
                DropdownButtonFormField<String>(
                  value: genero,
                  decoration: inputDecoration('Género'),
                  items: const [
                    DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (value) => setState(() => genero = value),
                  validator: (v) => v == null ? 'Seleccione un género' : null,
                ),
                const SizedBox(height: 20),

                // Email sin buildLabel duplicado
                TextFormField(
                  controller: emailController,
                  decoration: inputDecoration('Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese correo';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password sin buildLabel duplicado
                TextFormField(
                  controller: passwordController,
                  decoration: inputDecoration('Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (widget.usuarioEditar == null && (value == null || value.isEmpty)) {
                      return 'Ingrese contraseña';
                    }
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

               
                rolesAsync.when(
                  data: (roles) => DropdownButtonFormField<String>(
                    value: idRol,
                    decoration: inputDecoration('Rol'),
                    items: roles
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                        .toList(),
                    onChanged: (value) => setState(() => idRol = value),
                    validator: (v) => v == null ? 'Seleccione un rol' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error cargando roles: $e'),
                ),
                const SizedBox(height: 20),

                
                establecimientosAsync.when(
                  data: (lista) => DropdownButtonFormField<String>(
                    value: idEstablecimiento,
                    decoration: inputDecoration('Establecimiento principal'),
                    items: lista
                        .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        idEstablecimiento = val;
                        idSubestablecimiento = null;
                      });
                    },
                    validator: (v) => v == null ? 'Seleccione un establecimiento' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error cargando establecimientos: $e'),
                ),
                const SizedBox(height: 20),

                
                subestablecimientosAsync.when(
                  data: (subs) => DropdownButtonFormField<String?>(
                    value: idSubestablecimiento,
                    decoration: inputDecoration('Subestablecimiento (opcional)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Ninguno')),
                      ...subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                    ],
                    onChanged: (value) => setState(() => idSubestablecimiento = value),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error cargando subestablecimientos: $e'),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final notifier = ref.read(usuariosProvider.notifier);

                      final usuario = Usuario(
                        id: widget.usuarioEditar?.id ?? '',
                        ci: ciController.text.trim(),
                        nombreCompleto: nombreController.text.trim(),
                        celular: celularController.text.trim(),
                        genero: genero!,
                        avatar: '',
                        idRol: idRol!,
                        idEstablecimiento: idEstablecimiento!,
                        idSubestablecimiento: idSubestablecimiento,
                        otrosEstablecimientos: [], // Ya eliminado
                        email: emailController.text.trim(),
                      );

                      if (widget.usuarioEditar == null) {
                        // Crear usuario nuevo
                        try {
                          final res = await supabase.auth.signUp(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            emailRedirectTo: 'https://confirmacion-app.netlify.app/',
                          );

                          final userId = res.user?.id;
                          if (userId == null) throw Exception('No se pudo registrar en Supabase Auth');

                          final nuevoUsuario = usuario.copyWith(id: userId);
                          await notifier.agregarUsuario(nuevoUsuario);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creando usuario: $e')),
                          );
                        }
                      } else {
                        // Actualizar usuario existente
                        await notifier.actualizarUsuario(usuario);

                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        try {
                          if (email.isNotEmpty) {
                            await supabase.auth.admin.updateUserById(
                              widget.usuarioEditar!.id,
                              attributes: AdminUserAttributes(email: email),
                            );
                          }
                          if (password.isNotEmpty) {
                            await supabase.auth.admin.updateUserById(
                              widget.usuarioEditar!.id,
                              attributes: AdminUserAttributes(password: password),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error actualizando email/contraseña: $e')),
                          );
                        }

                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}