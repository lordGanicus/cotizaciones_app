import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/usuario.dart';
import '../../providers/usuarios_provider.dart';
import '../../providers/roles_provider.dart';
import '../../providers/pestablecimiento.dart';

class UsuarioFormPage extends ConsumerStatefulWidget {
  final Usuario? usuarioEditar;
  final String? establecimientoSeleccionadoId;

  const UsuarioFormPage({super.key, this.usuarioEditar, this.establecimientoSeleccionadoId});

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
    } else {
      idEstablecimiento = widget.establecimientoSeleccionadoId;
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

  String? _validarCI(String? value) {
    if (value == null || value.trim().isEmpty) return 'El CI es requerido';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo se permiten números';
    if (value.length < 5) return 'El CI debe tener al menos 5 dígitos';
    return null;
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
    final palabras = value.trim().split(' ');
    for (var palabra in palabras) {
      if (palabra.isEmpty) continue;
      if (!RegExp(r'^[A-ZÁÉÍÓÚÑ]').hasMatch(palabra[0])) return 'Cada palabra debe comenzar con mayúscula';
      if (!RegExp(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+$').hasMatch(palabra)) return 'Solo letras permitidas después de la mayúscula';
    }
    if (palabras.length < 2) return 'Ingrese al menos nombre y apellido';
    return null;
  }

  String? _validarCelular(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo números permitidos';
    if (value.length < 7 || value.length > 10) return 'Debe tener entre 7 y 10 dígitos';
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese correo';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo inválido';
    return null;
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
                // CI
                TextFormField(
                  controller: ciController,
                  decoration: inputDecoration('CI'),
                  validator: _validarCI,
                ),
                const SizedBox(height: 20),

                // Nombre
                TextFormField(
                  controller: nombreController,
                  decoration: inputDecoration('Nombre completo'),
                  validator: _validarNombre,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final palabras = value.split(' ');
                      final capitalizadas = palabras.map((palabra) {
                        if (palabra.isEmpty) return '';
                        return palabra[0].toUpperCase() +
                            (palabra.length > 1 ? palabra.substring(1).toLowerCase() : '');
                      }).join(' ');
                      if (capitalizadas != value) {
                        nombreController.value = nombreController.value.copyWith(
                          text: capitalizadas,
                          selection: TextSelection.collapsed(offset: capitalizadas.length),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Celular
                TextFormField(
                  controller: celularController,
                  decoration: inputDecoration('Celular'),
                  keyboardType: TextInputType.phone,
                  validator: _validarCelular,
                ),
                const SizedBox(height: 20),

                // Género
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

                // Email
                TextFormField(
                  controller: emailController,
                  decoration: inputDecoration('Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validarEmail,
                ),
                const SizedBox(height: 20),

                // Contraseña
                TextFormField(
                  controller: passwordController,
                  decoration: inputDecoration('Contraseña'),
                  obscureText: true,
                  enabled: false,
                ),
                const SizedBox(height: 20),

                // Rol
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

                // Establecimiento
                establecimientosAsync.when(
                  data: (lista) {
                    final seleccionado = lista.firstWhere(
                      (e) => e.id == idEstablecimiento,
                      orElse: () => lista.first,
                    );
                    return DropdownButtonFormField<String>(
                      value: seleccionado.id,
                      decoration: inputDecoration('Establecimiento principal'),
                      items: [
                        DropdownMenuItem(
                          value: seleccionado.id,
                          child: Text(seleccionado.nombre),
                        )
                      ],
                      onChanged: null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error cargando establecimientos: $e'),
                ),
                const SizedBox(height: 20),

                // Subestablecimientos
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

                // Botón Guardar
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

                      String passwordGenerada = '';
                      if (widget.usuarioEditar == null) {
                        final primerNombre = nombreController.text.trim().split(' ').first;
                        passwordGenerada = '${ciController.text.trim()}$primerNombre';
                        passwordController.text = passwordGenerada;
                      } else {
                        passwordGenerada = passwordController.text;
                      }

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
                        otrosEstablecimientos: [],
                        email: emailController.text.trim(),
                      );

                      if (widget.usuarioEditar == null) {
                        // --- CREAR USUARIO (sin tocar) ---
                        try {
                          final res = await supabase.auth.signUp(
                            email: emailController.text.trim(),
                            password: passwordGenerada,
                            emailRedirectTo: 'https://confirmacion-app.netlify.app/',
                          );

                          final userId = res.user?.id;
                          if (userId == null) throw Exception('No se pudo registrar en Supabase Auth');

                          final nuevoUsuario = usuario.copyWith(id: userId);
                          await notifier.agregarUsuario(nuevoUsuario);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Usuario registrado. Contraseña: $passwordGenerada'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          String mensajeError = 'Error al guardar usuario';
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } else {
                        // --- EDITAR USUARIO (corregido) ---
                        try {
                          print('Actualizando usuario local...');
                          await notifier.actualizarUsuario(usuario);
                          print('Usuario actualizado en provider local');

                          try {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (email.isNotEmpty) {
                              print('Actualizando email en Supabase Auth...');
                              await supabase.auth.admin.updateUserById(
                                widget.usuarioEditar!.id,
                                attributes: AdminUserAttributes(email: email),
                              );
                              print('Email actualizado en Auth');
                            }

                            if (password.isNotEmpty) {
                              print('Actualizando password en Supabase Auth...');
                              await supabase.auth.admin.updateUserById(
                                widget.usuarioEditar!.id,
                                attributes: AdminUserAttributes(password: password),
                              );
                              print('Password actualizado en Auth');
                            }
                          } catch (authError) {
                            print('No se pudo actualizar Auth (solo log): $authError');
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Usuario actualizado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }

                        } catch (e) {
                          print('Error al actualizar usuario en BD: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al guardar usuario: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
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