import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

export 'package:dio/dio.dart' show Headers, Options;

export 'api_exception.dart';

/// Único cliente HTTP de la app: agrega el token y avisa cuando caduca.
class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, siguiente) {
          final t = token;
          if (t != null) opciones.headers['Authorization'] = 'Bearer $t';
          siguiente.next(opciones);
        },
        onError: (error, siguiente) {
          final esLogin = error.requestOptions.path == '/usuarios/token';
          if (error.response?.statusCode == 401 && !esLogin) {
            alSesionCaducada?.call();
          }
          siguiente.next(error);
        },
      ),
    );
  }

  final Dio dio;

  /// Token en memoria; entre aperturas lo guarda `TokenStorage`.
  String? token;

  void Function()? alSesionCaducada;

  Future<Response<dynamic>> get(String ruta, {Map<String, dynamic>? query}) =>
      _enviar(() => dio.get(ruta, queryParameters: query));

  Future<Response<dynamic>> post(
    String ruta, {
    Object? data,
    Options? options,
  }) => _enviar(() => dio.post(ruta, data: data, options: options));

  Future<Response<dynamic>> delete(String ruta) =>
      _enviar(() => dio.delete(ruta));

  Future<Response<dynamic>> _enviar(
    Future<Response<dynamic>> Function() peticion,
  ) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw ApiException.desde(e);
    }
  }
}
