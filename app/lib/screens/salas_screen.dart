import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/salas_controller.dart';
import '../theme/app_theme.dart';
import '../utils/estado_carga.dart';
import '../utils/formatos.dart';
import '../widgets/estados.dart';
import '../widgets/menu_cuenta.dart';
import '../widgets/sala_card.dart';

class SalasScreen extends StatelessWidget {
  const SalasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SalasController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas del campus'),
        actions: const [MenuCuenta()],
      ),
      body: Obx(() {
        if (c.estado.value == EstadoCarga.cargando) {
          return const EstadoCargando(texto: 'Cargando salas…');
        }
        if (c.estado.value == EstadoCarga.error) {
          return EstadoError(
            mensaje: c.mensajeError.value,
            alReintentar: c.cargar,
          );
        }
        final lista = c.filtradas;
        return RefreshIndicator(
          onRefresh: c.cargar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (c.desdeCache.value)
                const SliverToBoxAdapter(
                  child: AvisoSinConexion(
                    texto: 'Sin conexión — mostrando el catálogo guardado',
                  ),
                ),
              SliverToBoxAdapter(child: _Filtros(c: c)),
              if (lista.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoVacio(
                    icono: Icons.search_off,
                    titulo: 'Ninguna sala coincide',
                    detalle: 'Prueba con otra búsqueda o quita el filtro.',
                    accion: OutlinedButton(
                      onPressed: () {
                        c.busqueda.value = '';
                        c.tipo.value = null;
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) => SalaCard(sala: lista[i]),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: Espacio.lg)),
            ],
          ),
        );
      }),
    );
  }
}

class _Filtros extends StatefulWidget {
  const _Filtros({required this.c});

  final SalasController c;

  @override
  State<_Filtros> createState() => _FiltrosState();
}

class _FiltrosState extends State<_Filtros> {
  late final TextEditingController _texto = TextEditingController(
    text: widget.c.busqueda.value,
  );

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    if (c.busqueda.value.isEmpty && _texto.text.isNotEmpty) _texto.clear();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.lg,
        Espacio.md,
        Espacio.lg,
        Espacio.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _texto,
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o edificio',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => c.busqueda.value = v,
          ),
          const SizedBox(height: Espacio.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(c, 'Todas', null),
                for (final t in c.tipos) _chip(c, Formatos.etiquetaTipo(t), t),
              ],
            ),
          ),
          Text(
            '${c.filtradas.length} de ${c.salas.length} salas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _chip(SalasController c, String etiqueta, String? tipo) => Padding(
    padding: const EdgeInsets.only(right: Espacio.sm),
    child: ChoiceChip(
      label: Text(etiqueta),
      selected: c.tipo.value == tipo,
      onSelected: (_) => c.tipo.value = tipo,
    ),
  );
}
