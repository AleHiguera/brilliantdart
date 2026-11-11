import 'dart:js_interop';

import 'package:brilliant_mobile/almacen_pestana.dart';

@JS('sessionStorage')
external _Almacen get _sessionStorage;

extension type _Almacen(JSObject _) implements JSObject {
  external String? getItem(String clave);
  external void setItem(String clave, String valor);
  external void removeItem(String clave);
}

AlmacenPestana crearAlmacen() => _AlmacenWeb();

/// El sessionStorage del navegador. Si está bloqueado (por ejemplo, en una
/// ventana privada muy restringida) se comporta como si estuviera vacío.
class _AlmacenWeb implements AlmacenPestana {
  @override
  String? leer(String clave) {
    try {
      return _sessionStorage.getItem(clave);
    } catch (_) {
      return null;
    }
  }

  @override
  void guardar(String clave, String valor) {
    try {
      _sessionStorage.setItem(clave, valor);
    } catch (_) {
      // Sin almacén, recargar pierde la sesión, como antes.
    }
  }

  @override
  void borrar(String clave) {
    try {
      _sessionStorage.removeItem(clave);
    } catch (_) {
      // Nada que borrar.
    }
  }
}
