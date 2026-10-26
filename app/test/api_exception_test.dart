import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reservas_utpl/services/api_exception.dart';
import 'package:reservas_utpl/utils/reporte_errores.dart';

ApiException conCodigo(
  int codigo,
  Object? datos, {
  String ruta = '/reservas/',
}) {
  final opciones = RequestOptions(path: ruta);
  return ApiException.desde(
    DioException.badResponse(
      statusCode: codigo,
      requestOptions: opciones,
      response: Response(
        requestOptions: opciones,
        statusCode: codigo,
        data: datos,
      ),
    ),
  );
}

void main() {
  test('400 muestra el motivo del servidor', () {
    final e = conCodigo(400, {
      'detail': "La sala 'aula_magna' ya está reservada en ese horario",
    });
    expect(e.mensaje, contains('ya está reservada'));
  });

  test('401 fuera del login es sesión caducada', () {
    expect(
      conCodigo(401, {'detail': 'x'}).mensaje,
      'Tu sesión caducó. Inicia sesión de nuevo.',
    );
  });

  test('401 en el login es credenciales incorrectas', () {
    expect(
      conCodigo(401, null, ruta: '/usuarios/token').mensaje,
      'Correo o contraseña incorrectos.',
    );
  });

  test('403 y 422 tienen mensajes propios', () {
    expect(
      conCodigo(403, {'detail': 'x'}).mensaje,
      'No tienes permiso para esta acción.',
    );
    final e422 = conCodigo(422, {
      'detail': [
        {
          'loc': ['body', 'pregunta'],
          'msg': 'String should have at least 3 characters',
        },
      ],
    });
    expect(e422.mensaje, startsWith('Revisa los datos: pregunta:'));
  });

  test('5xx no expone el detalle técnico', () {
    final e = conCodigo(503, {'detail': 'Traceback ...'});
    expect(
      e.mensaje,
      'El servidor tuvo un problema (código 503). Inténtalo más tarde.',
    );
  });

  test('sin conexión no tiene código', () {
    final e = ApiException.desde(
      DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'x',
      ),
    );
    expect(e.statusCode, isNull);
    expect(e.mensaje, startsWith('Sin conexión'));
  });

  test('limpiar quita tokens de los registros', () {
    const texto = 'Authorization: Bearer eyJhbGciOi.eyJzdWIiOi.abc123';
    expect(ReporteErrores.limpiar(texto), isNot(contains('eyJ')));
  });
}
