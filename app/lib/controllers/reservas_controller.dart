import 'package:get/get.dart';

import '../models/reserva.dart';
import '../repositories/almacen_local.dart';
import '../services/api_client.dart';
import '../services/reservas_api.dart';
import '../utils/estado_carga.dart';

class ReservasController extends GetxController {
  ReservasController({ReservasApi? api, AlmacenLocal? almacen})
    : _api = api ?? Get.find<ReservasApi>(),
      _almacen = almacen ?? Get.find<AlmacenLocal>();

  final ReservasApi _api;
  final AlmacenLocal _almacen;

  final RxList<Reserva> reservas = <Reserva>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;
  final RxBool desdeCache = false.obs;

  final RxList<FranjaOcupada> ocupacion = <FranjaOcupada>[].obs;
  final Rx<EstadoCarga> estadoOcupacion = EstadoCarga.cargando.obs;
  final RxString errorOcupacion = ''.obs;

  final RxBool guardando = false.obs;
  final RxString errorFormulario = ''.obs;

  /// Reservas de hoy en adelante, ordenadas.
  List<Reserva> get proximas {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    return reservas.where((r) => !r.fecha.isBefore(inicioHoy)).toList()..sort(
      (a, b) => a.fecha.compareTo(b.fecha) != 0
          ? a.fecha.compareTo(b.fecha)
          : a.horaInicio.compareTo(b.horaInicio),
    );
  }

  Future<void> cargar(String email) async {
    estado.value = EstadoCarga.cargando;
    try {
      final lista = await _api.misReservas();
      reservas.assignAll(lista);
      desdeCache.value = false;
      await _almacen.guardarReservas(email, lista);
      estado.value = EstadoCarga.listo;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      if (e.statusCode == 401) {
        estado.value = EstadoCarga.error;
        return;
      }
      final guardadas = _almacen.reservasGuardadas(email);
      if (guardadas.isEmpty && e.statusCode != null) {
        estado.value = EstadoCarga.error;
      } else {
        reservas.assignAll(guardadas);
        desdeCache.value = true;
        estado.value = guardadas.isEmpty
            ? EstadoCarga.error
            : EstadoCarga.listo;
      }
    }
  }

  Future<void> cargarOcupacion(String salaId, DateTime fecha) async {
    estadoOcupacion.value = EstadoCarga.cargando;
    try {
      ocupacion.assignAll(await _api.ocupacion(salaId, fecha));
      estadoOcupacion.value = EstadoCarga.listo;
    } on ApiException catch (e) {
      errorOcupacion.value = e.mensaje;
      estadoOcupacion.value = EstadoCarga.error;
    }
  }

  /// Devuelve true si el servidor aceptó la reserva.
  Future<bool> crear({
    required String email,
    required String sala,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    String? motivo,
  }) async {
    guardando.value = true;
    errorFormulario.value = '';
    try {
      final nueva = await _api.crearReserva(
        sala: sala,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        motivo: motivo,
      );
      reservas.add(nueva);
      await _almacen.guardarReservas(email, reservas);
      return true;
    } on ApiException catch (e) {
      errorFormulario.value = e.mensaje;
      return false;
    } finally {
      guardando.value = false;
    }
  }

  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> cancelar(String email, int id) async {
    try {
      await _api.cancelarReserva(id);
      reservas.removeWhere((r) => r.id == id);
      await _almacen.guardarReservas(email, reservas);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<void> limpiar(String email) async {
    reservas.clear();
    ocupacion.clear();
    await _almacen.borrarReservas(email);
  }
}
