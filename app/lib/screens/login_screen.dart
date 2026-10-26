import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _registro = false;
  bool _ocultar = true;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _enviar(AuthController auth) {
    if (!_formulario.currentState!.validate()) return;
    final correo = _correo.text.trim();
    _registro
        ? auth.registrar(correo, _clave.text)
        : auth.iniciarSesion(correo, _clave.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacio.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 72,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(height: Espacio.sm),
                    Text(
                      'Reservas de Salas UTPL',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Espacio.xs),
                    Text(
                      _registro
                          ? 'Crea tu cuenta'
                          : 'Inicia sesión para reservar un espacio del campus',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Espacio.xl),
                    Obx(
                      () => auth.aviso.value.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                bottom: Espacio.md,
                              ),
                              child: Text(
                                auth.aviso.value,
                                style: TextStyle(
                                  color: tema.colorScheme.tertiary,
                                ),
                              ),
                            ),
                    ),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          v != null &&
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v.trim())
                          ? null
                          : 'Escribe un correo válido',
                    ),
                    const SizedBox(height: Espacio.md),
                    TextFormField(
                      controller: _clave,
                      obscureText: _ocultar,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultar
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _ocultar ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 8
                          ? null
                          : 'Mínimo 8 caracteres',
                      onFieldSubmitted: (_) => _enviar(auth),
                    ),
                    const SizedBox(height: Espacio.md),
                    Obx(
                      () => auth.mensajeError.value.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                bottom: Espacio.md,
                              ),
                              child: Text(
                                auth.mensajeError.value,
                                style: TextStyle(color: tema.colorScheme.error),
                              ),
                            ),
                    ),
                    Obx(
                      () => FilledButton(
                        onPressed: auth.cargando.value
                            ? null
                            : () => _enviar(auth),
                        child: auth.cargando.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_registro ? 'Crear cuenta' : 'Ingresar'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        auth.mensajeError.value = '';
                        setState(() => _registro = !_registro);
                      },
                      child: Text(
                        _registro
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
