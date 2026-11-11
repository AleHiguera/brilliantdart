import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';

/// La sesión abierta tal como se guarda en la pestaña, para que recargar la
/// página no obligue a entrar de nuevo. Solo guarda y lee: no habla con el
/// servidor.
class SesionGuardada {
  SesionGuardada(this.almacen);

  static const String claveSesion = 'brilliant.sesion';
  static const String clavePartida = 'brilliant.partida';
  static const String claveAbandonada = 'brilliant.sesionAbandonada';

  final AlmacenPestana almacen;

  /// Usuario, nombre y token, o null si no hay nada guardado o está dañado.
  ({String usuario, String nombre, String token})? leerSesion() {
    final texto = almacen.leer(claveSesion);
    if (texto == null) return null;
    try {
      if (jsonDecode(texto) case {
        'usuario': final String usuario,
        'nombre': final String nombre,
        'token': final String token,
      }) {
        return (usuario: usuario, nombre: nombre, token: token);
      }
    } on FormatException {
      // Se trata como si no hubiera nada.
    }
    return null;
  }

  void guardarSesion(({String usuario, String nombre, String token})? sesion) {
    if (sesion == null) {
      almacen.borrar(claveSesion);
    } else {
      almacen.guardar(
        claveSesion,
        jsonEncode({
          'usuario': sesion.usuario,
          'nombre': sesion.nombre,
          'token': sesion.token,
        }),
      );
    }
  }

  String? leerPartida() => almacen.leer(clavePartida);

  void guardarPartida(String? codigo) => _guardarTexto(clavePartida, codigo);

  String? leerTokenAbandonado() => almacen.leer(claveAbandonada);

  void guardarTokenAbandonado(String? token) =>
      _guardarTexto(claveAbandonada, token);

  void _guardarTexto(String clave, String? valor) {
    if (valor == null) {
      almacen.borrar(clave);
    } else {
      almacen.guardar(clave, valor);
    }
  }
}
