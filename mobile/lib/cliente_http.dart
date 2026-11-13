import 'package:http/http.dart' as http;
import 'package:brilliant_mobile/cliente_http_nativo.dart'
    if (dart.library.js_interop) 'package:brilliant_mobile/cliente_http_web.dart'
    as plataforma;

/// El cliente con el que la app habla con el servidor. En el navegador es el
/// normal (el certificado lo acepta la persona); en el teléfono solo confía
/// en el certificado del servidor.
http.Client crearClienteHttp() => plataforma.crearCliente();
