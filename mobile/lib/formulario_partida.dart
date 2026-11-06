import 'package:flutter/material.dart';

AppBar barraPartida(String titulo) => AppBar(
  title: Text(titulo),
  centerTitle: true,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  elevation: 0,
);

/// Botón principal de un formulario: muestra que se espera al servidor.
class BotonEnviarPartida extends StatelessWidget {
  const BotonEnviarPartida({
    super.key,
    required this.texto,
    required this.enviando,
    required this.onPressed,
  });

  final String texto;
  final bool enviando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enviando ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: enviando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(texto),
      ),
    );
  }
}

class ErrorPartida extends StatelessWidget {
  const ErrorPartida(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SelectableText(
        mensaje,
        key: const Key('multijugador-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
