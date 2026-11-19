import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brilliant_mobile/cuadro_error.dart';
import 'package:brilliant_mobile/errores_formulario.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

// Mismas reglas que comun/Validador.java del servidor. El servidor las vuelve
// a comprobar; aquí solo sirven para avisar antes de enviar.
final _usuarioValido = RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{2,29}$');
final _correoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _letra = RegExp(r'\p{L}', unicode: true);

String? validarUsuario(String? valor) =>
    _usuarioValido.hasMatch((valor ?? '').trim())
    ? null
    : 'El usuario debe empezar con una letra y tener de 3 a 30 caracteres '
          '(letras, números, punto, guion o guion bajo).';

String? validarNombre(String? valor) {
  final nombre = (valor ?? '').trim();
  if (nombre.isEmpty || nombre.length > 80) {
    return 'El nombre es obligatorio (máximo 80 caracteres).';
  }
  if (nombre.contains('  ') || nombre.contains(RegExp(r'[^\S ]'))) {
    return 'El nombre solo puede llevar un espacio entre palabras.';
  }
  if (!_letra.hasMatch(nombre)) {
    return 'El nombre debe tener letras, no solo números o signos.';
  }
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
    : 'El PIN debe tener exactamente 4 números.';

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

  /// Por qué no se pudo crear la cuenta; se ve en el cuadro de error.
  List<String> _errores = const [];

  /// Los campos que hay que corregir: se marcan en rojo.
  Set<String> _camposConError = const {};

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
    if (_enviando) return;
    final errores = erroresRegistro(
      usuario: _usuario.text,
      nombre: _nombre.text,
      correo: _correo.text,
      pin: _pin.text,
      confirmacion: _confirmacion.text,
    );
    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores.values.toList();
        _camposConError = errores.keys.toSet();
      });
      return;
    }
    setState(() {
      _enviando = true;
      _errores = const [];
      _camposConError = const {};
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
        _errores = [e.mensaje];
        _enviando = false;
      });
    }
  }

  Widget _campo({
    required String clave,
    required String campo,
    required TextEditingController controlador,
    required String etiqueta,
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
        decoration: decoracionCampo(
          etiqueta,
          conError: _camposConError.contains(campo),
        ),
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
                      campo: 'usuario',
                      controlador: _usuario,
                      etiqueta: 'Usuario',
                      autocompletar: const [AutofillHints.newUsername],
                    ),
                    _campo(
                      clave: 'registro-nombre',
                      campo: 'nombre',
                      controlador: _nombre,
                      etiqueta: 'Nombre',
                      teclado: TextInputType.name,
                      autocompletar: const [AutofillHints.name],
                    ),
                    _campo(
                      clave: 'registro-correo',
                      campo: 'correo',
                      controlador: _correo,
                      etiqueta: 'Correo electrónico',
                      teclado: TextInputType.emailAddress,
                      autocompletar: const [AutofillHints.email],
                    ),
                    _campo(
                      clave: 'registro-pin',
                      campo: 'pin',
                      controlador: _pin,
                      etiqueta: 'PIN (4 números)',
                      pin: true,
                      autocompletar: const [AutofillHints.newPassword],
                    ),
                    _campo(
                      clave: 'registro-confirmacion',
                      campo: 'confirmacion',
                      controlador: _confirmacion,
                      etiqueta: 'Repite el PIN',
                      pin: true,
                    ),
                    if (_errores.isNotEmpty) ...[
                      CuadroError(
                        key: const Key('registro-error'),
                        mensajes: _errores,
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
