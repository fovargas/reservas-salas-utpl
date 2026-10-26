import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// Menú ⋮ común: correo de la sesión, «Acerca de» y cerrar sesión.
class MenuCuenta extends StatelessWidget {
  const MenuCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      onSelected: (opcion) async {
        if (opcion == 'acerca') {
          showLicensePage(
            context: context,
            applicationName: 'Reservas de Salas UTPL',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Proyecto Final — Desarrolla Aplicaciones Móviles Robustas con Flutter e IA',
          );
        } else if (opcion == 'salir') {
          final confirmar = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text(
                'Se borrarán de este teléfono tus reservas guardadas.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
          if (confirmar == true) await auth.cerrarSesion();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(auth.email.value ?? '')),
        const PopupMenuItem(value: 'acerca', child: Text('Acerca de')),
        const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
      ],
    );
  }
}
