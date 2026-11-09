import 'package:brilliantdart/dados.dart';

/// Dados de una partida multijugador: no se generan aquí, sino que muestran el
/// resultado que el servidor lanzó para toda la partida.
class DadosCompartidos extends Dados {
  DadosCompartidos(this._resultado);

  final (int, int) Function() _resultado;

  @override
  (int, int) lanzar() {
    final (valorDado1, valorDado2) = _resultado();
    dado1.valor = valorDado1;
    dado2.valor = valorDado2;
    historial.registrarLanzamiento(valorDado1, valorDado2);
    return (valorDado1, valorDado2);
  }
}
