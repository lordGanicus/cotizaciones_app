import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usuario.dart';
import '../../providers/usuarios_provider.dart';
import 'usuario_form.dart';

class UsuarioListPage extends ConsumerWidget {
  const UsuarioListPage({super.key});

  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final usuarios = ref.watch(usuariosProvider);

  return Scaffold(
    backgroundColor: lightBackground,
    appBar: AppBar(
      backgroundColor: darkBlue,
      title: const Text('Lista de usuarios'),
      actions: [
        TextButton.icon(
          onPressed: () {
            ref.read(usuariosProvider.notifier).cargarUsuarios();
          },
          icon: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          label: Text(
            'Actualizar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7), // más clarito/blanquito
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    ),
    body: usuarios.isEmpty
        ? Center(
            child: Text(
              'No hay usuarios registrados.',
              style: TextStyle(color: darkBlue, fontSize: 16),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: usuarios.length,
            separatorBuilder: (_, __) =>
                Divider(color: darkBlue.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryGreen),
                  ),
                  title: Text(
                    usuario.nombreCompleto,
                    style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'CI: ${usuario.ci}  |  Rol: ${usuario.idRol}',
                    style: TextStyle(color: darkBlue.withOpacity(0.7)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryGreen),
                        tooltip: 'Editar usuario',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UsuarioFormPage(usuarioEditar: usuario),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Eliminar usuario',
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar usuario'),
                              content: const Text(
                                  '¿Estás seguro de que deseas eliminar este usuario?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            await ref
                                .read(usuariosProvider.notifier)
                                .eliminarUsuario(usuario.id);
                            ref.read(usuariosProvider.notifier).cargarUsuarios();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: primaryGreen,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UsuarioFormPage(),
          ),
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Crear nuevo usuario',
    ),
  );
}
}
