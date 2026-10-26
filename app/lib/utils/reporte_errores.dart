import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Un solo lugar para los errores no controlados: se registran sin tokens y
/// la persona ve un aviso amistoso en vez de la pantalla roja.
class ReporteErrores {
  ReporteErrores._();

  static String limpiar(String texto) => texto
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'), 'Bearer ***')
      .replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'),
        '***',
      );

  static void registrar(Object error, StackTrace? pila) {
    debugPrint(
      '[ReservasUTPL] error no controlado -> ${limpiar('${error.runtimeType}: $error')}',
    );
  }

  static void instalar() {
    FlutterError.onError = (detalles) {
      FlutterError.presentError(detalles);
      registrar(detalles.exception, detalles.stack);
    };
    PlatformDispatcher.instance.onError = (error, pila) {
      registrar(error, pila);
      try {
        if (Get.key.currentState != null) {
          Get.snackbar(
            'Algo salió mal',
            'Ya registramos el problema. Puedes seguir usando la app.',
          );
        }
      } catch (_) {}
      return true;
    };
    ErrorWidget.builder = (_) => const _VistaErrorPantalla();
  }
}

class _VistaErrorPantalla extends StatelessWidget {
  const _VistaErrorPantalla();

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Esta pantalla tuvo un problema. Vuelve atrás e inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
