import 'dart:js_interop';

import 'package:brilliant_mobile/almacen_pestana.dart';

@JS('sessionStorage')
external _Almacen get _sessionStorage;

@JS('localStorage')
external _Almacen get _localStorage;

extension type _Almacen(JSObject _) implements JSObject {
  external String? getItem(String clave);
  external void setItem(String clave, String valor);
  external void removeItem(String clave);
}

/// En el navegador los almacenes ya están listos.
Future<void> prepararAlmacen(String? carpeta) async {}

AlmacenPestana crearAlmacen() => _AlmacenWeb(() => _sessionStorage);

AlmacenPestana crearAlmacenDuradero() => _AlmacenWeb(() => _localStorage);

/// Un almacén del navegador. Si está bloqueado (por ejemplo, en una ventana
/// privada muy restringida) se comporta como si estuviera vacío.
class _AlmacenWeb implements AlmacenPestana {
  _AlmacenWeb(this._almacen);

  final _Almacen Function() _almacen;

  @override
  String? leer(String clave) {
    try {
      return _almacen().getItem(clave);
    } catch (_) {
      return null;
    }
  }

  @override
  void guardar(String clave, String valor) {
    try {
      _almacen().setItem(clave, valor);
    } catch (_) {
      // Sin almacén, simplemente no se recuerda.
    }
  }

  @override
  void borrar(String clave) {
    try {
      _almacen().removeItem(clave);
    } catch (_) {
      // Nada que borrar.
    }
  }
}
