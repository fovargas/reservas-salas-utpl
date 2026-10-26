import 'dart:io';

import 'package:dio/dio.dart';

/// Error de red o HTTP traducido a un mensaje para la persona. `statusCode`
/// es null cuando no hubo respuesta (sin conexión, tiempo agotado).
class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;

  ApiException(this.mensaje, {this.statusCode});

  bool get sinConexion => statusCode == null;

  factory ApiException.desde(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
        );
      case DioExceptionType.badResponse:
        return _desdeRespuesta(e.response!, e.requestOptions.path);
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.error is SocketException) {
          return ApiException(
            'Sin conexión con el servidor. Revisa tu red y que el backend esté encendido.',
          );
        }
        return ApiException(
          'No se pudo completar la petición. Inténtalo de nuevo.',
        );
    }
  }

  static ApiException _desdeRespuesta(Response<dynamic> r, String ruta) {
    final codigo = r.statusCode ?? 0;
    final detail = r.data is Map ? (r.data as Map)['detail'] : null;
    switch (codigo) {
      case 401:
        // En el login, 401 es «credenciales incorrectas»; en el resto, token vencido.
        if (ruta == '/usuarios/token') {
          return ApiException(
            'Correo o contraseña incorrectos.',
            statusCode: 401,
          );
        }
        return ApiException(
          'Tu sesión caducó. Inicia sesión de nuevo.',
          statusCode: 401,
        );
      case 403:
        return ApiException(
          'No tienes permiso para esta acción.',
          statusCode: 403,
        );
      case 404:
        return ApiException(
          detail is String ? detail : 'No se encontró lo que buscabas.',
          statusCode: 404,
        );
      case 422:
        return ApiException(
          'Revisa los datos: ${_detalle422(detail)}',
          statusCode: 422,
        );
      case 400:
        return ApiException(
          detail is String ? detail : 'La solicitud no es válida.',
          statusCode: 400,
        );
    }
    if (codigo >= 500) {
      return ApiException(
        'El servidor tuvo un problema (código $codigo). Inténtalo más tarde.',
        statusCode: codigo,
      );
    }
    return ApiException(
      'La petición no pudo completarse (código $codigo).',
      statusCode: codigo,
    );
  }

  static String _detalle422(Object? detail) {
    if (detail is! List) return 'hay campos con formato incorrecto.';
    return detail
        .whereType<Map>()
        .map((e) {
          final loc = e['loc'];
          final campo = loc is List && loc.isNotEmpty ? '${loc.last}' : 'dato';
          return '$campo: ${e['msg']}';
        })
        .join('; ');
  }

  @override
  String toString() => mensaje;
}
