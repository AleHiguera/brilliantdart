import 'package:crypto/crypto.dart';

/// Huella SHA-256 del certificado del servidor de cuentas (`servidor.p12`),
/// la misma que imprime el servidor al arrancar. Si se genera otro
/// certificado, se compila con `--dart-define=HUELLA=0B:29:...`.
const String huellaServidor = String.fromEnvironment(
  'HUELLA',
  defaultValue:
      '0B:29:3D:DB:CE:41:BD:EC:BC:5B:BF:35:F1:73:26:D5:'
      '37:52:7D:9A:0F:20:1C:E6:C9:60:C0:7C:F6:80:58:9F',
);

/// El certificado del servidor es casero (no lo firmó ninguna autoridad), así
/// que el teléfono no lo reconoce. En vez de aceptar cualquiera, se acepta
/// solo aquel cuya huella coincide con la conocida.
class ConfianzaCertificado {
  ConfianzaCertificado([String huella = huellaServidor])
    : _huella = _normalizar(huella);

  final String _huella;

  /// Si el certificado, en bytes DER, es el del servidor.
  bool acepta(List<int> der) => _huella.isNotEmpty && huellaDe(der) == _huella;

  /// La huella SHA-256 en el formato del servidor: `0B:29:3D:...`.
  static String huellaDe(List<int> der) => sha256
      .convert(der)
      .bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');

  /// Acepta la huella con o sin dos puntos, con espacios y en minúsculas.
  static String _normalizar(String huella) {
    final hex = huella.replaceAll(RegExp('[^0-9a-fA-F]'), '').toUpperCase();
    return [
      for (var i = 0; i + 1 < hex.length; i += 2) hex.substring(i, i + 2),
    ].join(':');
  }
}
