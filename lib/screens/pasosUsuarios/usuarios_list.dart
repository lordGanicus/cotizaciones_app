import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usuario.dart';
import '../../providers/usuarios_provider.dart';
import 'usuario_form.dart';

class UsuarioListPage extends ConsumerWidget {
  const UsuarioListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos la lista de usuarios (List<Usuario>) directamente del StateNotifierProvider
    final usuarios = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Recarga la lista llamando al método cargarUsuarios del notifier
              ref.read(usuariosProvider.notifier).cargarUsuarios();
            },
          )
        ],
      ),
      body: usuarios.isEmpty
          ? const Center(child: Text('No hay usuarios registrados.'))
          : ListView.separated(
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(usuario.nombreCompleto),
                  subtitle: Text('CI: ${usuario.ci}  |  Rol: ${usuario.idRol}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UsuarioFormPage(usuarioEditar: usuario),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar usuario'),
                              content: const Text('¿Estás seguro de que deseas eliminar este usuario?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            await ref.read(usuariosProvider.notifier).eliminarUsuario(usuario.id);
                            // Recarga la lista tras eliminar
                            ref.read(usuariosProvider.notifier).cargarUsuarios();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UsuarioFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear nuevo usuario',
      ),
    );
  }
}
