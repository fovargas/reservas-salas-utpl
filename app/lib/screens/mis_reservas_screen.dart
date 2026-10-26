import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navegacion_controller.dart';
import '../controllers/reservas_controller.dart';
import '../controllers/salas_controller.dart';
import '../models/reserva.dart';
import '../utils/estado_carga.dart';
import '../utils/formatos.dart';
import '../widgets/estados.dart';
import '../widgets/menu_cuenta.dart';

class MisReservasScreen extends StatelessWidget {
  const MisReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReservasController>();
    final email = Get.find<AuthController>().email.value!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => c.cargar(email),
          ),
          const MenuCuenta(),
        ],
      ),
      body: Obx(() {
        if (c.estado.value == EstadoCarga.cargando) {
          return const EstadoCargando(texto: 'Cargando tus reservas…');
        }
        if (c.estado.value == EstadoCarga.error) {
          return EstadoError(
            mensaje: c.mensajeError.value,
            alReintentar: () => c.cargar(email),
          );
        }
        final lista = c.proximas;
        return RefreshIndicator(
          onRefresh: () => c.cargar(email),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (c.desdeCache.value)
                const SliverToBoxAdapter(
                  child: AvisoSinConexion(
                    texto: 'Sin conexión — reservas guardadas',
                  ),
                ),
              if (lista.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoVacio(
                    icono: Icons.event_busy,
                    titulo: 'No tienes reservas próximas',
                    detalle: 'Elige una sala del campus y reserva un horario.',
                    accion: FilledButton(
                      onPressed: () => Get.find<NavegacionController>().ir(0),
                      child: const Text('Explorar salas'),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) =>
                      _TarjetaReserva(reserva: lista[i], email: email),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.reserva, required this.email});

  final Reserva reserva;
  final String email;

  Future<void> _cancelar() async {
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('La sala quedará libre para otras personas.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final error = await Get.find<ReservasController>().cancelar(
      email,
      reserva.id,
    );
    Get.snackbar(
      error == null ? 'Reserva cancelada' : 'No se pudo cancelar',
      error ?? 'La sala quedó libre.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sala = Get.find<SalasController>().porId(reserva.sala);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(
          sala?.nombre ?? reserva.sala,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            '${Formatos.fechaLarga(reserva.fecha)} · ${reserva.horaInicio}–${reserva.horaFin}',
            if (reserva.motivo != null && reserva.motivo!.isNotEmpty)
              reserva.motivo!,
          ].join('\n'),
        ),
        isThreeLine: reserva.motivo != null && reserva.motivo!.isNotEmpty,
        trailing: IconButton(
          tooltip: 'Cancelar reserva',
          icon: const Icon(Icons.delete_outline),
          onPressed: _cancelar,
        ),
      ),
    );
  }
}
