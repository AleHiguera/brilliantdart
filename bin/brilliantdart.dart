import '../lib/bloc_valores_iniciales.dart';
import '../lib/tablero.dart';

void main() {
  final tablero = Tablero();
  final bloc = BlocValoresIniciales(tablero);

  print('Estado inicial del juego: ${bloc.puedeIniciar ? 'habilitado' : 'bloqueado'}');

  final valoresIniciales = [1, 2, 3, 4, 5, 6];

  for (var i = 0; i < BlocValoresIniciales.celdasIniciales.length; i++) {
    final (fila, columna) = BlocValoresIniciales.celdasIniciales[i];
    tablero.colocarDato(fila - 1, columna - 1, valoresIniciales[i]);
  }

  print('Celdas iniciales: ${BlocValoresIniciales.celdasIniciales}');
  print('Estado después de completar las celdas iniciales: ${bloc.puedeIniciar ? 'habilitado' : 'bloqueado'}');
  print('Valores en las celdas iniciales: ${bloc.obtenerValoresIniciales()}');
}