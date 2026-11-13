import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:brilliant_mobile/huella_certificado.dart';

http.Client crearCliente() =>
    ClienteSeguro(IOClient(clienteQueConfiaEn(ConfianzaCertificado())));

/// Un certificado que el teléfono no reconoce solo se acepta si es el del
/// servidor; los firmados por una autoridad se siguen aceptando como siempre.
HttpClient clienteQueConfiaEn(ConfianzaCertificado confianza) =>
    HttpClient()
      ..badCertificateCallback = (certificado, _, _) =>
          confianza.acepta(certificado.der);

/// Si el certificado no es el del servidor, la conexión segura falla con un
/// error que `http` no traduce. Aquí se vuelve un [http.ClientException], el
/// mismo error que cuando no hay conexión, para que la app lo muestre bien.
class ClienteSeguro extends http.BaseClient {
  ClienteSeguro(this._interno);

  final http.Client _interno;

  static const String certificadoAjeno =
      'El certificado del servidor no es el esperado.';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest peticion) async {
    try {
      return await _interno.send(peticion);
    } on TlsException {
      throw http.ClientException(certificadoAjeno, peticion.url);
    }
  }

  @override
  void close() => _interno.close();
}
