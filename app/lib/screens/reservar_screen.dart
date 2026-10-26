import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/reservas_controller.dart';
import '../models/sala.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';

class ReservarScreen extends StatefulWidget {
  const ReservarScreen({super.key, required this.sala, required this.fecha});

  final Sala sala;
  final DateTime fecha;

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  final _reservas = Get.find<ReservasController>();
  final _motivo = TextEditingController();
  late DateTime _fecha = widget.fecha;
  TimeOfDay _inicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 9, minute: 0);
  String _errorLocal = '';

  @override
  void initState() {
    super.initState();
    _reservas.errorFormulario.value = '';
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _elegirHora(bool inicio) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: inicio ? _inicio : _fin,
    );
    if (elegida == null) return;
    setState(() => inicio ? _inicio = elegida : _fin = elegida);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 90)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (_minutos(_fin) <= _minutos(_inicio)) {
      setState(
        () => _errorLocal = 'La hora de fin debe ser posterior a la de inicio.',
      );
      return;
    }
    setState(() => _errorLocal = '');
    final ok = await _reservas.crear(
      email: Get.find<AuthController>().email.value!,
      sala: widget.sala.id,
      fecha: _fecha,
      horaInicio: Formatos.horaDe(_inicio.hour, _inicio.minute),
      horaFin: Formatos.horaDe(_fin.hour, _fin.minute),
      motivo: _motivo.text.trim(),
    );
    if (ok) {
      Get.back(result: true);
      Get.snackbar(
        'Reserva confirmada',
        '${widget.sala.nombre}, ${Formatos.fechaLarga(_fecha)}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: ListView(
        padding: const EdgeInsets.all(Espacio.lg),
        children: [
          Text(widget.sala.nombre, style: tema.textTheme.titleLarge),
          Text(widget.sala.edificio),
          const SizedBox(height: Espacio.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Fecha'),
            subtitle: Text(Formatos.fechaLarga(_fecha)),
            onTap: _elegirFecha,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Hora de inicio'),
            subtitle: Text(Formatos.horaDe(_inicio.hour, _inicio.minute)),
            onTap: () => _elegirHora(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Hora de fin'),
            subtitle: Text(Formatos.horaDe(_fin.hour, _fin.minute)),
            onTap: () => _elegirHora(false),
          ),
          const SizedBox(height: Espacio.sm),
          TextField(
            controller: _motivo,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Reunión de coordinación',
            ),
          ),
          Obx(() {
            final error = _errorLocal.isNotEmpty
                ? _errorLocal
                : _reservas.errorFormulario.value;
            return error.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: Espacio.md),
                    child: Text(
                      error,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                  );
          }),
          Obx(
            () => FilledButton.icon(
              onPressed: _reservas.guardando.value ? null : _guardar,
              icon: _reservas.guardando.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Confirmar reserva'),
            ),
          ),
        ],
      ),
    );
  }
}
