import 'package:flutter/material.dart';

/// El cuadro de abajo, junto al botón, que dice por qué no se pudo entrar o
/// crear la cuenta: el título «Error» y cada motivo en su línea.
class CuadroError extends StatelessWidget {
  const CuadroError({super.key, required this.mensajes});

  final List<String> mensajes;

  static const Color fondo = Color(0xFFFDECEC);
  static const Color borde = Color(0xFFE5A3A3);
  static const Color texto = Color(0xFF8A1C1C);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: texto),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error',
                  key: Key('error-titulo'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: texto,
                  ),
                ),
                const SizedBox(height: 2),
                for (final mensaje in mensajes)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      mensajes.length > 1 ? '• $mensaje' : mensaje,
                      style: const TextStyle(color: texto, height: 1.3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La decoración de un campo: con [conError] el borde se pone rojo, sin texto
/// debajo, porque el motivo ya se lee en el [CuadroError].
InputDecoration decoracionCampo(
  String etiqueta, {
  bool conError = false,
  String? pista,
}) => InputDecoration(
  labelText: etiqueta,
  hintText: pista,
  border: const OutlineInputBorder(),
  errorText: conError ? '' : null,
  errorStyle: const TextStyle(height: 0, fontSize: 0),
);
