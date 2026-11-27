import 'package:flutter/material.dart';
import 'package:brilliant_mobile/avatar_jugador.dart';
import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/texto_elo_salon.dart';

/// Los colores de cada medalla: oro, plata y bronce.
class Medalla {
  const Medalla._(this.nombre, this.fuerte, this.claro, this.texto);

  final String nombre;
  final Color fuerte;
  final Color claro;
  final Color texto;

  static const oro = Medalla._(
    'oro',
    Color(0xFFD4A017),
    Color(0xFFFFEFA8),
    Color(0xFF6B4E00),
  );
  static const plata = Medalla._(
    'plata',
    Color(0xFF9EA3A8),
    Color(0xFFEDEFF1),
    Color(0xFF41464B),
  );
  static const bronce = Medalla._(
    'bronce',
    Color(0xFFB5703A),
    Color(0xFFF6D6BB),
    Color(0xFF5E3313),
  );

  /// La medalla de un lugar del 1 al 3; null para los demás.
  static Medalla? deLugar(int lugar) => switch (lugar) {
    1 => oro,
    2 => plata,
    3 => bronce,
    _ => null,
  };

  /// El brillo metálico: del tono claro al fuerte, en diagonal.
  LinearGradient get brillo => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [claro, fuerte, Color.lerp(fuerte, Colors.black, 0.15)!],
    stops: const [0, 0.55, 1],
  );
}

/// El podio con los tres primeros puestos: el 1.º al centro y más alto, el
/// 2.º a la izquierda y el 3.º a la derecha. Con menos de tres jugadores se
/// enseñan los que hay. Va sobre el fondo oscuro de la cabecera.
class PodioSalonFama extends StatelessWidget {
  const PodioSalonFama({super.key, required this.puestos, this.usuario});

  /// Los primeros del ranking, en orden; se usan hasta tres.
  final List<PuestoSalon> puestos;
  final String? usuario;

  /// Alto del escalón según la posición en el podio (no el lugar, que puede
  /// repetirse con empates).
  static const alturas = [96.0, 70.0, 52.0];

  @override
  Widget build(BuildContext context) {
    final podio = puestos.take(3).toList();
    // De izquierda a derecha: 2.º, 1.º, 3.º.
    final orden = [1, 0, 2].where((i) => i < podio.length);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // El foco dorado detrás del primero.
        Positioned(
          top: 0,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Medalla.oro.fuerte.withValues(alpha: 0.35),
                    Medalla.oro.fuerte.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          key: const Key('podio'),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final i in orden)
              Expanded(
                child: _Escalon(
                  key: Key('podio-${podio[i].usuario}'),
                  puesto: podio[i],
                  altura: alturas[i],
                  alCentro: i == 0,
                  soyYo:
                      podio[i].usuario.toLowerCase() == usuario?.toLowerCase(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Escalon extends StatelessWidget {
  const _Escalon({
    super.key,
    required this.puesto,
    required this.altura,
    required this.alCentro,
    required this.soyYo,
  });

  final PuestoSalon puesto;
  final double altura;
  final bool alCentro;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    final medalla = Medalla.deLugar(puesto.lugar) ?? Medalla.bronce;
    final tamano = alCentro ? 68.0 : 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (puesto.lugar == 1)
            Icon(
              Icons.emoji_events,
              size: alCentro ? 30 : 24,
              color: medalla.fuerte,
              shadows: [
                Shadow(
                  color: medalla.fuerte.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            )
          else
            const SizedBox(height: 10),
          const SizedBox(height: 2),
          // El aro metálico con el avatar dentro y el lugar en una medallita.
          SizedBox(
            width: tamano + 8,
            height: tamano + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: Key('medalla-${medalla.nombre}-${puesto.usuario}'),
                  width: tamano + 8,
                  height: tamano + 8,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: medalla.brillo,
                    border: soyYo
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: medalla.fuerte.withValues(alpha: 0.55),
                        blurRadius: alCentro ? 18 : 10,
                      ),
                    ],
                  ),
                  child: AvatarJugador(usuario: puesto.usuario, tamano: tamano),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: medalla.brillo,
                      border: Border.all(
                        color: const Color(0xFF1E1A14),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${puesto.lugar}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: medalla.texto,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            soyYo ? '@${puesto.usuario} (tú)' : '@${puesto.usuario}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white,
              fontWeight: soyYo ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          TextoEloSalon(
            key: Key('podio-elo-${puesto.usuario}'),
            elo: puesto.elo,
            color: medalla.claro,
            tamano: alCentro ? 14 : 13,
          ),
          const SizedBox(height: 8),
          // El escalón, con su número grande grabado.
          Container(
            height: altura,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medalla.fuerte,
                  Color.lerp(medalla.fuerte, const Color(0xFF1E1A14), 0.55)!,
                ],
              ),
              border: Border(top: BorderSide(color: medalla.claro, width: 2)),
            ),
            child: Text(
              '${puesto.lugar}',
              style: TextStyle(
                fontSize: alCentro ? 40 : 30,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.85),
                shadows: const [
                  Shadow(color: Colors.black26, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
