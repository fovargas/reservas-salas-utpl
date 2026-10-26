import '../models/mensaje_asistente.dart';
import '../models/reserva.dart';
import '../models/sala.dart';
import '../utils/formatos.dart';
import 'api_client.dart';

/// Endpoints del backend de reservas. Las pantallas nunca llaman HTTP: pasan
/// por un controlador, que usa este servicio.
class ReservasApi {
  ReservasApi(this._api);

  final ApiClient _api;

  Future<void> registrar(String email, String password) =>
      _api.post('/usuarios/', data: {'email': email, 'password': password});

  Future<String> iniciarSesion(String email, String password) async {
    final r = await _api.post(
      '/usuarios/token',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return (r.data as Map)['access_token'] as String;
  }

  Future<String> usuarioActual() async {
    final r = await _api.get('/usuarios/me');
    return (r.data as Map)['email'] as String;
  }

  Future<List<Sala>> salas() async {
    final r = await _api.get('/salas/');
    return (r.data as List)
        .map((e) => Sala.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FranjaOcupada>> ocupacion(String salaId, DateTime fecha) async {
    final r = await _api.get(
      '/salas/$salaId/ocupacion',
      query: {'fecha': Formatos.fechaIso(fecha)},
    );
    return (r.data as List)
        .map((e) => FranjaOcupada.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Reserva>> misReservas() async {
    final r = await _api.get('/reservas/', query: {'limit': 100});
    return (r.data as List)
        .map((e) => Reserva.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Reserva> crearReserva({
    required String sala,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    String? motivo,
  }) async {
    final r = await _api.post(
      '/reservas/',
      data: {
        'sala': sala,
        'fecha': Formatos.fechaIso(fecha),
        'hora_inicio': '$horaInicio:00',
        'hora_fin': '$horaFin:00',
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      },
    );
    return Reserva.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> cancelarReserva(int id) => _api.delete('/reservas/$id');

  Future<MensajeAsistente> preguntar(String pregunta) async {
    final r = await _api.post('/asistente/', data: {'pregunta': pregunta});
    return MensajeAsistente.desdeRespuesta(
      Map<String, dynamic>.from(r.data as Map),
    );
  }
}
