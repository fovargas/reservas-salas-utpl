import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:reservas_utpl/main.dart';
import 'package:reservas_utpl/repositories/almacen_local.dart';

import 'apoyo.dart';

void main() {
  tearDown(limpiarEntorno);

  testWidgets('sin token guardado muestra el inicio de sesión', (tester) async {
    await prepararEntorno(servidorBasico());
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();

    expect(find.text('Reservas de Salas UTPL'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('valida el formulario antes de llamar al servidor', (
    tester,
  ) async {
    final servidor = servidorBasico();
    await prepararEntorno(servidor);
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'no-es-correo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'abc',
    );
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
    expect(servidor.llamadas, isNot(contains('POST /usuarios/token')));
  });

  testWidgets('credenciales incorrectas muestran el mensaje del 401', (
    tester,
  ) async {
    final servidor = servidorBasico()
      ..en(
        'POST /usuarios/token',
        (_) => (401, {'detail': 'Credenciales inválidas'}),
      );
    await prepararEntorno(servidor);
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();

    await iniciarSesion(tester);

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('al iniciar sesión se ven las salas del backend', (tester) async {
    await prepararEntorno(servidorBasico());
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();

    await iniciarSesion(tester);

    expect(find.text('Salas del campus'), findsOneWidget);
    expect(find.text('Aula Magna'), findsOneWidget);
    expect(find.text('3 de 3 salas'), findsOneWidget);
  });

  testWidgets('el filtro por tipo deja solo los laboratorios', (tester) async {
    await prepararEntorno(servidorBasico());
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();
    await iniciarSesion(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Laboratorio'));
    await tester.pumpAndSettle();

    expect(find.text('Laboratorio de Redes'), findsOneWidget);
    expect(find.text('Aula Magna'), findsNothing);
  });

  testWidgets(
    'un error 500 muestra el estado de error y reintentar lo resuelve',
    (tester) async {
      var falla = true;
      final servidor = servidorBasico()
        ..en(
          'GET /salas/',
          (_) => falla
              ? (500, {'detail': 'Error interno del servidor'})
              : (200, salasDePrueba),
        );
      await prepararEntorno(servidor);
      await tester.pumpWidget(const ReservasApp());
      await tester.pumpAndSettle();
      await iniciarSesion(tester);

      expect(find.text('No se pudo cargar'), findsOneWidget);
      expect(find.textContaining('código 500'), findsOneWidget);

      falla = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Aula Magna'), findsOneWidget);
    },
  );

  testWidgets('la favorita se guarda en Hive', (tester) async {
    await prepararEntorno(servidorBasico());
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();
    await iniciarSesion(tester);

    await tester.tap(find.byTooltip('Agregar a favoritas').first);
    await tester.pumpAndSettle();

    expect(
      Hive.box<bool>(AlmacenLocal.cajaFavoritas).containsKey('aula_magna'),
      isTrue,
    );
    await tester.tap(find.text('Favoritas'));
    await tester.pumpAndSettle();
    expect(find.text('Aula Magna'), findsOneWidget);
  });

  testWidgets('sin reservas, Mis reservas ofrece ir a las salas', (
    tester,
  ) async {
    await prepararEntorno(servidorBasico());
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();
    await iniciarSesion(tester);

    await tester.tap(find.text('Mis reservas'));
    await tester.pumpAndSettle();
    expect(find.text('No tienes reservas próximas'), findsOneWidget);

    await tester.tap(find.text('Explorar salas'));
    await tester.pumpAndSettle();
    expect(find.text('Salas del campus'), findsOneWidget);
  });

  testWidgets('cancelar una reserva la quita de la lista', (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final fecha =
        '${manana.year}-${manana.month.toString().padLeft(2, '0')}-${manana.day.toString().padLeft(2, '0')}';
    var reservas = <Object>[
      {
        'id': 7,
        'sala': 'aula_magna',
        'fecha': fecha,
        'hora_inicio': '08:00:00',
        'hora_fin': '09:00:00',
        'motivo': 'Defensa',
      },
    ];
    final servidor = servidorBasico()
      ..en('GET /reservas/', (_) => (200, reservas))
      ..en('DELETE /reservas/7', (_) {
        reservas = [];
        return (204, null);
      });
    await prepararEntorno(servidor);
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();
    await iniciarSesion(tester);
    await tester.tap(find.text('Mis reservas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('08:00–09:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar reserva'));
    await tester.pumpAndSettle();

    expect(servidor.llamadas, contains('DELETE /reservas/7'));
    expect(find.text('No tienes reservas próximas'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('el asistente muestra la respuesta y sus salas sugeridas', (
    tester,
  ) async {
    final servidor = servidorBasico()
      ..en(
        'POST /asistente/',
        (_) => (
          200,
          {
            'respuesta': 'Te sugiero la Sala de Posgrados.',
            'modo': 'basico',
            'salas_sugeridas': ['sala_posgrados'],
          },
        ),
      );
    await prepararEntorno(servidor);
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();
    await iniciarSesion(tester);
    await tester.tap(find.text('Asistente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sala para una reunión de 10 personas'));
    await tester.pumpAndSettle();

    expect(find.text('Te sugiero la Sala de Posgrados.'), findsOneWidget);
    expect(find.text('Modo básico (sin IA)'), findsOneWidget);
    expect(
      find.widgetWithText(ActionChip, 'Sala de Posgrados'),
      findsOneWidget,
    );
  });

  testWidgets('con un token guardado abre la sesión sin pedir credenciales', (
    tester,
  ) async {
    await prepararEntorno(
      servidorBasico(),
      tokens: {'jwt_reservas_utpl': 'token-guardado'},
    );
    await tester.pumpWidget(const ReservasApp());
    await tester.pumpAndSettle();

    expect(find.text('Salas del campus'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);
  });
}
