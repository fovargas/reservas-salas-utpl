import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/salas_controller.dart';
import '../models/mensaje_asistente.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_cuenta.dart';
import 'sala_detalle_screen.dart';

class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _c = Get.find<AsistenteController>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar([String? sugerencia]) {
    final pregunta = sugerencia ?? _texto.text;
    if (pregunta.trim().length < 3) return;
    _texto.clear();
    _c.enviar(pregunta);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de reservas'),
        actions: const [MenuCuenta()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final mensajes = _c.mensajes;
              if (mensajes.isEmpty &&
                  !_c.enviando.value &&
                  _c.error.value.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(Espacio.xl),
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(height: Espacio.md),
                    Text(
                      'Pregúntame qué sala te conviene',
                      style: tema.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Espacio.xs),
                    const Text(
                      'Conozco el catálogo del campus y la ocupación de los próximos 7 días. '
                      'No reservo por ti: te sugiero salas y tú confirmas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Espacio.lg),
                    for (final s in AsistenteController.sugerencias)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Espacio.sm),
                        child: ActionChip(
                          label: Text(s),
                          onPressed: () => _enviar(s),
                        ),
                      ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(Espacio.lg),
                children: [
                  for (final m in mensajes) _Burbuja(mensaje: m),
                  if (_c.enviando.value)
                    const Padding(
                      padding: EdgeInsets.all(Espacio.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: Espacio.sm),
                          Text('Pensando…'),
                        ],
                      ),
                    ),
                  if (_c.error.value.isNotEmpty)
                    Card(
                      color: tema.colorScheme.errorContainer,
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(_c.error.value),
                        trailing: TextButton(
                          onPressed: () {
                            final ultima = mensajes
                                .where((m) => m.deUsuario)
                                .lastOrNull;
                            if (ultima != null) {
                              mensajes.remove(ultima);
                              _c.enviar(ultima.texto);
                            }
                          },
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Espacio.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu pregunta',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: Espacio.sm),
                  Obx(
                    () => IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: _c.enviando.value ? null : _enviar,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeAsistente mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final salas = Get.find<SalasController>();
    final propio = mensaje.deUsuario;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: Espacio.sm),
        padding: const EdgeInsets.all(Espacio.md),
        decoration: BoxDecoration(
          color: propio
              ? tema.colorScheme.primary
              : tema.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje.texto,
              style: TextStyle(
                color: propio ? tema.colorScheme.onPrimary : null,
              ),
            ),
            if (!propio) ...[
              const SizedBox(height: Espacio.xs),
              Text(
                mensaje.modo == 'ia'
                    ? 'Respuesta con IA (Gemini)'
                    : 'Modo básico (sin IA)',
                style: tema.textTheme.labelSmall,
              ),
              if (mensaje.salasSugeridas.isNotEmpty)
                Wrap(
                  spacing: Espacio.xs,
                  children: [
                    for (final id in mensaje.salasSugeridas)
                      if (salas.porId(id) case final sala?)
                        ActionChip(
                          avatar: const Icon(Icons.meeting_room, size: 16),
                          label: Text(sala.nombre),
                          onPressed: () =>
                              Get.to(() => SalaDetalleScreen(sala: sala)),
                        ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
