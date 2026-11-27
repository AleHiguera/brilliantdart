/// Las animaciones de puro adorno (personajitos del menú, nieve...).
abstract final class Decoraciones {
  /// Las pruebas de las demás pantallas las apagan: al moverse sin parar no
  /// dejarían que la pantalla «termine» de animarse. Sus propias pruebas las
  /// vuelven a encender.
  static bool animadas = true;
}
