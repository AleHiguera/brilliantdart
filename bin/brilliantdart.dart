import '../lib/tipoo.dart';
import '../lib/zona.dart';

void main() {
  final tipoAzul = Tipo(
    tipo: TipoZona.azul,
    color: 'Azul',
    regla: 'Todos los números deben ser iguales',
    puntuacion: 10,
  );

  final zonaAzul = Zona(
    id: 1,
    tipo: tipoAzul,
    coordenadas: [
      Coordenada(fila: 0, columna: 0, valor: 3),
      Coordenada(fila: 0, columna: 1, valor: 3),
      Coordenada(fila: 1, columna: 0, valor: 3),
    ],
  );

  print('===== TIPO =====');
  print(tipoAzul.obtenerInformacion());

  print('===== ZONA =====');
  print('ID: ${zonaAzul.id}');
  print('Tipo: ${zonaAzul.tipo.color}');
  print('Tamaño: ${zonaAzul.tamanoZona}');
  print('Valores: ${zonaAzul.obtenerValores()}');

  print('===== VALIDACIÓN =====');
  print('Movimiento válido: ${zonaAzul.validarMovimiento()}');
  print('Zona completada: ${zonaAzul.verificarCompletado()}');
}