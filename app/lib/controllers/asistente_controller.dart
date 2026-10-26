import 'package:get/get.dart';

import '../models/mensaje_asistente.dart';
import '../services/api_client.dart';
import '../services/reservas_api.dart';

class AsistenteController extends GetxController {
  AsistenteController({ReservasApi? api})
    : _api = api ?? Get.find<ReservasApi>();

  final ReservasApi _api;

  static const sugerencias = [
    'Sala para una reunión de 10 personas',
    'Necesito un laboratorio para 25 estudiantes',
    '¿Qué reservas tengo esta semana?',
  ];

  final RxList<MensajeAsistente> mensajes = <MensajeAsistente>[].obs;
  final RxBool enviando = false.obs;
  final RxString error = ''.obs;

  Future<void> enviar(String pregunta) async {
    final texto = pregunta.trim();
    if (texto.length < 3 || enviando.value) return;
    mensajes.add(MensajeAsistente(texto: texto, deUsuario: true));
    enviando.value = true;
    error.value = '';
    try {
      mensajes.add(await _api.preguntar(texto));
    } on ApiException catch (e) {
      error.value = e.mensaje;
    } finally {
      enviando.value = false;
    }
  }

  void limpiar() {
    mensajes.clear();
    error.value = '';
  }
}
