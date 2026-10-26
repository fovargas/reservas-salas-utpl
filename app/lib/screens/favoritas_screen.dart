import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navegacion_controller.dart';
import '../controllers/salas_controller.dart';
import '../utils/estado_carga.dart';
import '../widgets/estados.dart';
import '../widgets/menu_cuenta.dart';
import '../widgets/sala_card.dart';

class FavoritasScreen extends StatelessWidget {
  const FavoritasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SalasController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas favoritas'),
        actions: const [MenuCuenta()],
      ),
      body: Obx(() {
        if (c.estado.value == EstadoCarga.cargando) {
          return const EstadoCargando();
        }
        if (c.estado.value == EstadoCarga.error) {
          return EstadoError(
            mensaje: c.mensajeError.value,
            alReintentar: c.cargar,
          );
        }
        final lista = c.salasFavoritas;
        if (lista.isEmpty) {
          return EstadoVacio(
            icono: Icons.star_border,
            titulo: 'Aún no tienes favoritas',
            detalle: 'Toca la estrella de una sala para tenerla a mano. Se guardan en este teléfono.',
            accion: FilledButton(
              onPressed: () => Get.find<NavegacionController>().ir(0),
              child: const Text('Ver salas'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: lista.length,
          itemBuilder: (_, i) => SalaCard(sala: lista[i]),
        );
      }),
    );
  }
}
