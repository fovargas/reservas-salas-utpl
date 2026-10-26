import 'package:hive_flutter/hive_flutter.dart';

import '../models/reserva.dart';
import '../models/sala.dart';

/// Persistencia local con Hive: favoritas, copia del catálogo y copia de las
/// reservas de cada usuario (para verlas sin conexión).
class AlmacenLocal {
  static const cajaFavoritas = 'favoritas';
  static const cajaCache = 'cache';

  static Future<void> abrir() async {
    await Hive.initFlutter();
    await Hive.openBox<bool>(cajaFavoritas);
    await Hive.openBox<List>(cajaCache);
  }

  Box<bool> get _favoritas => Hive.box<bool>(cajaFavoritas);
  Box<List> get _cache => Hive.box<List>(cajaCache);

  Set<String> favoritas() => _favoritas.keys.cast<String>().toSet();

  Future<void> alternarFavorita(String salaId) => _favoritas.containsKey(salaId)
      ? _favoritas.delete(salaId)
      : _favoritas.put(salaId, true);

  List<Sala> salasGuardadas() => (_cache.get('salas') ?? const [])
      .map((e) => Sala.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  Future<void> guardarSalas(List<Sala> salas) =>
      _cache.put('salas', salas.map((s) => s.toJson()).toList());

  List<Reserva> reservasGuardadas(String email) =>
      (_cache.get('reservas:$email') ?? const [])
          .map((e) => Reserva.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  Future<void> guardarReservas(String email, List<Reserva> reservas) =>
      _cache.put('reservas:$email', reservas.map((r) => r.toJson()).toList());

  Future<void> borrarReservas(String email) => _cache.delete('reservas:$email');
}
