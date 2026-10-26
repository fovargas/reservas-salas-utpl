import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/reservas_controller.dart';
import '../controllers/salas_controller.dart';
import '../models/sala.dart';
import '../theme/app_theme.dart';
import '../utils/estado_carga.dart';
import '../utils/formatos.dart';
import '../widgets/sala_card.dart';
import 'reservar_screen.dart';

class SalaDetalleScreen extends StatefulWidget {
  const SalaDetalleScreen({super.key, required this.sala});

  final Sala sala;

  @override
  State<SalaDetalleScreen> createState() => _SalaDetalleScreenState();
}

class _SalaDetalleScreenState extends State<SalaDetalleScreen> {
  final _reservas = Get.find<ReservasController>();
  DateTime _fecha = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _reservas.cargarOcupacion(widget.sala.id, _fecha);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 90)),
    );
    if (elegida == null) return;
    setState(() => _fecha = elegida);
    _reservas.cargarOcupacion(widget.sala.id, elegida);
  }

  Future<void> _reservar() async {
    final creada = await Get.to<bool>(
      () => ReservarScreen(sala: widget.sala, fecha: _fecha),
    );
    if (creada == true) _reservas.cargarOcupacion(widget.sala.id, _fecha);
  }

  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    final salas = Get.find<SalasController>();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(sala.nombre, overflow: TextOverflow.ellipsis),
        actions: [
          Obx(() {
            final favorita = salas.favoritas.contains(sala.id);
            return IconButton(
              tooltip: favorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
              icon: Icon(favorita ? Icons.star : Icons.star_border),
              onPressed: () => salas.alternarFavorita(sala.id),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reservar,
        icon: const Icon(Icons.event_available),
        label: const Text('Reservar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.lg,
          Espacio.lg,
          96,
        ),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(iconoTipo(sala.tipo), size: 28),
              ),
              const SizedBox(width: Espacio.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sala.nombre, style: tema.textTheme.titleLarge),
                    Text(
                      '${sala.edificio} · ${Formatos.etiquetaTipo(sala.tipo)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacio.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline),
            title: Text('Capacidad: ${sala.capacidad} personas'),
          ),
          Wrap(
            spacing: Espacio.sm,
            runSpacing: Espacio.sm,
            children: [
              for (final e in sala.equipamiento)
                Chip(label: Text(e), avatar: const Icon(Icons.check, size: 16)),
            ],
          ),
          const Divider(height: Espacio.xl * 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Disponibilidad',
                  style: tema.textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(Formatos.fechaLarga(_fecha)),
              ),
            ],
          ),
          Obx(
            () => switch (_reservas.estadoOcupacion.value) {
              EstadoCarga.cargando => const Padding(
                padding: EdgeInsets.all(Espacio.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              EstadoCarga.error => ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: tema.colorScheme.error,
                ),
                title: Text(_reservas.errorOcupacion.value),
                trailing: IconButton(
                  tooltip: 'Reintentar',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _reservas.cargarOcupacion(sala.id, _fecha),
                ),
              ),
              EstadoCarga.listo when _reservas.ocupacion.isEmpty =>
                const ListTile(
                  leading: Icon(Icons.event_available, color: Colors.green),
                  title: Text('Libre todo el día'),
                ),
              EstadoCarga.listo => Column(
                children: [
                  for (final f in _reservas.ocupacion)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        f.propia ? Icons.person : Icons.block,
                        color: f.propia
                            ? tema.colorScheme.primary
                            : tema.colorScheme.error,
                      ),
                      title: Text('${f.horaInicio} – ${f.horaFin}'),
                      subtitle: Text(f.propia ? 'Tu reserva' : 'Ocupada'),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
