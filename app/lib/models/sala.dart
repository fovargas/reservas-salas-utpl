class Sala {
  final String id;
  final String nombre;
  final String edificio;
  final String tipo;
  final int capacidad;
  final List<String> equipamiento;

  const Sala({
    required this.id,
    required this.nombre,
    required this.edificio,
    required this.tipo,
    required this.capacidad,
    required this.equipamiento,
  });

  factory Sala.fromJson(Map<String, dynamic> json) => Sala(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    edificio: json['edificio'] as String,
    tipo: json['tipo'] as String,
    capacidad: json['capacidad'] as int,
    equipamiento: List<String>.from(json['equipamiento'] as List),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'edificio': edificio,
    'tipo': tipo,
    'capacidad': capacidad,
    'equipamiento': equipamiento,
  };
}
