import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:brilliant_mobile/paseo_npc.dart';
import 'package:brilliant_mobile/pintores_npc.dart';

/// Los personajitos que pasean por la parte de abajo del menú y de vez en
/// cuando se detienen a decir «¡Hola!». Son de adorno: los toques pasan a
/// través de ellos.
class NpcsMenu extends StatefulWidget {
  const NpcsMenu({super.key});

  /// Alto de la franja donde caminan (con espacio para el globo del saludo).
  static const double alto = 66;

  /// Cuánto se agrandan los dibujos respecto a sus medidas base.
  static const double escala = 0.85;

  /// Las pruebas de otras pantallas los apagan: al moverse sin parar no
  /// dejarían que la pantalla «termine» de animarse.
  static bool habilitados = true;

  @override
  State<NpcsMenu> createState() => _NpcsMenuState();
}

class _NpcsMenuState extends State<NpcsMenu>
    with SingleTickerProviderStateMixin {
  // El niño va por delante y el perrito un poco más rápido detrás; cada uno
  // saluda a su ritmo, así a veces se cruzan.
  final PaseoNpc _nino = PaseoNpc(x: 24, velocidad: 22, duracionCaminata: 5);
  final PaseoNpc _perro = PaseoNpc(
    x: 70,
    direccion: -1,
    velocidad: 27,
    duracionCaminata: 6.5,
  );

  late final Ticker _reloj = createTicker(_avanzar);
  Duration _anterior = Duration.zero;
  double _ancho = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con «reducir movimiento» se quedan quietos.
    final quietos =
        !NpcsMenu.habilitados ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (quietos && _reloj.isActive) {
      _reloj.stop();
    } else if (!quietos && !_reloj.isActive) {
      _anterior = Duration.zero;
      _reloj.start();
    }
  }

  void _avanzar(Duration transcurrido) {
    final segundos =
        (transcurrido - _anterior).inMicroseconds /
        Duration.microsecondsPerSecond;
    _anterior = transcurrido;
    if (_ancho <= 0) return;
    setState(() {
      _nino.avanzar(
        segundos,
        ancho: _ancho,
        tamano: tamanoNino.width * NpcsMenu.escala,
      );
      _perro.avanzar(
        segundos,
        ancho: _ancho,
        tamano: tamanoPerro.width * NpcsMenu.escala,
      );
    });
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!NpcsMenu.habilitados) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        key: const Key('npcs-menu'),
        height: NpcsMenu.alto,
        child: LayoutBuilder(
          builder: (context, limites) {
            _ancho = limites.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _Personaje(
                  clave: 'nino',
                  paseo: _nino,
                  tamano: tamanoNino * NpcsMenu.escala,
                  pintor: PintorNino(
                    paso: _nino.paso,
                    saludando: _nino.saludando,
                  ),
                ),
                _Personaje(
                  clave: 'perro',
                  paseo: _perro,
                  tamano: tamanoPerro * NpcsMenu.escala,
                  pintor: PintorPerro(
                    paso: _perro.paso,
                    saludando: _perro.saludando,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Personaje extends StatelessWidget {
  const _Personaje({
    required this.clave,
    required this.paseo,
    required this.tamano,
    required this.pintor,
  });

  final String clave;
  final PaseoNpc paseo;
  final Size tamano;
  final CustomPainter pintor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: Key('npc-$clave'),
      left: paseo.x,
      bottom: 4 + paseo.rebote * 1.2,
      // Del ancho del dibujo: el globo flota encima sin empujarlo, así el
      // personaje nunca se sale por la orilla al saludar.
      width: tamano.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 17,
            child: paseo.saludando
                ? OverflowBox(
                    maxWidth: 80,
                    child: Center(child: _Globo(key: Key('npc-saludo-$clave'))),
                  )
                : null,
          ),
          const SizedBox(height: 2),
          // Mira hacia donde camina.
          Transform.flip(
            flipX: paseo.direccion < 0,
            child: CustomPaint(size: tamano, painter: pintor),
          ),
        ],
      ),
    );
  }
}

/// El globito con «¡Hola!».
class _Globo extends StatelessWidget {
  const _Globo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: ColoresNpc.contorno, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        PaseoNpc.saludo,
        style: TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
          color: ColoresNpc.contorno,
        ),
      ),
    );
  }
}
