import 'package:get/get.dart';

import '../models/sala.dart';
import '../repositories/almacen_local.dart';
import '../services/api_client.dart';
import '../services/reservas_api.dart';
import '../utils/estado_carga.dart';

class SalasController extends GetxController {
  SalasController({ReservasApi? api, AlmacenLocal? almacen})
    : _api = api ?? Get.find<ReservasApi>(),
      _almacen = almacen ?? Get.find<AlmacenLocal>();

  final ReservasApi _api;
  final AlmacenLocal _almacen;

  final RxList<Sala> salas = <Sala>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;
  final RxBool desdeCache = false.obs;
  final RxString busqueda = ''.obs;
  final Rxn<String> tipo = Rxn<String>();
  final RxSet<String> favoritas = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    favoritas.addAll(_almacen.favoritas());
    cargar();
  }

  List<String> get tipos => salas.map((s) => s.tipo).toSet().toList()..sort();

  List<Sala> get filtradas {
    final texto = busqueda.value.trim().toLowerCase();
    return salas.where((s) {
      final coincideTipo = tipo.value == null || s.tipo == tipo.value;
      final coincideTexto =
          texto.isEmpty ||
          s.nombre.toLowerCase().contains(texto) ||
          s.edificio.toLowerCase().contains(texto);
      return coincideTipo && coincideTexto;
    }).toList();
  }

  List<Sala> get salasFavoritas =>
      salas.where((s) => favoritas.contains(s.id)).toList();

  Sala? porId(String id) => salas.firstWhereOrNull((s) => s.id == id);

  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    try {
      final lista = await _api.salas();
      salas.assignAll(lista);
      desdeCache.value = false;
      await _almacen.guardarSalas(lista);
      estado.value = EstadoCarga.listo;
    } on ApiException catch (e) {
      final guardadas = _almacen.salasGuardadas();
      mensajeError.value = e.mensaje;
      if (guardadas.isEmpty) {
        estado.value = EstadoCarga.error;
      } else {
        salas.assignAll(guardadas);
        desdeCache.value = true;
        estado.value = EstadoCarga.listo;
      }
    }
  }

  Future<void> alternarFavorita(String salaId) async {
    await _almacen.alternarFavorita(salaId);
    favoritas.contains(salaId)
        ? favoritas.remove(salaId)
        : favoritas.add(salaId);
  }
}
