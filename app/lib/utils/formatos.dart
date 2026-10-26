class Formatos {
  Formatos._();

  static const _dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String fechaIso(DateTime f) =>
      '${f.year}-${_dos(f.month)}-${_dos(f.day)}';

  /// «lunes 26 de octubre».
  static String fechaLarga(DateTime f) =>
      '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]}';

  /// «08:00:00» → «08:00».
  static String horaCorta(String hora) =>
      hora.length >= 5 ? hora.substring(0, 5) : hora;

  static String horaDe(int hora, int minuto) => '${_dos(hora)}:${_dos(minuto)}';

  static String etiquetaTipo(String tipo) => switch (tipo) {
    'reuniones' => 'Reuniones',
    'auditorio' => 'Auditorio',
    'laboratorio' => 'Laboratorio',
    'estudio' => 'Estudio',
    'aula' => 'Aula',
    'multimedia' => 'Multimedia',
    _ => tipo,
  };
}
