import 'package:get/get.dart';

import '../services/api_client.dart';
import '../services/reservas_api.dart';
import '../services/token_storage.dart';
import 'asistente_controller.dart';
import 'reservas_controller.dart';

class AuthController extends GetxController {
  AuthController({ApiClient? cliente, ReservasApi? api, TokenStorage? almacen})
    : _cliente = cliente ?? Get.find<ApiClient>(),
      _api = api ?? Get.find<ReservasApi>(),
      _almacen = almacen ?? TokenStorage();

  final ApiClient _cliente;
  final ReservasApi _api;
  final TokenStorage _almacen;

  final Rxn<String> email = Rxn<String>();
  final RxBool cargando = false.obs;
  final RxBool restaurando = true.obs;
  final RxString mensajeError = ''.obs;
  final RxString aviso = ''.obs;

  bool get autenticado => email.value != null;

  @override
  void onInit() {
    super.onInit();
    _cliente.alSesionCaducada = sesionCaducada;
    restaurarSesion();
  }

  Future<void> registrar(String correo, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _api.registrar(correo, password);
      await iniciarSesion(correo, password);
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> iniciarSesion(String correo, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      final token = await _api.iniciarSesion(correo, password);
      _cliente.token = token;
      await _almacen.guardar(token);
      email.value = await _api.usuarioActual();
      aviso.value = '';
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  /// Con un token guardado, lo valida con /usuarios/me. Sin conexión no se
  /// borra: puede seguir siendo válido.
  Future<void> restaurarSesion() async {
    restaurando.value = true;
    try {
      final guardado = await _almacen.leer();
      if (guardado == null) return;
      _cliente.token = guardado;
      email.value = await _api.usuarioActual();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await cerrarSesion();
        aviso.value = e.mensaje;
      } else {
        _cliente.token = null;
        aviso.value = e.mensaje;
      }
    } finally {
      restaurando.value = false;
    }
  }

  Future<void> sesionCaducada() async {
    if (!autenticado) return;
    await cerrarSesion();
    aviso.value = 'Tu sesión caducó. Inicia sesión de nuevo.';
    if (Get.key.currentState != null) Get.until((ruta) => ruta.isFirst);
  }

  /// Borra el token y los datos del usuario en este teléfono.
  Future<void> cerrarSesion() async {
    final correo = email.value;
    if (correo != null && Get.isRegistered<ReservasController>()) {
      await Get.find<ReservasController>().limpiar(correo);
    }
    if (Get.isRegistered<AsistenteController>()) {
      Get.find<AsistenteController>().limpiar();
    }
    await _almacen.borrar();
    _cliente.token = null;
    email.value = null;
  }
}
