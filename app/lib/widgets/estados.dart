import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EstadoCargando extends StatelessWidget {
  const EstadoCargando({super.key, this.texto = 'Cargando…'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Espacio.md),
          Text(texto),
        ],
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return _Centrado(
      children: [
        Icon(icono, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: Espacio.md),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (detalle != null) ...[
          const SizedBox(height: Espacio.xs),
          Text(detalle!, textAlign: TextAlign.center),
        ],
        if (accion != null) ...[const SizedBox(height: Espacio.lg), accion!],
      ],
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({
    super.key,
    required this.mensaje,
    required this.alReintentar,
  });

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return _Centrado(
      children: [
        Icon(Icons.cloud_off, size: 64, color: color),
        const SizedBox(height: Espacio.md),
        Text(
          'No se pudo cargar',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color),
        ),
        const SizedBox(height: Espacio.xs),
        Text(mensaje, textAlign: TextAlign.center),
        const SizedBox(height: Espacio.lg),
        FilledButton.icon(
          onPressed: alReintentar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}

class AvisoSinConexion extends StatelessWidget {
  const AvisoSinConexion({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(texto),
      leading: const Icon(Icons.wifi_off),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      actions: const [SizedBox.shrink()],
    );
  }
}

class _Centrado extends StatelessWidget {
  const _Centrado({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Espacio.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
