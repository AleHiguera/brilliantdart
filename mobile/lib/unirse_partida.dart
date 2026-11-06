import 'package:flutter/material.dart';
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/sala_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Pide el código que compartió el anfitrión y entra a su sala.
class UnirsePartidaPage extends StatefulWidget {
  const UnirsePartidaPage({super.key, required this.partidas});

  final ServicioPartidas partidas;

  @override
  State<UnirsePartidaPage> createState() => _UnirsePartidaPageState();
}

class _UnirsePartidaPageState extends State<UnirsePartidaPage> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (_enviando || !_formulario.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final sala = await widget.partidas.unirse(_codigo.text);
      if (!mounted) return;
      SalaPartidaPage.abrir(context, widget.partidas, sala);
    } on ErrorAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraPartida('Unirse a una partida'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formulario,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const Text(
                    'Escribe el código que te compartió el anfitrión.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('unirse-codigo'),
                    controller: _codigo,
                    enabled: !_enviando,
                    autofocus: true,
                    maxLength: ServicioPartidas.largoCodigo,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de la partida',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        (valor ?? '').trim().length ==
                            ServicioPartidas.largoCodigo
                        ? null
                        : 'El código tiene '
                              '${ServicioPartidas.largoCodigo} caracteres.',
                    onFieldSubmitted: (_) => _unirse(),
                  ),
                  if (_error != null) ErrorPartida(_error!),
                  const SizedBox(height: 16),
                  BotonEnviarPartida(
                    key: const Key('unirse-enviar'),
                    texto: 'Unirse',
                    enviando: _enviando,
                    onPressed: _unirse,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
