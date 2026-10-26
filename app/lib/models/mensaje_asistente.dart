class MensajeAsistente {
  final String texto;
  final bool deUsuario;

  /// `ia` (Gemini) o `basico` (reglas del servidor, sin modelo).
  final String? modo;
  final List<String> salasSugeridas;

  const MensajeAsistente({
    required this.texto,
    required this.deUsuario,
    this.modo,
    this.salasSugeridas = const [],
  });

  factory MensajeAsistente.desdeRespuesta(Map<String, dynamic> json) =>
      MensajeAsistente(
        texto: json['respuesta'] as String,
        deUsuario: false,
        modo: json['modo'] as String?,
        salasSugeridas: List<String>.from(
          json['salas_sugeridas'] as List? ?? const [],
        ),
      );
}
