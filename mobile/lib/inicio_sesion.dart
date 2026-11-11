import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/registro.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

/// Pide usuario y PIN y los comprueba contra el servidor de cuentas antes de
/// dejar jugar. Al entrar se abre [siguiente] en lugar de esta pantalla.
class InicioSesionPage extends StatefulWidget {
  const InicioSesionPage({
    super.key,
    required this.auth,
    required this.siguiente,
    this.aviso,
  });

  final ServicioAuth auth;
  final WidgetBuilder siguiente;

  /// Motivo por el que se volvió a esta pantalla, como una sesión perdida.
  final String? aviso;

  @override
  State<InicioSesionPage> createState() => _InicioSesionPageState();
}

class _InicioSesionPageState extends State<InicioSesionPage> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _pin = TextEditingController();
  late final _servidor = TextEditingController(text: widget.auth.servidor);
  bool _enviando = false;
  late String? _aviso = widget.aviso;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _pin.dispose();
    _servidor.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando || !_formulario.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
      _aviso = null;
    });

    widget.auth.servidor = _servidor.text.trim();
    try {
      await widget.auth.iniciarSesion(_usuario.text, _pin.text);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: widget.siguiente));
    } on ErrorAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
        _pin.clear();
      });
    }
  }

  void _abrirRegistro() {
    widget.auth.servidor = _servidor.text.trim();
    setState(() => _error = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RegistroPage(auth: widget.auth, siguiente: widget.siguiente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant'),
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
                    Row(
                      children: [
                        for (final color in estilo.coloresZonas.values)
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.black26,
                                width: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inicia sesión',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entra con tu cuenta del registro de clientes para jugar.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('login-usuario'),
                      controller: _usuario,
                      enabled: !_enviando,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) => (valor ?? '').trim().isEmpty
                          ? 'Escribe tu usuario.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('login-pin'),
                      controller: _pin,
                      enabled: !_enviando,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'PIN (4 números)',
                        border: OutlineInputBorder(),
                      ),
                      validator: validarPin,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Servidor'),
                      subtitle: Text(
                        _servidor.text,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      children: [
                        TextFormField(
                          key: const Key('login-servidor'),
                          controller: _servidor,
                          enabled: !_enviando,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Dirección del servidor',
                            hintText: 'https://192.168.1.5:$puertoServidorWeb',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (valor) =>
                              (valor ?? '').trim().startsWith('https://')
                              ? null
                              : 'Debe empezar por https://',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (_aviso case final aviso?) ...[
                      const SizedBox(height: 8),
                      AvisoSesion(aviso),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        _error!,
                        key: const Key('login-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('login-entrar'),
                      onPressed: _enviando ? null : _entrar,
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
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('login-crear-cuenta'),
                      onPressed: _enviando ? null : _abrirRegistro,
                      child: const Text('¿No tienes cuenta? Crear cuenta'),
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

/// Por qué se volvió a esta pantalla, como una conexión perdida. Es un aviso,
/// no un error: no se pinta de rojo.
class AvisoSesion extends StatelessWidget {
  const AvisoSesion(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('login-aviso'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
