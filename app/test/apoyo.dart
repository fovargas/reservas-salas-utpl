import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:reservas_utpl/main.dart';
import 'package:reservas_utpl/repositories/almacen_local.dart';
import 'package:reservas_utpl/services/api_client.dart';

typedef Respuesta = (int, Object?);

/// Servidor falso: responde según «MÉTODO /ruta» sin red real.
class ServidorFalso implements HttpClientAdapter {
  final Map<String, Respuesta Function(RequestOptions)> rutas = {};
  final List<String> llamadas = [];

  void en(String clave, Respuesta Function(RequestOptions) respuesta) =>
      rutas[clave] = respuesta;

  @override
  Future<ResponseBody> fetch(
    RequestOptions opciones,
    Stream<Uint8List>? cuerpo,
    Future<void>? cancelar,
  ) async {
    final clave = '${opciones.method} ${opciones.path}';
    llamadas.add(clave);
    final manejador = rutas[clave];
    if (manejador == null) {
      throw DioException.connectionError(
        requestOptions: opciones,
        reason: 'sin ruta $clave',
      );
    }
    final (codigo, datos) = manejador(opciones);
    return ResponseBody.fromString(
      datos == null ? '' : jsonEncode(datos),
      codigo,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const salasDePrueba = [
  {
    'id': 'aula_magna',
    'nombre': 'Aula Magna',
    'edificio': 'Edificio Central',
    'tipo': 'auditorio',
    'capacidad': 400,
    'equipamiento': ['proyector'],
  },
  {
    'id': 'laboratorio_redes',
    'nombre': 'Laboratorio de Redes',
    'edificio': 'Edificio de Laboratorios',
    'tipo': 'laboratorio',
    'capacidad': 24,
    'equipamiento': ['computadores'],
  },
  {
    'id': 'sala_posgrados',
    'nombre': 'Sala de Posgrados',
    'edificio': 'Edificio de Posgrados',
    'tipo': 'reuniones',
    'capacidad': 20,
    'equipamiento': ['videoconferencia'],
  },
];

/// Servidor con sesión válida, catálogo y sin reservas.
ServidorFalso servidorBasico() => ServidorFalso()
  ..en(
    'POST /usuarios/token',
    (_) => (200, {'access_token': 'token-de-prueba', 'token_type': 'bearer'}),
  )
  ..en('GET /usuarios/me', (_) => (200, {'id': 1, 'email': 'ana@utpl.edu.ec'}))
  ..en('GET /salas/', (_) => (200, salasDePrueba))
  ..en('GET /reservas/', (_) => (200, <Object>[]));

Future<void> prepararEntorno(
  ServidorFalso servidor, {
  Map<String, String> tokens = const {},
}) async {
  Get.reset();
  FlutterSecureStorage.setMockInitialValues(Map.of(tokens));
  await Hive.openBox<bool>(AlmacenLocal.cajaFavoritas, bytes: Uint8List(0));
  await Hive.openBox<List>(AlmacenLocal.cajaCache, bytes: Uint8List(0));
  final dio = Dio(BaseOptions(baseUrl: 'http://servidor.falso'))
    ..httpClientAdapter = servidor;
  registrarDependencias(cliente: ApiClient(dio: dio));
}

Future<void> limpiarEntorno() async {
  Get.reset();
  await Hive.close();
}

Future<void> iniciarSesion(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo'),
    'ana@utpl.edu.ec',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    'clave-segura-1',
  );
  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle();
}
