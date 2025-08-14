import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usuario.dart';
import '../../models/establecimiento.dart';
import '../../providers/usuarios_provider.dart';
import '../../providers/establecimiento_provider.dart';
import 'usuario_form.dart';

class UsuarioListPage extends ConsumerStatefulWidget {
  UsuarioListPage({super.key});

  @override
  ConsumerState<UsuarioListPage> createState() => _UsuarioListPageState();
}

class _UsuarioListPageState extends ConsumerState<UsuarioListPage> {
  final Color primaryGreen = const Color(0xFF00B894);
  final Color darkBlue = const Color(0xFF2D4059);
  final Color lightBackground = const Color(0xFFFAFAFA);

  Establecimiento? establecimientoSeleccionado;

  // Lista de roles para mapear idRol a nombre
  final List<Map<String, String>> roles = [
    {"id": "51dc767e-3a32-4d85-b020-8bbbaa38e1fb", "nombre": "Gerente"},
    {"id": "60d7706e-f25f-4c4d-975d-fc6251371bde", "nombre": "Administrador"},
    {"id": "b26f38da-e815-47f4-b059-1a4cac0eeaac", "nombre": "Usuario"},
  ];

  String obtenerNombreRol(String idRol) {
    final rol = roles.firstWhere(
      (r) => r['id'] == idRol,
      orElse: () => {"nombre": "Desconocido"},
    );
    return rol['nombre']!;
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withOpacity(0.7),
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
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Dropdown de establecimientos
          ref.watch(establecimientosFiltradosProvider).when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error cargando establecimientos: $err'),
            ),
            data: (establecimientos) {
              if (establecimientos.isEmpty) return const SizedBox();

              if (establecimientoSeleccionado == null) {
                establecimientoSeleccionado = establecimientos.first;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<Establecimiento>(
                  isExpanded: true,
                  value: establecimientoSeleccionado,
                  items: establecimientos.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e.nombre ?? 'Sin nombre'),
                    );
                  }).toList(),
                  onChanged: (nuevo) {
                    setState(() {
                      establecimientoSeleccionado = nuevo;
                    });
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Lista de usuarios filtrada por establecimiento
          Expanded(
            child: usuarios.isEmpty
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

                      if (establecimientoSeleccionado != null &&
                          usuario.idEstablecimiento !=
                              establecimientoSeleccionado!.id) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
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
                            'CI: ${usuario.ci}  |  Rol: ${obtenerNombreRol(usuario.idRol)}',
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
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
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
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
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
                                    ref
                                        .read(usuariosProvider.notifier)
                                        .cargarUsuarios();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () {
          if (establecimientoSeleccionado != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UsuarioFormPage(
                  establecimientoSeleccionadoId: establecimientoSeleccionado!.id,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo usuario',
      ),
    );
  }
}
