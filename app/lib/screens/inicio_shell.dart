import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navegacion_controller.dart';
import 'asistente_screen.dart';
import 'favoritas_screen.dart';
import 'mis_reservas_screen.dart';
import 'salas_screen.dart';

class InicioShell extends StatelessWidget {
  const InicioShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavegacionController>();
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: nav.indice.value,
          children: const [
            SalasScreen(),
            MisReservasScreen(),
            FavoritasScreen(),
            AsistenteScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: nav.indice.value,
          onDestinationSelected: nav.ir,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'Salas',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Mis reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star),
              label: 'Favoritas',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Asistente',
            ),
          ],
        ),
      ),
    );
  }
}
