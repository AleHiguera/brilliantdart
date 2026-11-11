/// Lleva la cuenta de las peticiones seguidas que no llegaron al servidor.
/// Un fallo suelto puede ser un tropiezo de la red; varios seguidos significan
/// que se perdió la conexión. No sabe nada de sesiones ni de pantallas.
class ControlConexion {
  ControlConexion({this.fallosParaDesconectar = 3})
    : assert(fallosParaDesconectar > 0);

  /// Con la partida en juego se consulta cada 2 s: tres fallos son unos
  /// segundos sin red, no un tropiezo.
  final int fallosParaDesconectar;

  int _fallosSeguidos = 0;

  int get fallosSeguidos => _fallosSeguidos;

  /// La última petición no llegó: conviene volver a intentarlo pronto.
  bool get fallando => _fallosSeguidos > 0;

  /// El servidor respondió, aunque fuera con un rechazo: hay conexión.
  void exito() => _fallosSeguidos = 0;

  /// Anota un fallo de red. Devuelve true solo en el fallo que agota la
  /// paciencia, para que la desconexión se anuncie una sola vez.
  bool fallo() => ++_fallosSeguidos == fallosParaDesconectar;

  void reiniciar() => _fallosSeguidos = 0;
}
