import 'package:flutter/material.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';

/// Cómo se ve cada mapa: su nombre y, si tiene, su temática (fondo, colores de
/// las tarjetas y de la barra, nieve...). Los colores del tablero no cambian:
/// eso es parte del juego.
class TemaMapa {
  const TemaMapa({
    required this.numero,
    required this.nombre,
    this.imagenFondo,
    this.veloFondo,
    this.tarjeta = PaletaAtardecer.tarjeta,
    this.bordeTarjeta = PaletaAtardecer.borde,
    this.sombraTarjeta = PaletaAtardecer.sombra,
    this.barra = PaletaAtardecer.barra,
    this.lineaBarra = PaletaAtardecer.lineaBarra,
    this.tarjetaDestacada = PaletaAtardecer.tarjetaDestacada,
    this.botonRedondo = PaletaAtardecer.botonRedondo,
    this.nieve = false,
    this.copoDeNieve = false,
    this.colorCielo = const Color(0xFFF7B98A),
  });

  /// El color del cielo de su fondo: se ve mientras carga la imagen.
  final Color colorCielo;

  final int numero;

  /// Cómo se llama el mapa en toda la app.
  final String nombre;

  /// Fondo propio del tablero; null usa el de la app.
  final String? imagenFondo;
  final LinearGradient? veloFondo;

  final Color tarjeta;
  final Color bordeTarjeta;
  final Color sombraTarjeta;
  final LinearGradient barra;
  final Color lineaBarra;

  /// La tarjeta del mapa en el menú y su flecha.
  final LinearGradient tarjetaDestacada;
  final LinearGradient botonRedondo;

  /// Si caen copitos de nieve detrás del tablero.
  final bool nieve;

  /// Si los 6 números iniciales se llenan en un copo de nieve en vez de en
  /// una rueda.
  final bool copoDeNieve;

  /// Si el mapa tiene un nombre propio (no solo «Mapa N»).
  bool get tieneNombrePropio => nombre != 'Mapa $numero';

  /// El Mapa 1: el Reino Helado, en azules y blancos.
  static const TemaMapa reinoHelado = TemaMapa(
    numero: 1,
    nombre: 'Reino Helado',
    imagenFondo: 'assets/imagenes/fondo_reino_helado.jpg',
    veloFondo: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x40FFFFFF), Color(0x26E6F4FF)],
    ),
    tarjeta: ColoresHielo.tarjeta,
    bordeTarjeta: ColoresHielo.borde,
    sombraTarjeta: ColoresHielo.sombra,
    barra: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xF2EAF7FF), Color(0xF2C6E7FB)],
    ),
    lineaBarra: Color(0x8064A8D8),
    tarjetaDestacada: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF5FFFFFF), Color(0xEBD4ECFB)],
    ),
    botonRedondo: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6CC4F0), ColoresHielo.azul],
    ),
    nieve: true,
    copoDeNieve: true,
    colorCielo: Color(0xFF5BB8F0),
  );

  /// El tema del mapa con ese número.
  static TemaMapa de(int numero) => numero == 1
      ? reinoHelado
      : TemaMapa(numero: numero, nombre: 'Mapa $numero');

  /// El tema de la pantalla en que se está; null fuera de un mapa.
  static TemaMapa? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlcanceTemaMapa>()?.tema;
}

/// Los colores del Reino Helado.
abstract final class ColoresHielo {
  /// Tarjetas: blanco hielo, casi opacas.
  static const Color tarjeta = Color(0xEBF4FAFF);
  static const Color borde = Color(0xFFB9DDF5);
  static const Color sombra = Color(0x332A7AB8);

  /// Azul hielo de los detalles.
  static const Color azul = Color(0xFF2A8BD0);

  /// Azul muy claro de lo que falta por llenar.
  static const Color vacio = Color(0xFFD9ECF8);
}

/// Pone el tema de un mapa a todo lo que va dentro (tarjetas, barra...).
class AlcanceTemaMapa extends InheritedWidget {
  const AlcanceTemaMapa({super.key, required this.tema, required super.child});

  final TemaMapa tema;

  @override
  bool updateShouldNotify(AlcanceTemaMapa anterior) => anterior.tema != tema;
}
