/// Dirección del backend. Se cambia al compilar con
/// `--dart-define=API_BASE_URL=...`; por defecto es cómo el emulador Android
/// ve el `localhost` del computador.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
