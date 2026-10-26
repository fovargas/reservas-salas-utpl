import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/salas_controller.dart';
import '../models/sala.dart';
import '../screens/sala_detalle_screen.dart';
import '../utils/formatos.dart';

IconData iconoTipo(String tipo) => switch (tipo) {
  'reuniones' => Icons.groups,
  'auditorio' => Icons.theater_comedy,
  'laboratorio' => Icons.computer,
  'estudio' => Icons.menu_book,
  'aula' => Icons.class_,
  'multimedia' => Icons.videocam,
  _ => Icons.meeting_room,
};

class SalaCard extends StatelessWidget {
  const SalaCard({super.key, required this.sala});

  final Sala sala;

  @override
  Widget build(BuildContext context) {
    final salas = Get.find<SalasController>();
    final colores = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colores.primaryContainer,
          child: Icon(iconoTipo(sala.tipo), color: colores.onPrimaryContainer),
        ),
        title: Text(
          sala.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${sala.edificio} · ${Formatos.etiquetaTipo(sala.tipo)} · ${sala.capacidad} personas',
        ),
        trailing: Obx(() {
          final favorita = salas.favoritas.contains(sala.id);
          return IconButton(
            tooltip: favorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
            icon: Icon(
              favorita ? Icons.star : Icons.star_border,
              color: favorita ? colores.secondary : null,
            ),
            onPressed: () => salas.alternarFavorita(sala.id),
          );
        }),
        onTap: () => Get.to(() => SalaDetalleScreen(sala: sala)),
      ),
    );
  }
}
