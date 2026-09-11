import 'package:test/test.dart';
import '../lib/tipoo.dart';
import '../lib/zona.dart';

void main() {
  group('Pruebas de Zona', () {
    test('Una zona azul puede completarse con numeros iguales', () {
      final tipoAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos los numeros deben ser iguales',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 1,
        tipo: tipoAzul,
        coordenadas: [
          Coordenada(fila: 0, columna: 0, valor: 3),
          Coordenada(fila: 0, columna: 1, valor: 3),
          Coordenada(fila: 1, columna: 0, valor: 3),
        ],
      );

      expect(zona.verificarCompletado(), isTrue);
      expect(zona.completado, isTrue);
    });

    test('Una zona azul no puede tener numeros diferentes', () {
      final tipoAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos los numeros deben ser iguales',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 2,
        tipo: tipoAzul,
        coordenadas: [
          Coordenada(fila: 0, columna: 0, valor: 3),
          Coordenada(fila: 0, columna: 1, valor: 3),
          Coordenada(fila: 1, columna: 0, valor: 4),
        ],
      );

      expect(zona.verificarCompletado(), isFalse);
    });

    test('Una zona roja acepta numeros diferentes', () {
      final tipoRojo = Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos los numeros deben ser diferentes',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 3,
        tipo: tipoRojo,
        coordenadas: [
          Coordenada(fila: 0, columna: 0, valor: 1),
          Coordenada(fila: 0, columna: 1, valor: 2),
          Coordenada(fila: 1, columna: 0, valor: 3),
        ],
      );

      expect(zona.verificarCompletado(), isTrue);
    });

    test('Una zona roja no acepta numeros repetidos', () {
      final tipoRojo = Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos los numeros deben ser diferentes',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 4,
        tipo: tipoRojo,
        coordenadas: [
          Coordenada(fila: 0, columna: 0, valor: 1),
          Coordenada(fila: 0, columna: 1, valor: 2),
          Coordenada(fila: 1, columna: 0, valor: 2),
        ],
      );

      expect(zona.verificarCompletado(), isFalse);
    });

    test('Una zona verde permite numeros repetidos', () {
      final tipoVerde = Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: 'Los numeros pueden repetirse',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 5,
        tipo: tipoVerde,
        coordenadas: [
          Coordenada(fila: 2, columna: 0, valor: 4),
          Coordenada(fila: 2, columna: 1, valor: 4),
          Coordenada(fila: 3, columna: 0, valor: 2),
        ],
      );

      expect(zona.verificarCompletado(), isTrue);
    });

    test('Una zona morada debe tener exactamente dos numeros', () {
      final tipoMorado = Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 6,
        tipo: tipoMorado,
        coordenadas: [
          Coordenada(fila: 3, columna: 3, valor: 2),
          Coordenada(fila: 3, columna: 4, valor: 7),
        ],
      );

      expect(zona.verificarCompletado(), isTrue);
    });

    test('Una zona morada con tres numeros no es valida', () {
      final tipoMorado = Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 7,
        tipo: tipoMorado,
        coordenadas: [
          Coordenada(fila: 3, columna: 3, valor: 2),
          Coordenada(fila: 3, columna: 4, valor: 7),
          Coordenada(fila: 4, columna: 3, valor: 5),
        ],
      );

      expect(zona.verificarCompletado(), isFalse);
    });

    test('El tamaño de la zona corresponde a sus coordenadas', () {
      final tipoAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 8,
        tipo: tipoAzul,
        coordenadas: [
          Coordenada(fila: 0, columna: 0),
          Coordenada(fila: 0, columna: 1),
          Coordenada(fila: 1, columna: 0),
          Coordenada(fila: 1, columna: 1),
        ],
      );

      expect(zona.tamanoZona, equals(4));
    });

    test('La zona reconoce una coordenada', () {
      final tipoAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 9,
        tipo: tipoAzul,
        coordenadas: [
          Coordenada(fila: 2, columna: 3),
          Coordenada(fila: 2, columna: 4),
        ],
      );

      expect(zona.contieneCoordenada(2, 3), isTrue);
      expect(zona.contieneCoordenada(5, 5), isFalse);
    });

    test('Se puede colocar un numero en una coordenada', () {
      final tipoAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 10,
      );

      final zona = Zona(
        id: 10,
        tipo: tipoAzul,
        coordenadas: [
          Coordenada(fila: 0, columna: 0),
          Coordenada(fila: 0, columna: 1),
        ],
      );

      zona.colocarNumero(0, 0, 5);

      expect(
        zona.obtenerValores(),
        equals([5]),
      );
    });
  });
}