import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class RegistroUsuarioPage extends StatefulWidget {
  const RegistroUsuarioPage({Key? key}) : super(key: key);

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  // Campos del formulario
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _firmaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Aquí podrías cargar roles y establecimientos para dropdowns
  String? _selectedRolId;
  String? _selectedEstablecimientoId;

  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  // Ejemplo simple de roles y establecimientos (deberías cargarlos de BD)
  final Map<String, String> roles = {
    'b26f38da-e815-47f4-b059-1a4cac0eeaac': 'Usuario',
    '60d7706e-f25f-4c4d-975d-fc6251371bde': 'Administrador',
    // Agrega más si quieres
  };

  final Map<String, String> establecimientos = {
    '0415d4f6-3d30-4138-b463-e138179d593c': 'Hotel Madero',
    '310ff4bb-280f-41d8-b86e-858107169fdb': 'Hotel Rey Palace',
    'bd97a07c-3ef7-49d3-ad47-829080546f15': 'Hotel Elegant',
  };

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRolId == null || _selectedEstablecimientoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione rol y establecimiento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Crear usuario autenticado (email + password)
            final res = await Supabase.instance.client.auth.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              emailRedirectTo: 'https://confirmacion-app.netlify.app/', // <- Esto es clave
            );

      final userId = res.user?.id;
      if (userId == null) throw Exception('Error al crear usuario autenticado');

      // 2. Insertar datos en tabla usuarios, vinculando con userId generado
      final usuario = Usuario(
        id: userId,
        ci: _ciController.text.trim(),
        nombreCompleto: _nombreController.text.trim(),
        celular: _celularController.text.trim(),
        firma: _firmaController.text.trim().isEmpty ? null : _firmaController.text.trim(),
        idRol: _selectedRolId!,
        idEstablecimiento: _selectedEstablecimientoId!,
      );

        final supabase = Supabase.instance.client;

        // 1. Insertar en tabla usuarios
        try {
          final insertRes = await supabase
              .from('usuarios')
              .insert(usuario.toMap())
              .select()
              .single();

          // Si llega aquí, todo bien
          print('Usuario registrado: $insertRes');
        } catch (e) {
          // Opción: mostrar error sin borrar usuario auth
          print('Error al insertar en tabla usuarios: $e');
        }

      // Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ciController.dispose();
    _nombreController.dispose();
    _celularController.dispose();
    _firmaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ciController,
                decoration: const InputDecoration(labelText: 'CI'),
                validator: (value) => value == null || value.isEmpty ? 'Ingrese CI' : null,
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) => value == null || value.isEmpty ? 'Ingrese nombre' : null,
              ),
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
              ),
              TextFormField(
                controller: _firmaController,
                decoration: const InputDecoration(labelText: 'Firma (opcional)'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese correo';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese contraseña';
                  if (value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRolId,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: roles.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRolId = val),
                validator: (val) => val == null ? 'Seleccione rol' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedEstablecimientoId,
                decoration: const InputDecoration(labelText: 'Establecimiento'),
                items: establecimientos.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedEstablecimientoId = val),
                validator: (val) => val == null ? 'Seleccione establecimiento' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrarUsuario,
                      child: const Text('Registrar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}