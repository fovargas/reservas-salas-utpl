import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/navegacion_controller.dart';
import 'controllers/reservas_controller.dart';
import 'controllers/salas_controller.dart';
import 'repositories/almacen_local.dart';
import 'screens/inicio_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/reservas_api.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';
import 'utils/reporte_errores.dart';
import 'widgets/estados.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReporteErrores.instalar();
  await AlmacenLocal.abrir();
  registrarDependencias();
  runApp(const ReservasApp());
}

/// Registra servicios y controladores una sola vez. Las pruebas pasan sus
/// propias versiones (servidor falso, almacenamiento en memoria).
void registrarDependencias({ApiClient? cliente, TokenStorage? tokens}) {
  final api = Get.put(cliente ?? ApiClient(), permanent: true);
  Get.put(ReservasApi(api), permanent: true);
  Get.put(AlmacenLocal(), permanent: true);
  final nav = Get.put(NavegacionController(), permanent: true);
  final reservas = Get.put(ReservasController(), permanent: true);
  Get.put(AsistenteController(), permanent: true);
  final auth = Get.put(AuthController(almacen: tokens), permanent: true);
  Get.put(SalasController(), permanent: true);
  ever<String?>(auth.email, (correo) {
    if (correo != null) {
      nav.ir(0);
      reservas.cargar(correo);
    }
  });
}

class ReservasApp extends StatelessWidget {
  const ReservasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Reservas UTPL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      locale: const Locale('es', 'EC'),
      supportedLocales: const [Locale('es', 'EC'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Raiz(),
    );
  }
}

class Raiz extends StatelessWidget {
  const Raiz({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.restaurando.value) {
        return const Scaffold(
          body: EstadoCargando(texto: 'Abriendo tu sesión…'),
        );
      }
      return auth.autenticado ? const InicioShell() : const LoginScreen();
    });
  }
}
