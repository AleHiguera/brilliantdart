import 'dart:convert';

import 'package:brilliantdart/tablero.dart';
import 'package:brilliant_mobile/almacen_pestana.dart';

/// El turno que el jugador ya jugó en una ronda, aunque el aviso no hubiera
/// llegado al servidor.
typedef TurnoGuardado = ({int ronda, bool tableroLleno, int? zona});

/// Lo que solo sabe la app de una partida en juego: los números que el jugador
/// fue poniendo y el último turno que jugó. Se guarda en la pestaña para que
/// recargar la página no lo borre. Una sola partida a la vez, la de [codigo].
class GuardadoPartida {
  GuardadoPartida(this.almacen, this.codigo);

  static const String claveTablero = 'brilliant.tablero';
  static const String claveTurno = 'brilliant.turno';

  final AlmacenPestana almacen;
  final String codigo;

  void guardarCeldas(Tablero tablero) => _guardar(claveTablero, [
    for (final celda in tablero.celdas)
      if (celda.valor case final valor?) [celda.fila, celda.columna, valor],
  ]);

  /// Pone en [tablero] los números guardados de esta partida. Devuelve false
  /// si no había nada de ella o lo guardado no cabe en el tablero.
  bool restaurarCeldas(Tablero tablero) {
    final celdas = _leer(claveTablero);
    if (celdas is! List) return false;
    final validas = [
      for (final celda in celdas)
        if (celda case [final int fila, final int columna, final int valor]
            when fila >= 0 &&
                fila < Tablero.filas &&
                columna >= 0 &&
                columna < Tablero.columnas &&
                valor >= 1 &&
                valor <= 6)
          (fila, columna, valor),
    ];
    if (validas.length != celdas.length) return false;
    for (final (fila, columna, valor) in validas) {
      tablero.colocarDato(fila, columna, valor);
    }
    return true;
  }

  void guardarTurno(TurnoGuardado turno) => _guardar(claveTurno, {
    'ronda': turno.ronda,
    'lleno': turno.tableroLleno,
    'zona': turno.zona,
  });

  TurnoGuardado? leerTurno() {
    if (_leer(claveTurno) case {
      'ronda': final int ronda,
      'lleno': final bool lleno,
      'zona': final int? zona,
    }) {
      return (ronda: ronda, tableroLleno: lleno, zona: zona);
    }
    return null;
  }

  /// La partida terminó o el jugador ya no está en ella: nada que recuperar.
  /// Lo de otra partida no se toca.
  void borrar() {
    for (final clave in [claveTablero, claveTurno]) {
      if (_leer(clave) != null) almacen.borrar(clave);
    }
  }

  void _guardar(String clave, Object datos) =>
      almacen.guardar(clave, jsonEncode({'codigo': codigo, 'datos': datos}));

  /// Los datos guardados en [clave] si son de esta partida.
  Object? _leer(String clave) {
    final texto = almacen.leer(clave);
    if (texto == null) return null;
    try {
      if (jsonDecode(texto) case {
        'codigo': final String de,
        'datos': final datos,
      } when de == codigo) {
        return datos;
      }
    } on FormatException {
      // Dañado: como si no hubiera nada.
    }
    return null;
  }
}
