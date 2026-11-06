import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

// Mismas reglas que comun/Validador.java del servidor. El servidor las vuelve
// a comprobar; aquí solo sirven para avisar antes de enviar.
final _usuarioValido = RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{2,29}$');
final _correoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _letra = RegExp(r'\p{L}', unicode: true);

String? validarUsuario(String? valor) =>
    _usuarioValido.hasMatch((valor ?? '').trim())
    ? null
    : 'Debe empezar por una letra y tener de 3 a 30 caracteres '
          '(letras, números, punto, guion o guion bajo).';

String? validarNombre(String? valor) {
  final nombre = (valor ?? '').trim();
  if (nombre.isEmpty || nombre.length > 80) {
    return 'El nombre es obligatorio (máximo 80 caracteres).';
  }
  if (nombre.contains('  ') || nombre.contains(RegExp(r'[^\S ]'))) {
    return 'Solo puede llevar un espacio entre palabras.';
  }
  if (!_letra.hasMatch(nombre)) return 'El nombre debe contener letras.';
  return null;
}

String? validarCorreo(String? valor) {
  final correo = (valor ?? '').trim();
  return correo.length <= 120 && _correoValido.hasMatch(correo)
      ? null
      : 'El correo electrónico no es válido.';
}

String? validarPin(String? valor) => RegExp(r'^[0-9]{4}$').hasMatch(valor ?? '')
    ? null
    : 'El PIN tiene exactamente 4 números.';

/// Crea una cuenta nueva en el servidor y entra directamente al juego.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.auth, required this.siguiente});

  final ServicioAuth auth;
  final WidgetBuilder siguiente;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pin = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _nombre.dispose();
    _correo.dispose();
    _pin.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (_enviando || !_formulario.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await widget.auth.registrar(
        usuario: _usuario.text,
        nombre: _nombre.text,
        correo: _correo.text,
        pin: _pin.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: widget.siguiente),
        (_) => false,
      );
    } on ErrorAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  Widget _campo({
    required String clave,
    required TextEditingController controlador,
    required String etiqueta,
    required FormFieldValidator<String> validador,
    bool pin = false,
    TextInputType? teclado,
    Iterable<String>? autocompletar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: Key(clave),
        controller: controlador,
        enabled: !_enviando,
        obscureText: pin,
        maxLength: pin ? 4 : null,
        keyboardType: pin ? TextInputType.number : teclado,
        inputFormatters: pin ? [FilteringTextInputFormatter.digitsOnly] : null,
        autofillHints: autocompletar,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: validador,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formulario,
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Text(
                      'Crea tu cuenta para guardar tu acceso al juego.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    _campo(
                      clave: 'registro-usuario',
                      controlador: _usuario,
                      etiqueta: 'Usuario',
                      validador: validarUsuario,
                      autocompletar: const [AutofillHints.newUsername],
                    ),
                    _campo(
                      clave: 'registro-nombre',
                      controlador: _nombre,
                      etiqueta: 'Nombre',
                      validador: validarNombre,
                      teclado: TextInputType.name,
                      autocompletar: const [AutofillHints.name],
                    ),
                    _campo(
                      clave: 'registro-correo',
                      controlador: _correo,
                      etiqueta: 'Correo electrónico',
                      validador: validarCorreo,
                      teclado: TextInputType.emailAddress,
                      autocompletar: const [AutofillHints.email],
                    ),
                    _campo(
                      clave: 'registro-pin',
                      controlador: _pin,
                      etiqueta: 'PIN (4 números)',
                      validador: validarPin,
                      pin: true,
                      autocompletar: const [AutofillHints.newPassword],
                    ),
                    _campo(
                      clave: 'registro-confirmacion',
                      controlador: _confirmacion,
                      etiqueta: 'Repite el PIN',
                      validador: (valor) =>
                          valor == _pin.text ? null : 'Los PIN no coinciden.',
                      pin: true,
                    ),
                    if (_error != null) ...[
                      SelectableText(
                        _error!,
                        key: const Key('registro-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      key: const Key('registro-crear'),
                      onPressed: _enviando ? null : _crearCuenta,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear cuenta'),
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
