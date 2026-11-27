import 'package:flutter/material.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';

/// Lo que se mueve detrás del tablero de un mapa con temática.
enum ParticulasMapa {
  ninguna,

  /// Copitos de nieve que caen.
  nieve,

  /// Brasitas de fuego que suben.
  brasas,
}

/// Dónde se ve cuántos de los 6 números iniciales van colocados.
enum IndicadorIniciales {
  /// La rueda de 6 sectores de siempre.
  rueda,

  /// Un copo de nieve de 6 brazos.
  copo,

  /// Una llama de 6 lenguas de fuego.
  llama,
}

/// Cómo se ve cada mapa: su nombre y, si tiene, su temática (fondo, colores de
/// las tarjetas y de la barra, nieve o fuego...). Los colores del tablero no
/// cambian: eso es parte del juego.
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
    this.particulas = ParticulasMapa.ninguna,
    this.indicador = IndicadorIniciales.rueda,
    this.icono,
    this.colorIcono = Colors.black54,
    this.colorCielo = const Color(0xFFF7B98A),
  });

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

  final ParticulasMapa particulas;
  final IndicadorIniciales indicador;

  /// El dibujito junto a «Mapa N» en el menú (un copito, una llama...).
  final IconData? icono;
  final Color colorIcono;

  /// El color del cielo de su fondo: se ve mientras carga la imagen.
  final Color colorCielo;

  /// Si caen copitos de nieve detrás del tablero.
  bool get nieve => particulas == ParticulasMapa.nieve;

  /// Si suben brasitas de fuego detrás del tablero.
  bool get brasas => particulas == ParticulasMapa.brasas;

  /// Si los 6 números iniciales se llenan en un copo de nieve.
  bool get copoDeNieve => indicador == IndicadorIniciales.copo;

  /// Si los 6 números iniciales se encienden en una llama.
  bool get llama => indicador == IndicadorIniciales.llama;

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
    particulas: ParticulasMapa.nieve,
    indicador: IndicadorIniciales.copo,
    icono: Icons.ac_unit,
    colorIcono: ColoresHielo.azul,
    colorCielo: Color(0xFF5BB8F0),
  );

  /// El Mapa 2: el Reino del Fuego, en rojos, naranjas y amarillos.
  static const TemaMapa reinoDelFuego = TemaMapa(
    numero: 2,
    nombre: 'Reino del Fuego',
    imagenFondo: 'assets/imagenes/fondo_reino_fuego.jpg',
    // Un velo cálido y ligero: el dibujo ya es oscuro y se ve bien.
    veloFondo: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x1FFFB066), Color(0x14FF7A2E)],
    ),
    tarjeta: ColoresFuego.tarjeta,
    bordeTarjeta: ColoresFuego.borde,
    sombraTarjeta: ColoresFuego.sombra,
    barra: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xF2FFD9A8), Color(0xF2FFB38A)],
    ),
    lineaBarra: Color(0x99C8431E),
    tarjetaDestacada: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF5FFF6E5), Color(0xEBFFCFA3)],
    ),
    botonRedondo: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA23A), ColoresFuego.rojo],
    ),
    particulas: ParticulasMapa.brasas,
    indicador: IndicadorIniciales.llama,
    icono: Icons.local_fire_department,
    colorIcono: ColoresFuego.naranja,
    colorCielo: Color(0xFF8E1C12),
  );

  /// El tema del mapa con ese número.
  static TemaMapa de(int numero) => switch (numero) {
    1 => reinoHelado,
    2 => reinoDelFuego,
    _ => TemaMapa(numero: numero, nombre: 'Mapa $numero'),
  };

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

/// Los colores del Reino del Fuego.
abstract final class ColoresFuego {
  /// Tarjetas: crema de brasa, casi opacas, para leerse sobre el rojo.
  static const Color tarjeta = Color(0xF0FFF3E6);
  static const Color borde = Color(0xFFF2A469);
  static const Color sombra = Color(0x667A1408);

  /// Naranja de las llamas.
  static const Color naranja = Color(0xFFF2711C);

  /// Rojo fuego de los contornos y detalles.
  static const Color rojo = Color(0xFFC8341A);

  /// Lo que todavía no se enciende: durazno muy claro.
  static const Color apagado = Color(0xFFFFE3CC);
}

/// Pone el tema de un mapa a todo lo que va dentro (tarjetas, barra...).
class AlcanceTemaMapa extends InheritedWidget {
  const AlcanceTemaMapa({super.key, required this.tema, required super.child});

  final TemaMapa tema;

  @override
  bool updateShouldNotify(AlcanceTemaMapa anterior) => anterior.tema != tema;
}
