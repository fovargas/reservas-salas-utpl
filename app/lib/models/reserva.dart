import '../utils/formatos.dart';

class Reserva {
  final int id;
  final String sala;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String? motivo;

  const Reserva({
    required this.id,
    required this.sala,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.motivo,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as int,
    sala: json['sala'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    horaInicio: Formatos.horaCorta(json['hora_inicio'] as String),
    horaFin: Formatos.horaCorta(json['hora_fin'] as String),
    motivo: json['motivo'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sala': sala,
    'fecha': Formatos.fechaIso(fecha),
    'hora_inicio': horaInicio,
    'hora_fin': horaFin,
    'motivo': motivo,
  };
}

class FranjaOcupada {
  final String horaInicio;
  final String horaFin;
  final bool propia;

  const FranjaOcupada({
    required this.horaInicio,
    required this.horaFin,
    required this.propia,
  });

  factory FranjaOcupada.fromJson(Map<String, dynamic> json) => FranjaOcupada(
    horaInicio: Formatos.horaCorta(json['hora_inicio'] as String),
    horaFin: Formatos.horaCorta(json['hora_fin'] as String),
    propia: json['propia'] as bool,
  );
}
