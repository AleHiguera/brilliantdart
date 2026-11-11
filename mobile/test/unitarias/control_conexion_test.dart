// Prueba unitaria: cuántos fallos de red seguidos hacen falta para dar la
// conexión por perdida.

import 'package:brilliant_mobile/control_conexion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ControlConexion', () {
    test('Empieza sin fallos', () {
      final conexion = ControlConexion();

      expect(conexion.fallosSeguidos, 0);
      expect(conexion.fallando, isFalse);
    });

    test('Por defecto se desconecta al tercer fallo seguido', () {
      final conexion = ControlConexion();

      expect(conexion.fallo(), isFalse);
      expect(conexion.fallo(), isFalse);
      expect(conexion.fallo(), isTrue);
    });

    test('La desconexión se anuncia una sola vez', () {
      final conexion = ControlConexion(fallosParaDesconectar: 2);

      conexion
        ..fallo()
        ..fallo();

      expect(conexion.fallo(), isFalse);
      expect(conexion.fallo(), isFalse);
    });

    test('Un fallo suelto deja la conexión fallando, pero no perdida', () {
      final conexion = ControlConexion();

      expect(conexion.fallo(), isFalse);
      expect(conexion.fallando, isTrue);
      expect(conexion.fallosSeguidos, 1);
    });

    test('Una respuesta del servidor borra los fallos anteriores', () {
      final conexion = ControlConexion();

      conexion
        ..fallo()
        ..fallo()
        ..exito();

      expect(conexion.fallando, isFalse);
      expect(conexion.fallo(), isFalse);
      expect(conexion.fallo(), isFalse);
      expect(conexion.fallo(), isTrue);
    });

    test('Reiniciar vuelve a empezar la cuenta', () {
      final conexion = ControlConexion(fallosParaDesconectar: 2)..fallo();

      conexion.reiniciar();

      expect(conexion.fallosSeguidos, 0);
      expect(conexion.fallo(), isFalse);
    });

    test('Con un límite de 1 basta un fallo', () {
      expect(ControlConexion(fallosParaDesconectar: 1).fallo(), isTrue);
    });
  });
}
