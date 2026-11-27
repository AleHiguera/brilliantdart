import 'package:flutter/material.dart';
import 'package:brilliant_mobile/avatar_jugador.dart';
import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/podio_salon_fama.dart';
import 'package:brilliant_mobile/texto_elo_salon.dart';

/// Fondo dorado de la fila de quien consulta.
const Color colorFilaMia = Color(0xFFFFF4D1);

/// Una fila del ranking debajo del podio: lugar, avatar, usuario y ELO. La de
/// quien consulta se resalta en dorado.
class FilaSalonFama extends StatelessWidget {
  const FilaSalonFama({super.key, required this.puesto, this.soyYo = false});

  final PuestoSalon puesto;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    // Si alguien empata con el 3.er lugar y no cupo en el podio, conserva su
    // medalla.
    final medalla = Medalla.deLugar(puesto.lugar);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(8, 9, 10, 9),
      decoration: BoxDecoration(
        color: soyYo ? colorFilaMia : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: soyYo
            ? Border.all(color: const Color(0xFFE0B43A), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: soyYo
                ? const Color(0x33E0B43A)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: soyYo ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalla?.claro ?? Colors.transparent,
              border: medalla == null
                  ? null
                  : Border.all(color: medalla.fuerte),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Text(
                  '${puesto.lugar}',
                  key: Key('salon-lugar-${puesto.usuario}'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: medalla?.texto ?? const Color(0xFF8A8577),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AvatarJugador(usuario: puesto.usuario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              soyYo ? '@${puesto.usuario} (tú)' : '@${puesto.usuario}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: soyYo ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF2A2620),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: soyYo ? Colors.white : const Color(0xFFF5F1E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextoEloSalon(
              key: Key('salon-elo-${puesto.usuario}'),
              elo: puesto.elo,
              color: const Color(0xFF2A2620),
              tamano: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// La separación entre el Top 10 y mi puesto cuando quedé fuera: «...».
class SeparadorSalonFama extends StatelessWidget {
  const SeparadorSalonFama({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('salon-separador'),
      padding: EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0xFFDCD6C6))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFFB8B09A),
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFDCD6C6))),
        ],
      ),
    );
  }
}

/// La etiqueta «TU POSICIÓN» encima de mi fila cuando quedé fuera del Top.
class EtiquetaMiPosicion extends StatelessWidget {
  const EtiquetaMiPosicion({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('salon-tu-posicion'),
      padding: EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(Icons.person_pin_circle, size: 16, color: Color(0xFFB08A1E)),
          SizedBox(width: 4),
          Text(
            'TU POSICIÓN',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB08A1E),
            ),
          ),
        ],
      ),
    );
  }
}
